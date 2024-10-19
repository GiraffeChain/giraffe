use std::{future::Future, pin::Pin};

use crate::models::{BlockHeader, BlockId};

pub trait Storage {
    fn fetch_header(&self, block_id: BlockId) -> Pin<Box<dyn Future<Output = BlockHeader>>>;
}
