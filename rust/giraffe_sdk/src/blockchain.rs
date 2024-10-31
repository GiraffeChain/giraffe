use tokio_rusqlite::Connection;

use crate::{
    clock::Clock,
    consensus::{protocol_settings::ProtocolSettings, Consensus},
    ledger::Ledger,
    models::FullBlock,
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
}
