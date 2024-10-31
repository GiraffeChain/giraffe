use std::vec;

use crate::{
    codecs::{hash256, script_to_address, to_b58},
    genesis,
    models::{Address, FullBlock, Script, StakingRegistration, Transaction, TransactionOutput},
};
use vrf::{
    openssl::{CipherSuite, ECVRF},
    VRF,
};

pub struct TestnetAccount {
    pub operator_keypair: secp256k1::Keypair,
    pub vrf_sk: Vec<u8>,
    pub vrf_vk: Vec<u8>,
    pub registration_signature: Vec<u8>,
    pub quantity: u64,
}

impl TestnetAccount {
    pub fn generate(quantity: u64, seed: Vec<u8>) -> TestnetAccount {
        let operator_sk_vec = hash256({
            let mut v = seed.clone();
            v.push(0);
            v.clone().as_slice()
        });
        let alg = secp256k1::Secp256k1::new();
        let operator_sk = secp256k1::SecretKey::from_slice(operator_sk_vec.as_slice()).unwrap();
        let operator_keypair = secp256k1::Keypair::from_secret_key(&alg, &operator_sk);
        let vrf_sk = hash256({
            let mut v = seed.clone();
            v.push(1);
            v.clone().as_slice()
        });
        let mut vrf = ECVRF::from_suite(CipherSuite::SECP256K1_SHA256_TAI).unwrap();
        let vrf_vk = vrf.derive_public_key(vrf_sk.as_slice()).unwrap();
        let registration_message = hash256(&vrf_vk);
        let registration_signature = alg
            .sign_schnorr_no_aux_rand(&registration_message.as_slice(), &operator_keypair)
            .as_byte_array()
            .to_vec();
        TestnetAccount {
            operator_keypair,
            vrf_sk,
            vrf_vk,
            registration_signature,
            quantity,
        }
    }

    pub fn registration(&self) -> StakingRegistration {
        StakingRegistration {
            commitment_signature: to_b58(&self.registration_signature),
            vk: to_b58(&self.operator_keypair.public_key().serialize()),
        }
    }

    pub fn transaction(&self) -> Transaction {
        Transaction {
            transaction_id: None,
            inputs: vec![],
            outputs: vec![TransactionOutput {
                address: Some(address()),
                quantity: self.quantity,
                edge: None,
                asset: None,
                label: None,
                data: None,
                staking_registration: Some(self.registration()),
            }],
            attestation: vec![],
            reward_parent_block_id: None,
        }
    }
}

pub fn init(timestamp: u64, stakes: Vec<u64>) -> FullBlock {
    let mut accounts = vec![];
    for (i, stake) in stakes.iter().enumerate() {
        let mut seed = timestamp.clone().to_be_bytes().to_vec();
        seed.append(&mut i.to_be_bytes().to_vec());
        let account = TestnetAccount::generate(*stake, seed);
        accounts.push(account);
    }
    let mut transactions: Vec<Transaction> = accounts.iter().map(|a| a.transaction()).collect();

    transactions.push(Transaction {
        transaction_id: None,
        inputs: vec![],
        outputs: vec![TransactionOutput {
            address: Some(address()),
            quantity: 1000000000,
            edge: None,
            asset: None,
            label: None,
            data: None,
            staking_registration: None,
        }],
        attestation: vec![],
        reward_parent_block_id: None,
    });

    let genesis = genesis::init(timestamp, transactions);
    genesis
}

pub fn address() -> Address {
    let sk_vec = vec![0u8; 32];
    let alg = secp256k1::Secp256k1::new();
    let sk = secp256k1::SecretKey::from_slice(sk_vec.as_slice()).unwrap();
    let kp = secp256k1::Keypair::from_secret_key(&alg, &sk);
    let script = Script {
        value: to_b58(&kp.public_key().serialize()),
    };
    script_to_address(&script)
}
