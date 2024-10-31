use std::{collections::HashMap, str::FromStr};

use num_bigint::BigInt;
use num_rational::BigRational;

#[derive(Debug, Clone)]
pub struct ProtocolSettings {
    pub f_effective: BigRational,
    pub vrf_amplitude: BigRational,
    pub chain_selection_k_lookback: u64,
    pub slot_duration_ms: u64,
}

impl ProtocolSettings {
    pub fn default() -> ProtocolSettings {
        ProtocolSettings {
            f_effective: BigRational::new(BigInt::from(1), BigInt::from(50)),
            vrf_amplitude: BigRational::new(BigInt::from(1), BigInt::from(40)),
            chain_selection_k_lookback: 576,
            slot_duration_ms: 500,
        }
    }
    pub fn with(&self, map: HashMap<String, String>) -> ProtocolSettings {
        let mut r = self.clone();
        if let Some(f_effective) = map.get("f_effective") {
            r.f_effective = BigRational::from_str(f_effective).unwrap();
        }
        if let Some(vrf_amplitude) = map.get("vrf_amplitude") {
            r.vrf_amplitude = BigRational::from_str(vrf_amplitude).unwrap();
        }
        if let Some(chain_selection_k_lookback) = map.get("chain_selection_k_lookback") {
            r.chain_selection_k_lookback = chain_selection_k_lookback.parse().unwrap();
        }
        if let Some(slot_duration_ms) = map.get("slot_duration_ms") {
            r.slot_duration_ms = slot_duration_ms.parse().unwrap();
        }
        r
    }
    pub fn as_map(&self) -> HashMap<String, String> {
        let mut map = HashMap::new();
        map.insert("f-effective".to_string(), self.f_effective.to_string());
        map.insert("vrf-amplitude".to_string(), self.vrf_amplitude.to_string());
        map.insert(
            "chain-selection-k-lookback".to_string(),
            self.chain_selection_k_lookback.to_string(),
        );
        map.insert(
            "slot-duration-ms".to_string(),
            self.slot_duration_ms.to_string(),
        );
        map
    }
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
