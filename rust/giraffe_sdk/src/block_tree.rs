use std::future::Future;

use tokio_rusqlite::Connection;

use crate::models::BlockId;

pub trait BlockTree {
    fn parent_of(&self, id: BlockId) -> impl Future<Output = Option<BlockId>>;
    fn find_common_ancestor(
        &self,
        a: BlockId,
        b: BlockId,
    ) -> impl Future<Output = (Vec<BlockId>, Vec<BlockId>)>;
}

impl BlockTree for Connection {
    async fn parent_of(&self, id: BlockId) -> Option<BlockId> {
        let id = id.clone();
        self.call(|conn| {
            let mut stmt =
                conn.prepare("SELECT parent_header_id FROM headers WHERE block_id = ?")?;
            let mut rows = stmt.query([id.value])?;
            if let Some(row) = rows.next()? {
                Ok(Some(BlockId { value: row.get(0)? }))
            } else {
                Ok(None)
            }
        })
        .await
        .unwrap()
    }

    async fn find_common_ancestor(&self, a: BlockId, b: BlockId) -> (Vec<BlockId>, Vec<BlockId>) {
        let mut a = a;
        let mut b = b;
        let mut a_height = get_height(self, a.clone()).await;
        let mut b_height = get_height(self, a.clone()).await;
        let mut a_path = vec![a.clone()];
        let mut b_path = vec![b.clone()];
        while a_height > b_height {
            a = self.parent_of(a.clone()).await.unwrap();
            a_path.push(a.clone());
            a_height -= 1;
        }
        while b_height > a_height {
            b = self.parent_of(b.clone()).await.unwrap();
            b_path.push(b.clone());
            b_height -= 1;
        }
        while a != b {
            a = self.parent_of(a.clone()).await.unwrap();
            a_path.push(a.clone());
            b = self.parent_of(b.clone()).await.unwrap();
            b_path.push(b.clone());
        }
        a_path.reverse();
        b_path.reverse();
        assert!(a_path[0] == b_path[0]);
        (a_path, b_path)
    }
}

async fn get_height(connection: &Connection, id: BlockId) -> u64 {
    let id = id.clone();
    connection
        .call(|conn| {
            let mut stmt = conn.prepare("SELECT height FROM headers WHERE block_id = ?")?;
            let mut rows = stmt.query([id.value])?;
            let row = rows.next()?.unwrap();
            Ok(row.get(0)?)
        })
        .await
        .unwrap()
}
