use std::sync::Arc;

use giraffe_sdk::{
    blockchain::{Blockchain, Error},
    p2p,
};
use tokio::sync::Mutex;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let blockchain = Arc::new(Mutex::new(Blockchain::init().await?));
    p2p::start(2023, vec![], blockchain).await?;
    Ok(())
}
