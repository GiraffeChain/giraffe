use std::{future::Future, pin::Pin};

use sha2::{Digest, Sha256};

use crate::{
    clock::Clock,
    codecs::from_b58,
    models::{BlockHeader, BlockId, SlotId},
};

use super::rho::{rho, rho_nonce_hash};

pub async fn next_eta<FetchHeader>(
    genesis_eta: Vec<u8>,
    fetch_header: FetchHeader,
    clock: Clock,
    parent_slot_id: SlotId,
    child_slot: i64,
) -> Vec<u8>
where
    FetchHeader: Fn(BlockId) -> Pin<Box<dyn Future<Output = BlockHeader>>>,
{
    let child_epoch = clock.epoch_of(child_slot);
    if child_epoch == 0 {
        return genesis_eta;
    } else {
        let parent_epoch = clock.epoch_of(parent_slot_id.slot as i64);
        let parent_header = fetch_header(parent_slot_id.block_id.unwrap()).await;
        if parent_epoch == child_epoch {
            return from_b58(&parent_header.staker_certificate.unwrap().eta);
        } else if child_epoch - parent_epoch > 1 {
            panic!("Eta calculation encountered empty epoch");
        } else {
            let two_thirds_length = 2 * clock.epoch_length_slots / 3;
            let mut two_thirds_best = parent_header;
            while two_thirds_best.slot % clock.epoch_length_slots > two_thirds_length {
                two_thirds_best = fetch_header(two_thirds_best.parent_header_id.unwrap()).await;
            }
            return calculate(fetch_header, clock, &two_thirds_best).await;
        }
    }
}

async fn calculate<FetchHeader>(
    fetch_header: FetchHeader,
    clock: Clock,
    two_thirds_best: &BlockHeader,
) -> Vec<u8>
where
    FetchHeader: Fn(BlockId) -> Pin<Box<dyn Future<Output = BlockHeader>>>,
{
    let epoch = clock.epoch_of(two_thirds_best.slot as i64);
    let (epoch_start, _) = clock.epoch_range(epoch);
    let mut epoch_data: Vec<BlockHeader> = Vec::new();
    epoch_data.push(two_thirds_best.clone());
    let mut cont = false;
    let parent = fetch_header(two_thirds_best.parent_header_id.clone().unwrap()).await;
    if parent.slot >= (epoch_start as u64) {
        epoch_data.push(parent.clone());
        cont = true;
    }
    while cont {
        let parent = fetch_header(two_thirds_best.parent_header_id.clone().unwrap()).await;
        if parent.slot >= (epoch_start as u64) {
            epoch_data.push(parent.clone());
            cont = true;
        } else {
            cont = false;
        }
    }
    let nonce_hashes = epoch_data
        .iter()
        .map(|header| rho(&header.staker_certificate.as_ref().unwrap().vrf_signature))
        .map(|rho| rho_nonce_hash(rho));
    let mut hasher = Sha256::new();
    hasher.update(from_b58(
        &two_thirds_best.staker_certificate.as_ref().unwrap().eta,
    ));
    hasher.update(epoch.to_be_bytes());
    for nonce_hash in nonce_hashes {
        hasher.update(nonce_hash);
    }
    hasher.finalize().to_vec()
}
