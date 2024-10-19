use num_bigint::BigInt;
use num_rational::BigRational;

pub struct ProtocolSettings {
    pub f_effective: BigRational,
    pub vrf_amplitude: BigRational,
    pub chain_selection_k_lookback: u64,
    pub slot_duration_ms: u64,
}

impl ProtocolSettings {
    pub fn chain_selection_s_window(&self) -> u64 {
        (BigRational::new(
            BigInt::from(self.chain_selection_k_lookback),
            BigInt::from(4),
        ) * self.f_effective.recip())
        .to_integer()
        .to_u64_digits()
        .1[0]
    }
    pub fn epoch_length(&self) -> u64 {
        (BigRational::new(
            BigInt::from(self.chain_selection_k_lookback),
            BigInt::from(3),
        ) * self.f_effective.recip())
        .to_integer()
        .to_u64_digits()
        .1[0]
    }
}
