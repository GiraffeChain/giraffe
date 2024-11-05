use std::collections::HashMap;

use rusqlite::params;
use tokio_rusqlite::Connection;

use crate::models::{BlockId, Transaction, TransactionId, TransactionOutputReference};

use super::value_calculator::required_minimum_quantity;

pub struct LedgerValidation {
    connection: Connection,
    utxos: super::utxos::Utxos,
}

impl LedgerValidation {
    pub fn new(connection: Connection, utxos: super::utxos::Utxos) -> Self {
        LedgerValidation {connection, utxos }
    }
    pub async fn verify_transaction(
        &self,
        head: &BlockId,
        transaction: &Transaction,
    ) -> Result<(), String> {
        if transaction.inputs.is_empty() {
            return Err("Empty inputs".to_string());
        }
        for output in &transaction.outputs {
            if output.quantity < required_minimum_quantity(&output) {
                return Err("Insufficient output quantity".to_string());
            }
        }
        for input in &transaction.inputs {
            let reference = input.reference.clone().ok_or("Illegal Self-Spend")?;
            reference
                .transaction_id
                .ok_or("Illegal Self-Spend".to_string())?;
        }

        let out_quantity = transaction.outputs.iter().map(|o| o.quantity).sum::<u64>();

        let mut in_quantity: u64 = 0;

        for input in &transaction.inputs {
            let reference = input.reference.clone().ok_or("Illegal Self-Spend")?;
            let quantity: u64 = self
                .connection
                .call(move |conn| {
                    conn.query_row(
                "SELECT quantity FROM transaction_outputs WHERE transaction_id = ? AND idx = ?",
                params![reference.transaction_id.unwrap().value, reference.index],
                |row| row.get(0),
            ).map_err(|e| tokio_rusqlite::Error::Rusqlite(e))
                })
                .await
                .map_err(|e| e.to_string())?;
            in_quantity += quantity;
        }

        if in_quantity < out_quantity {
            return Err("Insufficient input funds".to_string());
        }

        let dependencies = super::get_dependencies(transaction);

        let spendable_check = self
            .utxos
            .transaction_outputs_are_spendable(head, dependencies)
            .await?;

        if !spendable_check {
            return Err("Unspendable dependency".to_string());
        }

        asset_validation(&self.connection, transaction).await?;

        if ! super::vm::verify(transaction).await? {
            return Err("Transaction verification failed".to_string());
        }

        Ok(())
    }
}

async fn asset_validation(
    connection: &Connection,
    transaction: &Transaction,
) -> Result<(), String> {
    let mut transferred_assets = HashMap::new();
    for output in &transaction.outputs {
        if let Some(asset) = &output.asset {
            if asset.quantity <= 0 {
                return Err("Non-positive asset quantity".to_string());
            }
            if let Some(origin) = &asset.origin {
                if !transaction
                    .inputs
                    .iter()
                    .any(|i| *i.reference.as_ref().unwrap() == *origin)
                {
                    if let Some(v) = transferred_assets.get(origin) {
                        transferred_assets.insert(origin.clone(), asset.quantity + v);
                    } else {
                        transferred_assets.insert(origin.clone(), asset.quantity);
                    }
                }
            } else {
                return Err("Missing origin".to_string());
            }
        }
    }
            let t = transaction.inputs.clone();
    let input_assets = 
        connection.call(move |conn| {
            let mut input_assets: HashMap<TransactionOutputReference, u64> = HashMap::new();
            for input in &t {
                let reference = input.reference.clone().unwrap();
                let mut statement = conn.prepare("SELECT asset_origin_id, asset_origin_idx, asset_quantity FROM transaction_outputs WHERE transaction_id = ? AND idx = ? AND asset_origin_id IS NOT NULL AND asset_origin_idx IS NOT NULL")?;
                let mut rows = statement.query(params![reference.transaction_id.unwrap().value, reference.index])?;
                if let Some(row) = rows.next()? {
                    let id_str: String = row.get(0)?;
                    let idx: u32 = row.get(1)?;
                    let quantity: u64 = row.get(2)?;
                    let a_ref = TransactionOutputReference {
                        transaction_id: Some(TransactionId { value: id_str }),
                        index: idx,
                    };
                    if let Some(q) = input_assets.get(&a_ref) {
                        input_assets.insert(a_ref, quantity + q);
                    } else {
                        input_assets.insert(a_ref, quantity);
                    }
                }
            }
            Ok(input_assets)

        }).await.map_err(|e| e.to_string())?;
    for (k, v) in transferred_assets.iter() {
        if let Some(q) = input_assets.get(k) {
            if q < v {
                return Err("Insufficient input asset quantity".to_string());
            }
        } else {
            return Err("Missing input asset".to_string());
        }
    }
    Ok(())
}
