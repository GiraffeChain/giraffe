use vrf::{
    openssl::{CipherSuite, ECVRF},
    VRF,
};

use crate::{
    clock::Clock,
    codecs::{from_b58, BlockHeaderExt},
    data::FetchHeader,
    models::{BlockHeader, BlockId, SlotId},
};

use super::{eta_calculation::EtaCalculation, protocol_settings::ProtocolSettings};

pub struct HeaderValidation<F: FetchHeader> {
    pub genesis_id: BlockId,
    pub protocol_settings: ProtocolSettings,
    pub clock: Clock,
    pub eta_calculation: EtaCalculation<F>,
    pub fetch_header: F,
}

impl<F: FetchHeader> HeaderValidation<F> {
    pub async fn validate(&self, header: &BlockHeader) -> Result<(), &str> {
        if header.id() == self.genesis_id {
            return Ok(());
        }
        let parent = self
            .fetch_header
            .fetch(header.parent_header_id.clone().unwrap())
            .await
            .ok_or("Parent header not found")?;
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
