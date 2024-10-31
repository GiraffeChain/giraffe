use libp2p::core::connection;
use num_bigint::BigInt;
use num_rational::BigRational;
use sha2::{Digest, Sha256};
use tokio_rusqlite::Connection;
use vrf::{
    openssl::{CipherSuite, ECVRF},
    VRF,
};

use crate::{
    clock::Clock,
    codecs::{block_signable_bytes, from_b58, from_b58_string, BlockHeaderExt},
    data,
    models::{ActiveStaker, BlockHeader, BlockId, SlotId},
};

use super::{
    eta_calculation::EtaCalculation, leader_election, protocol_settings::ProtocolSettings,
    rho::rho_from_b58, staker_tracker::StakerTracker,
};

pub struct HeaderValidation {
    genesis_id: BlockId,
    protocol_settings: ProtocolSettings,
    clock: Clock,
    eta_calculation: EtaCalculation,
    connection: Connection,
    staker_tracker: StakerTracker,
}

impl HeaderValidation {
    pub fn new(
        genesis_id: BlockId,
        protocol_settings: ProtocolSettings,
        clock: Clock,
        eta_calculation: EtaCalculation,
        staker_tracker: StakerTracker,
        connection: Connection,
    ) -> Self {
        HeaderValidation {
            genesis_id,
            protocol_settings,
            clock,
            eta_calculation,
            connection,
            staker_tracker,
        }
    }
    pub async fn validate(&self, header: &BlockHeader) -> Result<(), String> {
        if header.id() == self.genesis_id {
            return Ok(());
        }
        let parent = data::fetch_header(&self.connection, header.parent_header_id.clone().unwrap())
            .await
            .ok_or("Parent header not found")?;
        if header.slot <= parent.slot {
            return Err("Non-Forward slot".to_string());
        }
        if header.height != parent.height + 1 {
            return Err("Non-Incremental height".to_string());
        }
        if header.timestamp <= parent.timestamp {
            return Err("Non-Forward timestamp".to_string());
        }
        if header.staker_certificate.is_none() {
            return Err("Uncertified Block".to_string());
        }
        // TODO: Global slot verification
        eta_verification(&self.eta_calculation, header, &parent).await?;
        let staker = registration_verification(&self, header).await?;
        block_signature_verification(header, &staker)?;
        eligibility_verification(self, header, &parent, &staker).await?;
        Ok(())
    }
}

async fn eta_verification(
    eta_calculation: &EtaCalculation,
    header: &BlockHeader,
    parent: &BlockHeader,
) -> Result<(), String> {
    let expected_eta = eta_calculation
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
        return Err("Invalid eta".to_string());
    }

    let mut vrf = ECVRF::from_suite(CipherSuite::SECP256K1_SHA256_TAI).unwrap();
    let message = [
        from_b58(&header.staker_certificate.clone().unwrap().eta),
        header.slot.to_be_bytes().to_vec(),
    ]
    .concat();
    vrf.verify(
        from_b58(&header.staker_certificate.clone().unwrap().vrf_vk).as_slice(),
        from_b58(&header.staker_certificate.clone().unwrap().vrf_signature).as_slice(),
        message.as_slice(),
    )
    .map_err(|_| "Invalid VRF signature")?;
    Ok(())
}

async fn registration_verification(
    v: &HeaderValidation,
    header: &BlockHeader,
) -> Result<ActiveStaker, String> {
    let staker = v
        .staker_tracker
        .staker(
            &header.parent_header_id.clone().unwrap(),
            &header.slot,
            &header.account.clone().unwrap(),
        )
        .await
        .ok_or("Unregistered Staker")?;
    let mut digest = Sha256::new();
    digest.update(from_b58(&header.staker_certificate.clone().unwrap().vrf_vk));
    let message = digest.finalize().to_vec();
    let signature_vec = from_b58_string(staker.registration.clone().unwrap().commitment_signature);
    let signature = match signature_vec.len() {
        64 => {
            let mut ret: [u8; 64] = [0u8; 64];
            ret[..].copy_from_slice(signature_vec.as_slice());
            secp256k1::schnorr::Signature::from_byte_array(ret)
        }
        _ => return Err("Invalid Signature".to_string()),
    };
    let vk_vec = from_b58_string(staker.registration.clone().unwrap().vk);
    let vk = match vk_vec.len() {
        33 => {
            let mut ret: [u8; 32] = [0u8; 32];
            ret[..].copy_from_slice(vk_vec.as_slice());
            secp256k1::XOnlyPublicKey::from_byte_array(&ret).map_err(|_| "Invalid VK")?
        }
        _ => return Err("Invalid VK".to_string()),
    };
    let secp256k1 = secp256k1::Secp256k1::new();
    secp256k1
        .verify_schnorr(&signature, &message, &vk)
        .map_err(|_| "Registration commitment mismatch")?;

    Ok(staker)
}

async fn eligibility_verification(
    v: &HeaderValidation,
    header: &BlockHeader,
    parent: &BlockHeader,
    staker: &ActiveStaker,
) -> Result<(), String> {
    let total_stake = v
        .staker_tracker
        .total_active_stake(&header.parent_header_id.clone().unwrap(), &header.slot)
        .await;
    let relative_stake = BigRational::new(BigInt::from(staker.quantity), BigInt::from(total_stake));
    let threshold = v
        .protocol_settings
        .get_threshold(relative_stake, header.slot - parent.slot);
    let rho = rho_from_b58(&header.staker_certificate.clone().unwrap().vrf_signature);
    if !leader_election::is_eligible(threshold, rho) {
        return Err("Ineligible".to_string());
    }
    Ok(())
}

fn block_signature_verification(header: &BlockHeader, staker: &ActiveStaker) -> Result<(), String> {
    let message = block_signable_bytes(header);
    let signature_vec = from_b58_string(header.staker_certificate.clone().unwrap().block_signature);
    let signature = match signature_vec.len() {
        64 => {
            let mut ret: [u8; 64] = [0u8; 64];
            ret[..].copy_from_slice(signature_vec.as_slice());
            secp256k1::schnorr::Signature::from_byte_array(ret)
        }
        _ => return Err("Invalid Signature".to_string()),
    };
    let vk_vec = from_b58_string(staker.registration.clone().unwrap().vk);
    let vk = match vk_vec.len() {
        33 => {
            let mut ret: [u8; 32] = [0u8; 32];
            ret[..].copy_from_slice(vk_vec.as_slice());
            secp256k1::XOnlyPublicKey::from_byte_array(&ret).map_err(|_| "Invalid VK")?
        }
        _ => return Err("Invalid VK".to_string()),
    };
    let secp256k1 = secp256k1::Secp256k1::new();
    secp256k1
        .verify_schnorr(&signature, &message, &vk)
        .map_err(|_| "Invalid Block Signature")?;
    Ok(())
}
