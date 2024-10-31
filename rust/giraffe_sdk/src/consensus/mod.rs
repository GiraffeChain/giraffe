use eta_calculation::EtaCalculation;
use header_validation::HeaderValidation;
use staker_tracker::StakerTracker;

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
}
