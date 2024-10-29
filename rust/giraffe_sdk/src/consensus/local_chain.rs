use crate::models::BlockId;
use async_broadcast::{broadcast, Receiver, Sender};
use tokio_rusqlite::Connection;

pub struct LocalChain {
    pub genesis: BlockId,
    pub head: BlockId,
    broadcaster: Sender<BlockId>,
    pub receiver: Receiver<BlockId>,
    connection: Connection,
}

impl LocalChain {
    fn new(genesis: BlockId, head: BlockId, connection: Connection) -> LocalChain {
        let (s, r): (Sender<BlockId>, Receiver<BlockId>) = broadcast(16);
        LocalChain {
            genesis,
            head,
            broadcaster: s,
            receiver: r,
            connection,
        }
    }

    async fn adopt(&mut self, block_id: &BlockId) {
        self.head = block_id.clone();
        self.broadcaster.broadcast(block_id.clone()).await.unwrap();
    }
}
