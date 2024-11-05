use std::sync::{Arc, Mutex};

use crate::{
    block_tree,
    clock::Clock,
    codecs::from_b58_string,
    data,
    models::{ActiveStaker, BlockId, StakingRegistration, TransactionOutputReference},
};
use num_bigint::BigInt;
use num_rational::BigRational;
use prost::Message;
use tokio_rusqlite::{params, Connection, Transaction};

#[derive(Debug, Clone)]
pub struct StakerTracker {
    clock: Clock,
    genesis_id: BlockId,
    connection: Arc<Mutex<Connection>>,
}

impl StakerTracker {
    pub fn new(genesis_id: BlockId, clock: Clock, connection: Connection) -> Self {
        StakerTracker {
            clock,
            genesis_id,
            connection: Arc::new(Mutex::new(connection)),
        }
    }
    pub async fn total_active_stake(&self, block_id: &BlockId, slot: &u64) -> u64 {
        let conn = self.connection.lock().unwrap();
        set_state_to(self, &conn, block_id, slot).await;
        conn.call(|conn| {
            let mut stmt =
                conn.prepare("SELECT value FROM staking_meta WHERE key = 'total_active_stake'")?;
            let mut rows = stmt.query([])?;
            Ok(rows.next()?.unwrap().get(0)?)
        })
        .await
        .unwrap()
    }

    pub async fn staker(
        &self,
        block_id: &BlockId,
        slot: &u64,
        account: &TransactionOutputReference,
    ) -> Option<ActiveStaker> {
        let account = account.clone();
        // TODO mutex
        let conn = self.connection.lock().unwrap();
        set_state_to(self, &conn, block_id, slot).await;
        conn
            .call(move |conn| {
                let mut stmt = conn
                    .prepare("SELECT COUNT(*) FROM stakers WHERE account_tx_id = ? AND account_tx_idx = ?")?;
                let mut rows = stmt.query(params![account.transaction_id.clone().unwrap().value, account.index])?;
                if let Some(_) = rows.next()? {
                    let mut stmt = conn.prepare("SELECT quantity, staking_registration FROM transaction_outputs WHERE transaction_id = ? AND transaction_idx = ?")?;
                    let mut rows = stmt.query(params![account.transaction_id.unwrap().value, account.index])?;
                    let row = rows.next()?.unwrap();
                    let quantity: u64 = row.get(0)?;
                    let registration_b58: String = row.get(1)?;
                    let registration_enc = from_b58_string(registration_b58);
                    let registration = StakingRegistration::decode(registration_enc.as_slice()).unwrap();
                    Ok(Some(ActiveStaker {
                        registration: Some(registration),
                        quantity,
                    }))
                } else {
                    Ok(None)
                }
            })
            .await
            .unwrap()
    }

    pub async fn staker_relative_stake(
        &self,
        block_id: &BlockId,
        slot: &u64,
        account: &TransactionOutputReference,
    ) -> Option<BigRational> {
        let staker = self.staker(block_id, slot, account).await?;
        let total = self.total_active_stake(block_id, slot).await;
        return Some(BigRational::new(
            BigInt::from(staker.quantity),
            BigInt::from(total),
        ));
    }
}

async fn set_state_to(
    meta: &StakerTracker,
    connection: &Connection,
    block_id: &BlockId,
    slot: &u64,
) {
    let epoch = meta.clock.epoch_of(slot.clone() as i64);
    let epoch_boundary_block = if epoch > 1 {
        boundary_of(
            &connection,
            &meta.clock,
            block_id,
            &(epoch.clone() as u64 - 2),
        )
        .await
    } else {
        meta.genesis_id.clone()
    };
    let current = block_tree::current_event_id(&connection, "stakers".to_owned()).await;

    let (unapply_chain, apply_chain) =
        block_tree::find_common_ancestor(&connection, current, epoch_boundary_block.clone()).await;
    for id in unapply_chain[1..].iter() {
        unapply_stakers(&connection, &id, &unapply_chain[0]).await;
    }
    for id in apply_chain[1..].iter() {
        apply_stakers(&connection, &id).await;
    }
}

async fn apply_stakers(connection: &Connection, block_id: &BlockId) {
    let tx_ids = data::fetch_body(connection, block_id.clone())
        .await
        .unwrap()
        .transaction_ids;
    let (operations, stake_shift) = connection
        .call(|conn| {
            let mut operations: Vec<StakeShiftOperation> = Vec::new();
            let mut stake_shift: i64 = 0;
            for tx_id in tx_ids {
                let stmt = &mut conn.prepare("SELECT transaction_outputs.transaction_id, transaction_outputs.idx, transaction_outputs.quantity FROM transaction_outputs INNER JOIN transaction_inputs ON transaction_outputs.transaction_id = transaction_inputs.spent_transaction_id AND transaction_outputs.idx = transaction_inputs.spent_transaction_idx WHERE transaction_inputs.transaction_id = ? AND transaction_outputs.staking_registration IS NOT NULL")?;
                let rows = &mut stmt.query([tx_id.value.clone()])?;
                while let Some(row) = rows.next()? {
                    operations.push(StakeShiftOperation::Remove(row.get(0)?, row.get(1)?));
                    let quantity: i64 = row.get(2)?;
                    stake_shift -= quantity;
                }
                let stmt = &mut conn.prepare("SELECT transaction_outputs.idx, transaction_outputs.quantity FROM transaction_outputs WHERE transaction_outputs.transaction_id = ? AND transaction_outputs.staking_registration IS NOT NULL")?;
                let rows = &mut stmt.query([tx_id.value.clone()])?;
                while let Some(row) = rows.next()? {
                    operations.push(StakeShiftOperation::Add(tx_id.value.clone(), row.get(0)?));
                    let quantity: i64 = row.get(1)?;
                    stake_shift += quantity;
                }
            }
            Ok((operations, stake_shift))
        })
        .await
        .unwrap();
    connection
        .call(move |conn| {
            let db_tx: Transaction = conn.transaction()?;
            db_tx.execute(
                "UPDATE staking_meta SET value = value + ? WHERE key = 'total_active_stake'",
                params![stake_shift],
            )?;
            for operation in operations {
                match operation {
                    StakeShiftOperation::Add(tx_id, tx_idx) => {
                        db_tx.execute(
                            "INSERT INTO stakers (account_tx_id, account_tx_idx) VALUES (?, ?)",
                            params![tx_id, tx_idx],
                        )?;
                    }
                    StakeShiftOperation::Remove(tx_id, tx_idx) => {
                        db_tx.execute(
                            "DELETE FROM stakers WHERE account_tx_id = ? AND account_tx_idx = ?",
                            params![tx_id, tx_idx],
                        )?;
                    }
                }
            }
            db_tx.commit()?;
            Ok(())
        })
        .await
        .unwrap();
}

async fn unapply_stakers(connection: &Connection, block_id: &BlockId, parent: &BlockId) {
    let mut tx_ids = data::fetch_body(connection, block_id.clone())
        .await
        .unwrap()
        .transaction_ids
        .clone();
    tx_ids.reverse();
    let (operations, stake_shift) = connection
        .call(|conn| {
            let mut operations: Vec<StakeShiftOperation> = Vec::new();
            let mut stake_shift: i64 = 0;
            for tx_id in tx_ids {
                let stmt = &mut conn.prepare("SELECT transaction_outputs.idx, transaction_outputs.quantity FROM transaction_outputs WHERE transaction_outputs.transaction_id = ? AND transaction_outputs.staking_registration IS NOT NULL")?;
                let rows = &mut stmt.query([tx_id.value.clone()])?;
                while let Some(row) = rows.next()? {
                    operations.push(StakeShiftOperation::Remove(tx_id.value.clone(), row.get(0)?));
                    let quantity: i64 = row.get(1)?;
                    stake_shift -= quantity;
                }
                let stmt = &mut conn.prepare("SELECT transaction_outputs.transaction_id, transaction_outputs.idx, transaction_outputs.quantity FROM transaction_outputs INNER JOIN transaction_inputs ON transaction_outputs.transaction_id = transaction_inputs.spent_transaction_id AND transaction_outputs.idx = transaction_inputs.spent_transaction_idx WHERE transaction_inputs.transaction_id = ? AND transaction_outputs.staking_registration IS NOT NULL")?;
                let rows = &mut stmt.query([tx_id.value.clone()])?;
                while let Some(row) = rows.next()? {
                    operations.push(StakeShiftOperation::Add(row.get(0)?, row.get(1)?));
                    let quantity: i64 = row.get(2)?;
                    stake_shift += quantity;
                }
            }
            Ok((operations, stake_shift))
        })
        .await
        .unwrap();
    let p = parent.clone();
    connection
        .call(move |conn| {
            let db_tx: Transaction = conn.transaction()?;
            db_tx.execute(
                "UPDATE staking_meta SET value = value + ? WHERE key = 'total_active_stake'",
                params![stake_shift],
            )?;
            for operation in operations {
                match operation {
                    StakeShiftOperation::Add(tx_id, tx_idx) => {
                        db_tx.execute(
                            "INSERT INTO stakers (account_tx_id, account_tx_idx) VALUES (?, ?)",
                            params![tx_id, tx_idx],
                        )?;
                    }
                    StakeShiftOperation::Remove(tx_id, tx_idx) => {
                        db_tx.execute(
                            "DELETE FROM stakers WHERE account_tx_id = ? AND account_tx_idx = ?",
                            params![tx_id, tx_idx],
                        )?;
                    }
                }
            }
            db_tx.execute(
                "UPDATE ess SET block_id = ? WHERE key = 'stakers'",
                [p.value],
            )?;
            db_tx.commit()?;
            Ok(())
        })
        .await
        .unwrap();
}

enum StakeShiftOperation {
    Add(String, u64),
    Remove(String, u64),
}

async fn boundary_of(
    connection: &Connection,
    clock: &Clock,
    head: &BlockId,
    epoch: &u64,
) -> BlockId {
    let current = block_tree::current_event_id(connection, "epoch_boundaries".to_owned()).await;

    if current != *head {
        let (unapply_chain, apply_chain) =
            block_tree::find_common_ancestor(connection, current, head.clone()).await;
        let common_ancestor_id = unapply_chain[0].clone();
        let common_ancestor_slot: u64 = connection
            .call(move |conn: &mut rusqlite::Connection| {
                Ok(conn.query_row(
                    "SELECT slot FROM headers WHERE block_id = ?",
                    [common_ancestor_id.clone().value],
                    |row| Ok(row.get(0)?),
                )?)
            })
            .await
            .unwrap();
        let common_ancestor_epoch = clock.epoch_of(common_ancestor_slot as i64);
        connection
            .call(move |conn| {
                let mut stmt = conn.prepare("DELETE FROM epoch_boundaries WHERE epoch >= ?")?;
                stmt.execute([common_ancestor_epoch])?;
                Ok(())
            })
            .await
            .unwrap();
        let clock = clock.clone();
        let mut e = common_ancestor_epoch.clone();
        let mut id = unapply_chain[0].clone().clone();
        connection
            .call(move |conn| {
                for next in apply_chain[1..].iter() {
                    let next_id = next.clone();
                    let next_slot: u64 = conn
                        .prepare("SELECT slot FROM headers WHERE block_id = ?")?
                        .query([next_id.value.clone()])?
                        .next()?
                        .unwrap()
                        .get(0)?;
                    let next_epoch = clock.clone().epoch_of(next_slot as i64);
                    if next_epoch > e {
                        conn.prepare(
                            "INSERT INTO epoch_boundaries (epoch, block_id) VALUES (?, ?)",
                        )?
                        .execute(params![next_epoch, id.value.clone()])?;
                        e = next_epoch;
                    }
                    id = next_id;
                }
                Ok(())
            })
            .await
            .unwrap()
    }

    let e = epoch.clone();

    let boundary = connection
        .call(move |conn: &mut rusqlite::Connection| {
            Ok(conn.query_row(
                "SELECT block_id FROM epoch_boundaries WHERE epoch = ?",
                [e],
                |row| Ok(BlockId { value: row.get(0)? }),
            )?)
        })
        .await
        .unwrap();

    boundary
}
