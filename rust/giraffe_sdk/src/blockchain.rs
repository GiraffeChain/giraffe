use std::time::{SystemTime, UNIX_EPOCH};

use crate::{data, models::FullBlock, p2p, testnet};
use tokio_rusqlite::Connection;

use crate::{
    clock::Clock,
    consensus::{protocol_settings::ProtocolSettings, Consensus},
    ledger::Ledger,
};

pub struct Blockchain {
    pub connection: Connection,
    pub clock: Clock,
    pub consensus: Consensus,
    pub ledger: Ledger,
}

impl Blockchain {
    pub async fn new(genesis: FullBlock, connection: Connection) -> Self {
        let protocol_settings =
            ProtocolSettings::default().with(genesis.header.clone().unwrap().settings);
        let clock = Clock::from_settings(
            &protocol_settings,
            genesis.header.clone().unwrap().timestamp,
        );
        let consensus = Consensus::new(
            genesis.clone(),
            protocol_settings.clone(),
            clock.clone(),
            connection.clone(),
        )
        .await;
        let ledger = Ledger::new(&connection);
        Blockchain {
            connection,
            clock,
            consensus,
            ledger,
        }
    }

    pub async fn init() -> Result<Self, Error> {
        let db = tokio_rusqlite::Connection::open_in_memory().await?;
        data::init_db(&db).await?;
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64;
        let genesis: FullBlock = testnet::init(timestamp, vec![10000000]);
        let blockchain = Blockchain::new(genesis, db).await;
        println!("Initialized blockchain");
        Ok(blockchain)
    }
}

#[derive(Debug)]
pub enum Error {
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
