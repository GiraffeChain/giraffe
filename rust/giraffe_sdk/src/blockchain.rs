use tokio_rusqlite::Connection;

use crate::{clock::Clock, consensus::Consensus, ledger::Ledger};

pub struct Blockchain {
    pub connection: Connection,
    pub clock: Clock,
    pub consensus: Consensus,
    pub ledger: Ledger,
}
