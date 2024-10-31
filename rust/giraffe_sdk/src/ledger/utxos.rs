use std::sync::Arc;

use tokio::sync::Mutex;

use rusqlite::params;
use tokio_rusqlite::Connection;

use crate::{
    block_tree,
    models::{BlockId, TransactionId, TransactionOutputReference},
};

#[derive(Debug, Clone)]
pub struct Utxos {
    connection: Arc<Mutex<Connection>>,
}

impl Utxos {
    pub fn new(connection: Connection) -> Self {
        Utxos {
            connection: Arc::new(Mutex::new(connection)),
        }
    }

    pub async fn transaction_outputs_are_spendable(
        &self,
        head: &BlockId,
        references: Vec<TransactionOutputReference>,
    ) -> Result<bool, String> {
        let connection = self.connection.lock().await;
        update_state(&connection, head).await?;
        connection.call(move |conn| {
            for reference in references {
            let mut statement = conn.prepare("SELECT spendable FROM transaction_outputs WHERE transaction_id = ? AND idx = ? AND spendable = true")?;
            let mut rows = statement.query(params![reference.transaction_id.clone().unwrap().value, reference.index])?;
            if rows.next()?.is_none() {
                return Ok(false);
            }
        }
            Ok(true)
        }).await.map_err(|e| e.to_string())
    }
}

async fn update_state(connection: &Connection, head: &BlockId) -> Result<(), String> {
    let current = block_tree::current_event_id(connection, "utxos".to_owned()).await;

    if current != *head {
        let (unapply_chain, apply_chain) =
            block_tree::find_common_ancestor(connection, current, head.clone()).await;
        connection
            .call(move |conn| {
                for i in (1..unapply_chain.len()).rev() {
                    let id = &unapply_chain[i];
                    unapply_block(conn, id)?;
                }
                for i in (1..apply_chain.len()).rev() {
                    let id = &apply_chain[i];
                    apply_block(conn, id)?;
                }
                Ok(())
            })
            .await
            .map_err(|e| e.to_string())?;
    }
    Ok(())
}

fn apply_block(conn: &rusqlite::Connection, block_id: &BlockId) -> Result<(), rusqlite::Error> {
    let mut statement =
        conn.prepare("SELECT transaction_id FROM bodies WHERE block_id = ? ORDER BY index ASC")?;
    let mut rows = statement.query([block_id.clone().value])?;
    while let Some(row) = rows.next()? {
        let id = TransactionId { value: row.get(0)? };
        apply_transaction(conn, &id)?;
    }
    Ok(())
}

fn unapply_block(conn: &rusqlite::Connection, block_id: &BlockId) -> Result<(), rusqlite::Error> {
    let mut statement =
        conn.prepare("SELECT transaction_id FROM bodies WHERE block_id = ? ORDER BY index DESC")?;
    let mut rows = statement.query([block_id.clone().value])?;
    while let Some(row) = rows.next()? {
        let id = TransactionId { value: row.get(0)? };
        unapply_transaction(conn, &id)?;
    }
    Ok(())
}

fn apply_transaction(
    conn: &rusqlite::Connection,
    id: &TransactionId,
) -> Result<(), rusqlite::Error> {
    conn.execute(
        "UPDATE transaction_outputs SET spendable = true WHERE transaction_id = ?",
        [id.clone().value],
    )?;
    let mut statement = conn.prepare("SELECT spent_transaction_id, spent_transaction_idx FROM transaction_inputs WHERE transaction_id = ?")?;
    let mut rows = statement.query([id.clone().value])?;
    while let Some(row) = rows.next()? {
        let spent_transaction_id: String = row.get(0)?;
        let spent_transaction_idx: u32 = row.get(1)?;
        conn.execute("UPDATE transaction_outputs SET spendable = false WHERE transaction_id = ? AND index = ?", params![spent_transaction_id, spent_transaction_idx])?;
    }
    Ok(())
}

fn unapply_transaction(
    conn: &rusqlite::Connection,
    id: &TransactionId,
) -> Result<(), rusqlite::Error> {
    conn.execute(
        "UPDATE transaction_outputs SET spendable = NULL WHERE transaction_id = ?",
        [id.clone().value],
    )?;
    let mut statement = conn.prepare("SELECT spent_transaction_id, spent_transaction_idx FROM transaction_inputs WHERE transaction_id = ?")?;
    let mut rows = statement.query([id.clone().value])?;
    while let Some(row) = rows.next()? {
        let spent_transaction_id: String = row.get(0)?;
        let spent_transaction_idx: u32 = row.get(1)?;
        conn.execute("UPDATE transaction_outputs SET spendable = true WHERE transaction_id = ? AND index = ?", params![spent_transaction_id, spent_transaction_idx])?;
    }
    Ok(())
}
