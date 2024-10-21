use crate::{data::Storage, models::BlockId};
use async_broadcast::{broadcast, Receiver, Sender, TryRecvError};

pub struct LocalChain<S: Storage> {
    pub genesis: BlockId,
    pub head: BlockId,
    pub broadcaster: Sender<BlockId>,
    pub receiver: Receiver<BlockId>,
    pub storage: S,
}

impl<S: Storage> LocalChain<S> {
    fn new(genesis: BlockId, head: BlockId, storage: S) -> LocalChain<S> {
        let (s, r): (Sender<BlockId>, Receiver<BlockId>) = broadcast(16);
        LocalChain {
            genesis,
            head,
            broadcaster: s,
            receiver: r,
            storage,
        }
    }
}
