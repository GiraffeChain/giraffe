use std::collections::HashMap;
use std::string;

use crate::minting::staking::{PartialStakerCertificate, UnsignedBlockHeader};
use crate::models::{self, BlockHeader};
use crate::models::{
    AccountRegistration, Asset, BlockId, Edge, GraphEntry, Lock, LockAddress, StakingRegistration,
    Transaction, TransactionId, TransactionInput, TransactionOutput, TransactionOutputReference,
    Vertex,
};
use base58::{FromBase58, ToBase58};
use prost_types;
use sha2::{Digest, Sha256};

pub fn show_block_id(block_id: &models::BlockId) -> String {
    format!("b_{}", block_id.value)
}

pub fn show_transaction_id(transaciton_id: &models::TransactionId) -> String {
    format!("t_{}", transaciton_id.value)
}

pub fn show_lock_address(lock_address: &models::LockAddress) -> String {
    format!("a_{}", lock_address.value)
}

pub fn show_transaction_output_reference(reference: &TransactionOutputReference) -> String {
    format!(
        "{}:{}",
        show_transaction_id(&reference.transaction_id.clone().unwrap()),
        reference.index
    )
}

pub fn decode_block_id(input: &str) -> BlockId {
    let value = if input.starts_with("b_") {
        &input[2..]
    } else {
        input
    };
    if value.from_base58().unwrap().len() != 32 {
        panic!("Invalid block ID");
    }
    BlockId {
        value: value.to_string(),
    }
}

pub fn decode_transaction_id(input: &str) -> TransactionId {
    let value = if input.starts_with("t_") {
        &input[2..]
    } else {
        input
    };
    if value.from_base58().unwrap().len() != 32 {
        panic!("Invalid transaction ID");
    }
    TransactionId {
        value: value.to_string(),
    }
}

pub fn decode_lock_address(input: &str) -> LockAddress {
    let value = if input.starts_with("a_") {
        &input[2..]
    } else {
        input
    };
    if value.from_base58().unwrap().len() != 32 {
        panic!("Invalid address");
    }
    LockAddress {
        value: value.to_string(),
    }
}

pub fn transaction_signable_bytes(transaction: &Transaction) -> Vec<u8> {
    merge_arrays(&[
        encode_list(encode_transaction_input, &transaction.inputs),
        encode_list(encode_transaction_output, &transaction.outputs),
        opt_codec(&transaction.reward_parent_block_id, encode_block_id),
    ])
}

pub fn transaction_id(transaction: &Transaction) -> TransactionId {
    if let Some(ref id) = transaction.transaction_id {
        id.clone()
    } else {
        compute_transaction_id(transaction)
    }
}

pub fn embed_transaction_id(transaction: &mut Transaction) {
    transaction.transaction_id = Some(compute_transaction_id(transaction));
}

pub fn compute_transaction_id(transaction: &Transaction) -> TransactionId {
    let hash = hash256(&transaction_signable_bytes(transaction));
    TransactionId {
        value: hash.to_base58(),
    }
}

pub trait TransactionExt {
    fn id(&self) -> models::TransactionId;
    fn embed_transaction_id(&mut self);
    fn signable_bytes(&self) -> Vec<u8>;
}

impl TransactionExt for models::Transaction {
    fn id(&self) -> models::TransactionId {
        transaction_id(self)
    }

    fn embed_transaction_id(&mut self) {
        embed_transaction_id(self)
    }

    fn signable_bytes(&self) -> Vec<u8> {
        transaction_signable_bytes(self)
    }
}

pub fn block_signable_bytes(header: &BlockHeader) -> Vec<u8> {
    merge_arrays(&[
        encode_block_id(&header.parent_header_id.as_ref().unwrap()),
        from_b58(&header.tx_root),
        encode_u64(header.timestamp),
        encode_u64(header.height),
        encode_u64(header.slot),
        encode_staker_certificate(&header.staker_certificate.as_ref().unwrap()),
        encode_transaction_output_reference(&header.account.as_ref().unwrap()),
    ])
}

pub fn unsigned_block_signable_bytes(header: &UnsignedBlockHeader) -> Vec<u8> {
    merge_arrays(&[
        encode_block_id(&header.parent_header_id.as_ref().unwrap()),
        from_b58(&header.tx_root),
        encode_u64(header.timestamp),
        encode_u64(header.height),
        encode_u64(header.slot),
        encode_partial_staker_certificate(&header.partial_staker_certificate.as_ref().unwrap()),
        encode_transaction_output_reference(&header.account.as_ref().unwrap()),
        encode_block_settings(&header.settings),
    ])
}

pub fn encode_block_settings(settings: &HashMap<String, String>) -> Vec<u8> {
    let mut result = Vec::new();
    for (key, value) in settings.iter() {
        result.extend(merge_arrays(&[encode_utf8(key), encode_utf8(value)]));
    }
    result
}

pub fn block_id(header: &BlockHeader) -> BlockId {
    if let Some(ref id) = header.header_id {
        id.clone()
    } else {
        compute_block_id(header)
    }
}

pub fn embed_block_id(header: &mut BlockHeader) {
    header.header_id = Some(compute_block_id(header));
}

pub fn compute_block_id(header: &BlockHeader) -> BlockId {
    let hash = hash256(&block_signable_bytes(header));
    BlockId {
        value: hash.to_base58(),
    }
}

pub trait BlockHeaderExt {
    fn id(&self) -> models::BlockId;
    fn embed_block_id(&mut self);
    fn signable_bytes(&self) -> Vec<u8>;
}

impl BlockHeaderExt for models::BlockHeader {
    fn id(&self) -> models::BlockId {
        block_id(self)
    }

    fn embed_block_id(&mut self) {
        embed_block_id(self)
    }

    fn signable_bytes(&self) -> Vec<u8> {
        block_signable_bytes(self)
    }
}

fn encode_i32(value: i32) -> Vec<u8> {
    value.to_be_bytes().to_vec()
}

fn encode_u32(value: u32) -> Vec<u8> {
    encode_i32(value as i32)
}

fn encode_i64(value: i64) -> Vec<u8> {
    value.to_be_bytes().to_vec()
}

fn encode_u64(value: u64) -> Vec<u8> {
    encode_i64(value as i64)
}

fn encode_list<T, F>(encode_t: F, list: &[T]) -> Vec<u8>
where
    F: Fn(&T) -> Vec<u8>,
{
    let mut result = encode_i32(list.len() as i32);
    for item in list {
        result.extend(encode_t(item));
    }
    result
}

fn encode_block_id(value: &BlockId) -> Vec<u8> {
    value.value.from_base58().unwrap()
}

fn encode_transaction_id(value: &TransactionId) -> Vec<u8> {
    value.value.from_base58().unwrap()
}

fn encode_transaction_input(input: &TransactionInput) -> Vec<u8> {
    merge_arrays(&[encode_transaction_output_reference(
        &input.reference.as_ref().unwrap(),
    )])
}

fn encode_transaction_output_reference(value: &TransactionOutputReference) -> Vec<u8> {
    merge_arrays(&[
        opt_codec(&value.transaction_id, encode_transaction_id),
        encode_u32(value.index),
    ])
}

fn encode_transaction_output(value: &TransactionOutput) -> Vec<u8> {
    merge_arrays(&[
        encode_lock_address(&value.lock_address.as_ref().unwrap()),
        encode_u64(value.quantity),
        opt_codec(&value.account, encode_transaction_output_reference),
        opt_codec(&value.graph_entry, encode_graph_entry),
        opt_codec(&value.account_registration, encode_account_registration),
        opt_codec(&value.asset, encode_asset),
    ])
}

fn encode_lock_address(value: &LockAddress) -> Vec<u8> {
    value.value.from_base58().unwrap()
}

fn encode_account_registration(value: &AccountRegistration) -> Vec<u8> {
    merge_arrays(&[
        encode_lock_address(&value.association_lock.as_ref().unwrap()),
        opt_codec(&value.staking_registration, encode_staking_registration),
    ])
}

fn encode_graph_entry(value: &GraphEntry) -> Vec<u8> {
    match value.entry.as_ref().unwrap() {
        models::graph_entry::Entry::Vertex(vertex) => encode_graph_vertex(&vertex),
        models::graph_entry::Entry::Edge(edge) => encode_graph_edge(&edge),
    }
}

fn encode_graph_vertex(value: &Vertex) -> Vec<u8> {
    merge_arrays(&[
        encode_utf8(&value.label),
        opt_codec(&value.data, encode_struct),
    ])
}

fn encode_graph_edge(value: &Edge) -> Vec<u8> {
    merge_arrays(&[
        encode_utf8(&value.label),
        opt_codec(&value.data, encode_struct),
        encode_transaction_output_reference(&value.a.as_ref().unwrap()),
        encode_transaction_output_reference(&value.b.as_ref().unwrap()),
    ])
}

fn encode_asset(value: &Asset) -> Vec<u8> {
    merge_arrays(&[
        encode_transaction_output_reference(&value.origin.as_ref().unwrap()),
        encode_u64(value.quantity),
    ])
}

fn encode_struct(value: &prost_types::Struct) -> Vec<u8> {
    let fields = &value.fields;
    let mut sorted_keys: Vec<_> = fields.keys().collect();
    sorted_keys.sort();
    let encoded_pairs: Vec<_> = sorted_keys
        .iter()
        .map(|k| {
            merge_arrays(&[
                encode_utf8(k),
                encode_struct_value(&fields.get(*k).unwrap()),
            ])
        })
        .collect();
    encode_list(|t| t.clone(), &encoded_pairs)
}

fn encode_staking_registration(value: &StakingRegistration) -> Vec<u8> {
    merge_arrays(&[
        value.commitment_signature.from_base58().unwrap(),
        value.vk.from_base58().unwrap(),
    ])
}

fn encode_lock(value: &Lock) -> Vec<u8> {
    match value.value.as_ref().unwrap() {
        models::lock::Value::Ed25519(ed25519) => ed25519.vk.from_base58().unwrap(),
    }
}

pub fn lock_to_address(value: &Lock) -> LockAddress {
    LockAddress {
        value: hash256(&encode_lock(value)).to_base58(),
    }
}

fn encode_struct_value(value: &prost_types::Value) -> Vec<u8> {
    match value.kind.as_ref().unwrap() {
        prost_types::value::Kind::StringValue(s) => encode_utf8(&s),
        prost_types::value::Kind::NumberValue(n) => encode_utf8(&n.to_string()),
        prost_types::value::Kind::BoolValue(b) => vec![if *b { 1 } else { 0 }],
        prost_types::value::Kind::ListValue(arr) => merge_arrays(
            &arr.values
                .iter()
                .map(encode_struct_value)
                .collect::<Vec<_>>(),
        ),
        prost_types::value::Kind::StructValue(obj) => encode_struct(&obj),
        _ => panic!("Unsupported struct value type"),
    }
}

fn encode_staker_certificate(value: &models::StakerCertificate) -> Vec<u8> {
    merge_arrays(&[
        // from_b58(&value.block_signature),
        from_b58(&value.vrf_signature),
        from_b58(&value.vrf_vk),
        from_b58(&value.eta),
    ])
}

fn encode_partial_staker_certificate(value: &PartialStakerCertificate) -> Vec<u8> {
    merge_arrays(&[
        // from_b58(&value.block_signature),
        from_b58(&value.vrf_signature),
        from_b58(&value.vrf_vk),
        from_b58(&value.eta),
    ])
}

pub fn encode_utf8(value: &str) -> Vec<u8> {
    value.as_bytes().to_vec()
}

pub fn hash256(data: &[u8]) -> Vec<u8> {
    let mut hasher = Sha256::new();
    hasher.update(data);
    hasher.finalize().to_vec()
}

pub fn to_b58(data: &[u8]) -> String {
    data.to_base58()
}

pub fn from_b58(data: &str) -> Vec<u8> {
    data.from_base58().unwrap()
}

pub fn from_b58_string(data: String) -> Vec<u8> {
    data.from_base58().unwrap()
}

fn opt_codec<T, F>(t: &Option<T>, encode: F) -> Vec<u8>
where
    F: Fn(&T) -> Vec<u8>,
{
    if let Some(ref value) = t {
        merge_arrays(&[vec![1], encode(value)])
    } else {
        vec![0]
    }
}

fn merge_arrays(arrays: &[Vec<u8>]) -> Vec<u8> {
    let total_length: usize = arrays.iter().map(|arr| arr.len()).sum();
    let mut result = Vec::with_capacity(total_length);
    for arr in arrays {
        result.extend(arr);
    }
    result
}
