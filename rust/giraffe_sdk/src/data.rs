use std::collections::HashMap;

use prost::Message;
use prost_types::Struct;
use rusqlite::{params, Row};

use crate::{
    codecs::{decode_lock_address, from_b58, from_b58_string},
    models::{
        graph_entry, Asset, BlockBody, BlockHeader, BlockId, Edge, GraphEntry, StakerCertificate,
        StakingRegistration, Transaction, TransactionId, TransactionInput, TransactionOutput,
        TransactionOutputReference, Vertex, Witness,
    },
};
use tokio_rusqlite::Connection;

pub fn fetch_header_sync(
    conn: &rusqlite::Connection,
    id: BlockId,
) -> Result<Option<BlockHeader>, tokio_rusqlite::Error> {
    let mut stmt = conn.prepare("SELECT parent_header_id, tx_root, timestamp, height, slot, staker_certificate, account_tx, account_index, settings FROM headers WHERE block_id = ?")?;
    let mut rows = stmt.query([id.clone().value])?;
    if let Some(row) = rows.next()? {
        let staker_cert =
            StakerCertificate::decode(from_b58_string(row.get(5)?).as_slice()).unwrap();
        let settings_str: String = row.get(8)?;
        let mut settings: HashMap<String, String> = HashMap::new();
        for t in settings_str.split(',') {
            let kv: Vec<&str> = t.split('=').collect();
            settings.insert(kv[0].to_string(), kv[1].to_string());
        }
        Ok(Some(BlockHeader {
            header_id: Some(id),
            parent_header_id: Some(BlockId { value: row.get(0)? }),
            tx_root: row.get(1)?,
            timestamp: row.get(2)?,
            height: row.get(3)?,
            slot: row.get(4)?,
            staker_certificate: Some(staker_cert),
            account: Some(TransactionOutputReference {
                transaction_id: Some(TransactionId { value: row.get(6)? }),
                index: row.get(7)?,
            }),
            settings,
        }))
    } else {
        Ok(None)
    }
}

pub async fn fetch_header(connection: &Connection, block_id: BlockId) -> Option<BlockHeader> {
    connection
        .call(|conn| fetch_header_sync(conn, block_id))
        .await
        .unwrap()
}

pub fn fetch_body_sync(
    conn: &rusqlite::Connection,
    block_id: BlockId,
) -> Result<Option<BlockBody>, tokio_rusqlite::Error> {
    let mut statement =
        conn.prepare("SELECT tx_count FROM headers WHERE block_id = ? AND tx_count IS NOT NULL")?;
    let mut rows = statement.query([block_id.clone().value])?;
    if let Some(count_row) = rows.next()? {
        let count: u32 = count_row.get(0)?;
        if count == 0 {
            return Ok(Some(BlockBody {
                transaction_ids: vec![],
            }));
        } else {
            let mut statement = conn.prepare(
                "SELECT transaction_id FROM bodies WHERE block_id = ? ORDER BY index ASC",
            )?;
            let mut rows = statement.query([block_id.value])?;
            let mut txs = Vec::new();
            while let Some(row) = rows.next()? {
                txs.push(TransactionId { value: row.get(0)? });
            }
            return Ok(Some(BlockBody {
                transaction_ids: txs,
            }));
        }
    } else {
        return Ok(None);
    }
}

pub async fn fetch_body(connection: &Connection, block_id: BlockId) -> Option<BlockBody> {
    connection
        .call(|conn| fetch_body_sync(conn, block_id))
        .await
        .unwrap()
}

fn decode_transaction_output(row: &Row) -> Result<TransactionOutput, tokio_rusqlite::Error> {
    let quantity: u64 = row.get(0)?;
    let address_str: String = row.get(1)?;
    let staking_registration_str: Option<String> = row.get(2)?;
    let graph_label: Option<String> = row.get(4)?;
    let graph_data: Option<String> = row.get(5)?;
    let graph_edge_lock_address: Option<String> = row.get(6)?;
    let graph_a_id: Option<String> = row.get(7)?;
    let graph_a_idx: Option<u32> = row.get(8)?;
    let graph_b_id: Option<String> = row.get(9)?;
    let graph_b_idx: Option<u32> = row.get(10)?;
    let asset_id: Option<String> = row.get(11)?;
    let asset_idx: Option<u32> = row.get(12)?;
    let asset_quantity: Option<u64> = row.get(13)?;
    let staking_registration: Option<StakingRegistration> = staking_registration_str
        .map(|value| StakingRegistration::decode(from_b58(value.as_str()).as_slice()).unwrap());
    let graph_entry = if let Some(label) = graph_label {
        let data =
            graph_data.map(|value| Struct::decode(from_b58(value.as_str()).as_slice()).unwrap());
        let e = match (graph_a_idx, graph_b_idx) {
            (Some(a_idx), Some(b_idx)) => graph_entry::Entry::Edge(Edge {
                label,
                data,
                a: Some(TransactionOutputReference {
                    transaction_id: graph_a_id.map(|value| TransactionId { value }),
                    index: a_idx,
                }),
                b: Some(TransactionOutputReference {
                    transaction_id: graph_b_id.map(|value| TransactionId { value }),
                    index: b_idx,
                }),
            }),
            _ => graph_entry::Entry::Vertex(Vertex {
                label,
                edge_lock_address: graph_edge_lock_address
                    .map(|value| decode_lock_address(value.as_str())),
                data,
            }),
        };
        Some(GraphEntry { entry: Some(e) })
    } else {
        None
    };
    let output = TransactionOutput {
        quantity,
        lock_address: Some(decode_lock_address(address_str.as_str())),
        staking_registration,
        graph_entry,
        asset: if let Some(asset_idx) = asset_idx {
            let origin = Some(TransactionOutputReference {
                transaction_id: asset_id.map(|value| TransactionId { value }),
                index: asset_idx,
            });
            Some(Asset {
                origin,
                quantity: asset_quantity.unwrap(),
            })
        } else {
            None
        },
    };
    Ok(output)
}

pub fn fetch_transaction_output_sync(
    conn: &rusqlite::Connection,
    transaction_id: TransactionId,
    index: u32,
) -> Result<Option<TransactionOutput>, tokio_rusqlite::Error> {
    let mut statement = conn.prepare("SELECT quantity, address, staking_registration, graph_label, graph_data, graph_edge_lock_address, graph_a_id, graph_a_idx, graph_b_id, graph_b_idx, asset_id, asset_idx, asset_quantity FROM transaction_outputs WHERE transaction_id = ? AND index = ? LIMIT 1")?;
    let mut rows = statement.query(params![transaction_id.value, index])?;
    if let Some(row) = rows.next()? {
        decode_transaction_output(row).map(|v| Some(v))
    } else {
        Ok(None)
    }
}

pub fn fetch_transaction_outputs_sync(
    conn: &rusqlite::Connection,
    transaction_id: TransactionId,
) -> Result<Vec<TransactionOutput>, tokio_rusqlite::Error> {
    let mut statement = conn.prepare("SELECT quantity, address, staking_registration, graph_label, graph_data, graph_edge_lock_address, graph_a_id, graph_a_idx, graph_b_id, graph_b_idx, asset_id, asset_idx, asset_quantity FROM transaction_outputs WHERE transaction_id = ? ORDER BY index ASC")?;
    let mut rows = statement.query([transaction_id.value])?;
    let mut outputs = Vec::new();
    while let Some(row) = rows.next()? {
        let output = decode_transaction_output(row)?;
        outputs.push(output);
    }
    Ok(outputs)
}

pub fn fetch_transaction_inputs_sync(
    conn: &rusqlite::Connection,
    transaction_id: TransactionId,
) -> Result<Vec<TransactionInput>, tokio_rusqlite::Error> {
    let mut statement = conn.prepare("SELECT spent_transaction_id, spent_transaction_idx FROM transaction_inputs WHERE transaction_id = ? ORDER BY index ASC")?;
    let mut rows = statement.query([transaction_id.clone().value])?;
    let mut inputs = Vec::new();
    while let Some(row) = rows.next()? {
        let spent_transaction_id: String = row.get(0)?;
        let spent_transaction_idx: u32 = row.get(1)?;
        let reference = TransactionOutputReference {
            transaction_id: Some(TransactionId {
                value: spent_transaction_id,
            }),
            index: spent_transaction_idx,
        };
        inputs.push(TransactionInput {
            reference: Some(reference),
        });
    }
    Ok(inputs)
}

pub fn fetch_transaction_sync(
    conn: &rusqlite::Connection,
    transaction_id: TransactionId,
) -> Result<Option<Transaction>, tokio_rusqlite::Error> {
    let mut statement = conn.prepare(
        "SELECT attestation, reward_parent_block_id FROM transactions WHERE transaction_id = ?",
    )?;
    let mut rows = statement.query([transaction_id.clone().value])?;
    if let Some(row) = rows.next()? {
        let attestation_str: String = row.get(0)?;
        let reward_parent_block_id_str: Option<String> = row.get(1)?;
        let witnesses_str = attestation_str.split(',').collect::<Vec<&str>>();
        let attestation: Vec<Witness> = witnesses_str
            .iter()
            .map(|witness_str| Witness::decode(from_b58(witness_str).as_slice()).unwrap())
            .collect();
        let outputs = fetch_transaction_outputs_sync(conn, transaction_id.clone())?;
        let inputs = fetch_transaction_inputs_sync(conn, transaction_id.clone())?;
        Ok(Some(Transaction {
            transaction_id: Some(transaction_id.clone()),
            outputs,
            inputs,
            attestation,
            reward_parent_block_id: reward_parent_block_id_str.map(|value| BlockId { value }),
        }))
    } else {
        Ok(None)
    }
}

pub async fn fetch_transaction(
    connection: &Connection,
    transaction_id: TransactionId,
) -> Option<Transaction> {
    connection
        .call(|conn| fetch_transaction_sync(conn, transaction_id))
        .await
        .unwrap()
}

pub async fn init_db(connection: &Connection) {
    connection
        .call(|connection| {
            connection.execute(
                "CREATE TABLE IF NOT EXISTS headers (
            block_id TEXT PRIMARY KEY NOT NULL,
            parent_header_id TEXT,
            tx_root TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            height INTEGER NOT NULL,
            slot INTEGER NOT NULL,
            staker_certificate TEXT NOT NULL,
            account_tx TEXT NOT NULL,
            account_index INTEGER NOT NULL,
            settings TEXT,
            tx_count INTEGER
        )",
                [],
            )?;
            connection.execute("CREATE INDEX headers_height_idx ON headers (height)", [])?;
            connection.execute("CREATE INDEX headers_slot_idx ON headers (slot)", [])?;
            connection.execute(
                "CREATE TABLE IF NOT EXISTS bodies (
            block_id TEXT NOT NULL,
            index INTEGER NOT NULL,
            transaction_id TEXT NOT NULL,
            PRIMARY KEY (block_id, index, transaction_id),
        )",
                [],
            )?;
            connection.execute(
                "CREATE TABLE IF NOT EXISTS transactions (
            transaction_id TEXT PRIMARY KEY NOT NULL,
            inputs_count INTEGER NOT NULL,
            outputs_count INTEGER NOT NULL,
            attestation TEXT NOT NULL,
            reward_parent_block_id TEXT
        )",
                [],
            )?;
            connection.execute(
                "CREATE TABLE IF NOT EXISTS transaction_outputs (
            transaction_id TEXT NOT NULL,
            index INTEGER NOT NULL,
            PRIMARY KEY (transaction_id, index),
            quantity INTEGER NOT NULL,
            address TEXT NOT NULL,
            staking_registration TEXT,
            graph_label TEXT,
            graph_data TEXT,
            graph_edge_lock_address TEXT,
            graph_a_id TEXT,
            graph_a_idx INTEGER,
            graph_b_id TEXT,
            graph_b_idx INTEGER,
            asset_origin_id TEXT,
            asset_origin_idx INTEGER,
            asset_quantity INTEGER,
        )",
                [],
            )?;
            connection.execute("CREATE INDEX transaction_outputs_address_idx ON transaction_outputs (address)", [])?;
            connection.execute(
                "CREATE TABLE IF NOT EXISTS transaction_inputs (
            transaction_id TEXT NOT NULL,
            index INTEGER NOT NULL,
            PRIMARY KEY (transaction_id, index),
            spent_transaction_id TEXT NOT NULL,
            spent_transaction_idx INTEGER NOT NULL,
        )",
                [],
            )?;
            connection.execute("CREATE INDEX transaction_inputs_spent_transaction_id_idx ON transaction_inputs (spent_transaction_id)", [])?;
            connection.execute("CREATE INDEX transaction_inputs_spent_transaction_idx_idx ON transaction_inputs (spent_transaction_idx)", [])?;
            connection.execute(
                "CREATE TABLE IF NOT EXISTS staking_meta (
            key TEXT PRIMARY KEY NOT NULL,
            value INTEGER NOT NULL,
        )",
                [],
            )?;
            connection.execute(
                "CREATE TABLE IF NOT EXISTS stakers (
            account_tx TEXT NOT NULL,
            account_tx_idx INTEGER NOT NULL,
            PRIMARY KEY (account_tx, account_tx_idx),
        )",
                [],
            )?;
            connection.execute(
                "CREATE TABLE IF NOT EXISTS ess (
            key TEXT PRIMARY KEY NOT NULL,
            block_id TEXT NOT NULL,
        )",
                [],
            )?;

            Ok(())
        })
        .await
        .unwrap();
}
