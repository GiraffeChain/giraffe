use std::sync::Arc;

use crate::{block_tree, models::BlockId};
use async_broadcast::{broadcast, Receiver, Sender};
use tokio::sync::Mutex;
use tokio_rusqlite::Connection;

#[derive(Debug, Clone)]
pub struct LocalChain {
    pub genesis_id: BlockId,
    broadcaster: Sender<BlockId>,
    pub receiver: Receiver<BlockId>,
    connection: Arc<Mutex<Connection>>,
}

impl LocalChain {
    pub fn new(genesis_id: BlockId, connection: Connection) -> LocalChain {
        let (s, r): (Sender<BlockId>, Receiver<BlockId>) = broadcast(16);
        LocalChain {
            genesis_id,
            broadcaster: s,
            receiver: r,
            connection: Arc::new(Mutex::new(connection)),
        }
    }

    pub async fn adopt(&mut self, block_id: &BlockId) {
        let connection = self.connection.lock().await;
        let head = connection
            .call(|conn| Ok(LocalChain::head_sync(conn)?))
            .await
            .unwrap();
        let (unapply_chain, apply_chain) =
            block_tree::find_common_ancestor(&connection, block_id.clone(), head.clone()).await;
        let common_ancestor_id = unapply_chain[0].clone();
        connection.call(move |conn| {
            conn.execute(
                "UPDATE headers SET (canonical = NULL) WHERE height > (SELECT height FROM headers WHERE block_id = ?))", 
                [common_ancestor_id.value]
            )?;
            for a in &apply_chain[1..] {
                conn.execute(
                    "UPDATE headers SET (canonical = true) WHERE block_id = ?",
                    [a.value.clone()],
                )?;
            }
            Ok(())
        }).await.unwrap();
        self.broadcaster.broadcast(block_id.clone()).await.unwrap();
    }

    pub async fn head(&self) -> BlockId {
        self.connection
            .lock()
            .await
            .call(|conn| Ok(LocalChain::head_sync(conn)?))
            .await
            .unwrap()
    }

    fn head_sync(conn: &mut rusqlite::Connection) -> Result<BlockId, rusqlite::Error> {
        let mut stmt = conn.prepare("SELECT block_id FROM blocks WHERE height = (SELECT MAX(height) FROM blocks WHERE canonical = true)")?;
        let mut rows = stmt.query([])?;
        let id = BlockId {
            value: rows.next()?.unwrap().get(0)?,
        };
        Ok(id)
    }

    pub async fn block_id_at_height(
        &mut self,
        height: i64,
    ) -> Result<Option<BlockId>, tokio_rusqlite::Error> {
        self.connection
            .lock()
            .await
            .call(move |conn| {
                // TODO: Block-Sourced State
                let mut stmt = conn
                    .prepare("SELECT block_id FROM blocks WHERE height = ? AND canonical = true")?;
                let mut rows = stmt.query([height]).unwrap();
                if let Some(row) = rows.next().unwrap() {
                    let id = BlockId { value: row.get(0)? };
                    Ok(Some(id))
                } else {
                    Ok(None)
                }
            })
            .await
    }
}
