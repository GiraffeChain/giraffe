use crate::{data::FetchHeader, models::BlockId};
use async_broadcast::{broadcast, Receiver, Sender};

pub struct LocalChain<S: FetchHeader> {
    pub genesis: BlockId,
    pub head: BlockId,
    pub broadcaster: Sender<BlockId>,
    pub receiver: Receiver<BlockId>,
    fetch_header: S,
}

impl<S: FetchHeader> LocalChain<S> {
    fn new(genesis: BlockId, head: BlockId, fetch_header: S) -> LocalChain<S> {
        let (s, r): (Sender<BlockId>, Receiver<BlockId>) = broadcast(16);
        LocalChain {
            genesis,
            head,
            broadcaster: s,
            receiver: r,
            fetch_header,
        }
    }
}
