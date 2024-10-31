use std::{
    sync::Arc,
    time::{SystemTime, UNIX_EPOCH},
};

use giraffe_sdk::{blockchain::Blockchain, data, models::FullBlock, p2p, testnet};
use tokio::sync::Mutex;

#[tokio::main]
async fn main() -> Result<(), Error> {
    let db = tokio_rusqlite::Connection::open_in_memory().await?;
    data::init_db(&db).await?;
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64;
    let genesis: FullBlock = testnet::init(timestamp, vec![10000000]);
    let blockchain = Arc::new(Mutex::new(Blockchain::new(genesis, db).await));
    p2p::start(2023, vec![], blockchain).await?;
    Ok(())
}

#[derive(Debug)]
enum Error {
    Data(data::Error),
    P2P(p2p::Error),
}

impl From<tokio_rusqlite::Error> for Error {
    fn from(e: tokio_rusqlite::Error) -> Self {
        Error::Data(data::Error::Rusqlite(e))
    }
}

impl From<data::Error> for Error {
    fn from(e: data::Error) -> Self {
        Error::Data(e)
    }
}

impl From<p2p::Error> for Error {
    fn from(e: p2p::Error) -> Self {
        Error::P2P(e)
    }
}
