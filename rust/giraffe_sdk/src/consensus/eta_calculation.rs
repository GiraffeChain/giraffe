use sha2::{Digest, Sha256};

use crate::{
    clock::Clock,
    codecs::from_b58,
    data::Storage,
    models::{BlockHeader, SlotId},
};

use super::rho::{rho, rho_nonce_hash};

pub struct EtaCalCulation {
    genesis_eta: Vec<u8>,
    clock: Clock,
}

impl EtaCalCulation {
    pub async fn next_eta<S: Storage>(
        &self,
        storage: S,
        parent_slot_id: SlotId,
        child_slot: i64,
    ) -> Vec<u8> {
        let child_epoch = self.clock.epoch_of(child_slot);
        if child_epoch == 0 {
            return self.genesis_eta.clone();
        } else {
            let parent_epoch = self.clock.epoch_of(parent_slot_id.slot as i64);
            let parent_header = storage.fetch_header(parent_slot_id.block_id.unwrap()).await;
            if parent_epoch == child_epoch {
                return from_b58(&parent_header.staker_certificate.unwrap().eta);
            } else if child_epoch - parent_epoch > 1 {
                panic!("Eta calculation encountered empty epoch");
            } else {
                let two_thirds_length = 2 * self.clock.epoch_length_slots / 3;
                let mut two_thirds_best = parent_header;
                while two_thirds_best.slot % self.clock.epoch_length_slots > two_thirds_length {
                    two_thirds_best = storage
                        .fetch_header(two_thirds_best.parent_header_id.unwrap())
                        .await;
                }
                return self.calculate(storage, &two_thirds_best).await;
            }
        }
    }

    async fn calculate<S: Storage>(&self, storage: S, two_thirds_best: &BlockHeader) -> Vec<u8> {
        let epoch = self.clock.epoch_of(two_thirds_best.slot as i64);
        let (epoch_start, _) = self.clock.epoch_range(epoch);
        let mut epoch_data: Vec<BlockHeader> = Vec::new();
        epoch_data.push(two_thirds_best.clone());
        let mut cont = false;
        let parent = storage
            .fetch_header(two_thirds_best.parent_header_id.clone().unwrap())
            .await;
        if parent.slot >= (epoch_start as u64) {
            epoch_data.push(parent.clone());
            cont = true;
        }
        while cont {
            let parent = storage
                .fetch_header(two_thirds_best.parent_header_id.clone().unwrap())
                .await;
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
}
