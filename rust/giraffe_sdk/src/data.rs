use std::{
    collections::HashMap, future::Future}
;

use prost::Message;

use crate::{
    codecs::from_b58_string,
    models::{BlockHeader, BlockId, StakerCertificate, TransactionId, TransactionOutputReference},
};
use tokio_rusqlite::Connection;

pub trait Storage {
    fn fetch_header(&self, block_id: BlockId) -> impl Future<Output = BlockHeader>;
}

pub struct SqliteStorage {
    connection: Connection,
}

impl Storage for SqliteStorage {
    async fn fetch_header(&self, block_id: BlockId) -> BlockHeader {
        let id = block_id.clone();
        let header = self.connection.call(|conn| {
            let mut stmt = conn.prepare("SELECT parent_header_id, tx_root, timestamp, height, slot, staker_certificate, account_tx, account_index, settings FROM headers WHERE block_id = ?")?;
            let mut rows = stmt.query([block_id.value])?;
            let row = rows.next()?.unwrap();
    
            let staker_cert = StakerCertificate::decode(from_b58_string(row.get(6)?).as_slice()).unwrap();
            let settings_str: String = row.get(9)?;
            let mut settings: HashMap<String, String> = HashMap::new();
            for t in settings_str.split(',') {
                let kv: Vec<&str> = t.split('=').collect();
                settings.insert(kv[0].to_string(), kv[1].to_string());
            }
            Ok(BlockHeader {
                header_id: Some(id),
                parent_header_id: Some(BlockId { value: row.get(1)? }),
                tx_root: row.get(2)?,
                timestamp: row.get(3)?,
                height: row.get(4)?,
                slot: row.get(5)?,
                staker_certificate: Some(staker_cert),
                account: Some(TransactionOutputReference {
                    transaction_id: Some(TransactionId { value: row.get(7)? }),
                    index: row.get(8)?,
                }),
                settings: settings,
            })
        });
        header.await.unwrap()
    }
}
