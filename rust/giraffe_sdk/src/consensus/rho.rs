use sha2::{Digest, Sha512};
use vrf::openssl::{CipherSuite, ECVRF};

use crate::codecs::from_b58;

pub fn rho(proof: &String) -> Vec<u8> {
    let mut vrf = ECVRF::from_suite(CipherSuite::SECP256K1_SHA256_TAI).unwrap();
    let pi = from_b58(proof);
    let rho = vrf.proof_to_hash(pi.as_slice()).unwrap();
    return rho;
}

pub fn rho_test_hash(rho: Vec<u8>) -> Vec<u8> {
    let mut hasher = Sha512::new();
    hasher.update(rho);
    hasher.update("test".as_bytes());
    hasher.finalize().to_vec()
}
