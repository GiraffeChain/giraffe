use std::{collections::HashMap, future::Future};

use prost::Message;

use crate::{
    codecs::from_b58_string,
    models::{
        BlockBody, BlockHeader, BlockId, StakerCertificate, TransactionId,
        TransactionOutputReference,
    },
};
use tokio_rusqlite::Connection;

pub trait FetchHeader {
    fn fetch(&self, block_id: BlockId) -> impl Future<Output = Option<BlockHeader>>;
}

impl FetchHeader for Connection {
    async fn fetch(&self, block_id: BlockId) -> Option<BlockHeader> {
        let id = block_id.clone();
        self.call(|conn| {
            let mut stmt = conn.prepare("SELECT parent_header_id, tx_root, timestamp, height, slot, staker_certificate, account_tx, account_index, settings FROM headers WHERE block_id = ?")?;
            let mut rows = stmt.query([block_id.value])?;
            if let Some(row) = rows.next()? {
                let staker_cert = StakerCertificate::decode(from_b58_string(row.get(5)?).as_slice()).unwrap();
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
        }).await.unwrap()
    }
}

pub trait FetchBody {
    fn fetch(&self, block_id: BlockId) -> impl Future<Output = Option<BlockBody>>;
}

impl FetchBody for Connection {
    async fn fetch(&self, block_id: BlockId) -> Option<BlockBody> {
        let id = block_id.clone();
        let id2 = block_id.clone();

        let count_opt: Option<u32> = self
            .call(|conn| {
                let mut statement =
                    conn.prepare("SELECT tx_count FROM bodies_c WHERE block_id = ?")?;
                let mut rows = statement.query([id.value])?;
                if let Some(count_row) = rows.next()? {
                    return Ok(Some(count_row.get(0)?));
                } else {
                    return Ok(None);
                }
            })
            .await
            .unwrap();

        if let Some(count) = count_opt {
            if count == 0 {
                return Some(BlockBody {
                    transaction_ids: vec![],
                });
            } else {
                self.call(|conn| {
                    let mut statement = conn.prepare(
                        "SELECT transaction_id FROM bodies WHERE block_id = ? ORDER BY index ASC",
                    )?;
                    let mut rows = statement.query([id2.value])?;
                    let mut txs = Vec::new();
                    while let Some(row) = rows.next()? {
                        txs.push(TransactionId { value: row.get(0)? });
                    }
                    return Ok(Some(BlockBody {
                        transaction_ids: txs,
                    }));
                })
                .await
                .unwrap()
            }
        } else {
            return None;
        }
    }
}
