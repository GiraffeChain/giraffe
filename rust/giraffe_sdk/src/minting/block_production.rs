use std::{collections::HashMap, time::SystemTime};

use crate::{
    clock::Clock,
    codecs::{to_b58, BlockHeaderExt},
    consensus::staker_tracker::StakerTracker,
    models::{BlockHeader, FullBlock, FullBlockBody, LockAddress, SlotId},
};

use super::staking::{Staker, Staking, UnsignedBlockHeader, VrfHit};

pub struct BlockProducer<ST: StakerTracker> {
    pub staking: Staker<ST>,
    pub clock: Clock,
    pub reward_address: LockAddress,
}

impl<ST: StakerTracker> BlockProducer<ST> {
    pub async fn next_eligibility(&self, parent_slot_id: SlotId) -> Option<VrfHit> {
        let mut test = parent_slot_id.slot + 1;
        let exit_slot = self
            .clock
            .epoch_range(self.clock.epoch_of(test.clone() as i64))
            .1 as u64;
        while test < exit_slot {
            if let Some(vrf_hit) = self.staking.elect(&parent_slot_id, test).await {
                return Some(vrf_hit);
            }
            test += 1;
        }
        None
    }

    pub async fn make_block(&self, parent_header: BlockHeader, hit: VrfHit) -> FullBlock {
        let timestamp = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64;
        // TODO
        let tx_root = to_b58(Vec::with_capacity(32).as_slice());
        let unsigned_header: UnsignedBlockHeader = UnsignedBlockHeader {
            parent_header_id: Some(parent_header.id()),
            tx_root,
            timestamp,
            height: parent_header.height + 1,
            slot: hit.slot,
            partial_staker_certificate: Some(hit.certificate.clone()),
            account: Some(hit.account),
            settings: HashMap::new(),
        };
        let header = self.staking.sign_block(&unsigned_header);
        // TODO: Block Packer
        let full_body = FullBlockBody {
            transactions: Vec::new(),
        };
        FullBlock {
            header: Some(header),
            full_body: Some(full_body),
        }
    }
}
