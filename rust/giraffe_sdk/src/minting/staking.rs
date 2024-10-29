use std::future::Future;

use num_bigint::BigInt;
use num_rational::BigRational;
use secp256k1::Secp256k1;
use vrf::{
    openssl::{CipherSuite, ECVRF},
    VRF,
};

use crate::{
    clock::Clock,
    codecs::{embed_block_id, to_b58, unsigned_block_signable_bytes},
    consensus::{
        eta_calculation::EtaCalculation, leader_election, protocol_settings::ProtocolSettings,
        rho::rho, staker_tracker::StakerTracker,
    },
    models::{BlockHeader, BlockId, SlotId, StakerCertificate, TransactionOutputReference},
};

pub struct Staker<ST: StakerTracker> {
    account: TransactionOutputReference,
    vk_vrf: Vec<u8>,
    sk_vrf: Vec<u8>,
    key_pair_operator: secp256k1::Keypair,
    eta_calculation: EtaCalculation,
    protocol_settings: ProtocolSettings,
    clock: Clock,
    staker_tracker: ST,
}

pub trait Staking {
    fn elect(&self, parent_slot_id: &SlotId, slot: u64) -> impl Future<Output = Option<VrfHit>>;

    fn sign_block(&self, block: &UnsignedBlockHeader) -> BlockHeader;

    fn proof_for_slot(&self, slot: u64, eta: Vec<u8>) -> Vec<u8>;

    fn rho_for_slot(&self, slot: u64, eta: Vec<u8>) -> Vec<u8>;
}

impl<ST: StakerTracker> Staking for Staker<ST> {
    async fn elect(&self, parent_slot_id: &SlotId, slot: u64) -> Option<VrfHit> {
        let eta = self
            .eta_calculation
            .next_eta(parent_slot_id.clone(), slot.clone() as i64)
            .await;
        let staker = self
            .staker_tracker
            .staker(
                &parent_slot_id.block_id.clone().unwrap(),
                &slot,
                &self.account,
            )
            .await;
        if let Some(staker) = staker {
            let total_stake = self
                .staker_tracker
                .total_active_stake(&parent_slot_id.block_id.clone().unwrap(), &slot)
                .await;
            let relative_stake =
                BigRational::new(BigInt::from(staker.quantity), BigInt::from(total_stake));
            let threshold = self
                .protocol_settings
                .get_threshold(relative_stake, slot - parent_slot_id.slot);
            let p = self.proof_for_slot(slot, eta.clone());
            let r = rho(p);
            if leader_election::is_eligible(threshold.clone(), r) {
                let test_proof = self.proof_for_slot(slot, eta.clone());
                let certificate = PartialStakerCertificate {
                    vrf_signature: to_b58(test_proof.as_slice()),
                    vrf_vk: to_b58(self.vk_vrf.as_slice()),
                    eta: to_b58(eta.clone().as_slice()),
                };
                return Some(VrfHit {
                    certificate,
                    slot,
                    threshold,
                    account: self.account.clone(),
                });
            } else {
                return None;
            }
        } else {
            return None;
        }
    }

    fn sign_block(&self, block: &UnsignedBlockHeader) -> BlockHeader {
        let signable = unsigned_block_signable_bytes(block);
        let message = signable.as_slice();
        let routine = Secp256k1::new();
        let signature = routine.sign_schnorr_no_aux_rand(message, &self.key_pair_operator);
        let partial = block.partial_staker_certificate.as_ref().unwrap();
        let certificate = StakerCertificate {
            block_signature: to_b58(signature.as_byte_array()),
            vrf_signature: partial.vrf_signature.clone(),
            vrf_vk: partial.vrf_vk.clone(),
            eta: partial.eta.clone(),
        };
        let mut header_base = BlockHeader {
            header_id: None,
            parent_header_id: block.parent_header_id.clone(),
            tx_root: block.tx_root.clone(),
            timestamp: block.timestamp,
            height: block.height,
            slot: block.slot,
            staker_certificate: Some(certificate),
            account: Some(self.account.clone()),
            settings: block.settings.clone(),
        };
        embed_block_id(&mut header_base);
        header_base
    }

    fn proof_for_slot(&self, slot: u64, eta: Vec<u8>) -> Vec<u8> {
        let message = [eta, slot.to_be_bytes().to_vec()].concat();
        let mut vrf = ECVRF::from_suite(CipherSuite::SECP256K1_SHA256_TAI).unwrap();
        let signature = vrf.prove(&self.sk_vrf, &message.as_slice()).unwrap();
        // vrf.verify(&self.vk_vrf, &signature, &message.as_slice()).unwrap();
        signature
    }

    fn rho_for_slot(&self, slot: u64, eta: Vec<u8>) -> Vec<u8> {
        let signature = self.proof_for_slot(slot, eta);
        rho(signature)
    }
}

#[derive(Clone, PartialEq)]
pub struct VrfHit {
    pub certificate: PartialStakerCertificate,
    pub slot: u64,
    pub threshold: BigRational,
    pub account: TransactionOutputReference,
}

#[derive(Clone, PartialEq)]
pub struct PartialStakerCertificate {
    pub vrf_signature: String,
    pub vrf_vk: String,
    pub eta: String,
}

#[derive(Clone, PartialEq)]
pub struct UnsignedBlockHeader {
    pub parent_header_id: Option<BlockId>,
    pub tx_root: String,
    pub timestamp: u64,
    pub height: u64,
    pub slot: u64,
    pub partial_staker_certificate: Option<PartialStakerCertificate>,
    pub account: Option<TransactionOutputReference>,
    pub settings: ::std::collections::HashMap<String, String>,
}
