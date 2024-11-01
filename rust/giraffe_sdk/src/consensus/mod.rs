use eta_calculation::EtaCalculation;
use header_validation::HeaderValidation;
use local_chain::LocalChain;
use protocol_settings::ProtocolSettings;
use staker_tracker::StakerTracker;
use tokio_rusqlite::Connection;

use crate::{
    clock::Clock,
    codecs::{block_id, from_b58_string},
    models::FullBlock,
};

pub mod chain_selection;
pub mod eta_calculation;
pub mod header_validation;
pub mod leader_election;
pub mod local_chain;
pub mod protocol_settings;
pub mod rho;
pub mod staker_tracker;

pub struct Consensus {
    pub eta_calculation: EtaCalculation,
    pub staker_tracker: StakerTracker,
    pub header_validation: HeaderValidation,
    pub local_chain: LocalChain,
}

impl Consensus {
    pub async fn new(
        genesis: FullBlock,
        protocol_settings: ProtocolSettings,
        clock: Clock,
        connection: Connection,
    ) -> Self {
        let genesis_id = block_id(&genesis.header.clone().unwrap());
        let eta_calculation = EtaCalculation::new(
            from_b58_string(
                genesis
                    .header
                    .clone()
                    .unwrap()
                    .staker_certificate
                    .unwrap()
                    .eta,
            ),
            clock.clone(),
            connection.clone(),
        );
        let staker_tracker =
            StakerTracker::new(genesis_id.clone(), clock.clone(), connection.clone());
        let header_validation = HeaderValidation::new(
            genesis_id.clone(),
            protocol_settings.clone(),
            eta_calculation.clone(),
            staker_tracker.clone(),
            connection.clone(),
        );
        let local_chain = LocalChain::new(genesis_id, connection.clone());
        Consensus {
            eta_calculation,
            staker_tracker,
            header_validation,
            local_chain,
        }
    }
}
