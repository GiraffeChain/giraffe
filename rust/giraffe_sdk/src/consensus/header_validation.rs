use vrf::{
    openssl::{CipherSuite, ECVRF},
    VRF,
};

use crate::{
    clock::Clock,
    codecs::{from_b58, BlockHeaderExt},
    data::Storage,
    models::{BlockHeader, BlockId, SlotId},
};

use super::{eta_calculation::EtaCalCulation, protocol_settings::ProtocolSettings};

pub struct HeaderValidation {
    pub genesis_id: BlockId,
    pub eta_calculation: EtaCalCulation,
    pub protocol_settings: ProtocolSettings,
    pub clock: Clock,
}

impl HeaderValidation {
    pub async fn validate<S: Storage>(&self, header: &BlockHeader, storage: S) -> Result<(), &str> {
        if header.id() == self.genesis_id {
            return Ok(());
        }
        let parent = storage
            .fetch_header(header.parent_header_id.clone().unwrap())
            .await;
        if header.slot <= parent.slot {
            return Err("Non-Forward slot");
        }
        if header.height != parent.height + 1 {
            return Err("Non-Incremental height");
        }
        if header.timestamp <= parent.timestamp {
            return Err("Non-Forward timestamp");
        }
        let expected_eta = self
            .eta_calculation
            .next_eta(
                storage,
                SlotId {
                    slot: parent.slot,
                    block_id: header.parent_header_id.clone(),
                },
                header.slot as i64,
            )
            .await;
        let eta = from_b58(&header.staker_certificate.clone().unwrap().eta);
        if eta == expected_eta {
            return Err("Invalid eta");
        }

        let mut vrf = ECVRF::from_suite(CipherSuite::SECP256K1_SHA256_TAI).unwrap();
        let message = [
            from_b58(&header.staker_certificate.clone().unwrap().eta),
            header.slot.to_be_bytes().to_vec(),
        ]
        .concat();
        match vrf.verify(
            from_b58(&header.staker_certificate.clone().unwrap().vrf_vk).as_slice(),
            from_b58(&header.staker_certificate.clone().unwrap().vrf_signature).as_slice(),
            message.as_slice(),
        ) {
            Ok(_) => Ok(()),
            Err(_) => Err("Invalid VRF signature"),
        }
    }
}
