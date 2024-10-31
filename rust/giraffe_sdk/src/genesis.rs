use crate::{
    codecs::{from_b58, hash256, to_b58, transaction_id},
    consensus::protocol_settings::{self, ProtocolSettings},
    models::{
        BlockHeader, BlockId, FullBlock, FullBlockBody, StakerCertificate, Transaction,
        TransactionId, TransactionOutputReference,
    },
};

const BYTE_STRING_ZERO_32: &str = "11111111111111111111111111111111";
const BYTE_STRING_ZERO_64: &str =
    "1111111111111111111111111111111111111111111111111111111111111111";
const BYTE_STRING_ZERO_80: &str =
    "11111111111111111111111111111111111111111111111111111111111111111111111111111111";

const HEIGHT: u64 = 1;
const SLOT: u64 = 0;
const PARENT_SLOT: i64 = -1;
pub fn parent_id() -> BlockId {
    BlockId {
        value: BYTE_STRING_ZERO_32.to_string(),
    }
}
pub fn parent_tx_root() -> String {
    BYTE_STRING_ZERO_32.to_string()
}
pub fn staking_account() -> TransactionOutputReference {
    TransactionOutputReference {
        transaction_id: Some(TransactionId {
            value: BYTE_STRING_ZERO_32.to_string(),
        }),
        index: 0,
    }
}
pub fn staker_certificate(eta: &Vec<u8>) -> StakerCertificate {
    StakerCertificate {
        block_signature: BYTE_STRING_ZERO_64.to_string(),
        vrf_signature: BYTE_STRING_ZERO_80.to_string(),
        vrf_vk: BYTE_STRING_ZERO_32.to_string(),
        eta: to_b58(eta),
    }
}
pub fn init(timestamp: u64, transactions: Vec<Transaction>) -> FullBlock {
    let eta = hash256({
        let mut bytes = vec![];
        bytes.append(&mut timestamp.to_be_bytes().to_vec());
        for tx in transactions.clone() {
            bytes.append(&mut from_b58(&transaction_id(&tx).value));
        }
        bytes.clone().as_slice()
    });
    let header = BlockHeader {
        header_id: None,
        parent_header_id: Some(parent_id()),
        tx_root: BYTE_STRING_ZERO_32.to_string(), // TODO
        timestamp,
        height: HEIGHT,
        slot: SLOT,
        staker_certificate: Some(staker_certificate(&eta)),
        account: Some(staking_account()),
        settings: ProtocolSettings::default().as_map(),
    };
    let full_body = FullBlockBody { transactions };
    FullBlock {
        header: Some(header),
        full_body: Some(full_body),
    }
}
