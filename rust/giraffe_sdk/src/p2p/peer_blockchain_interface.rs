use std::{collections::HashMap, sync::Arc};

use libp2p::{request_response::RequestId, PeerId};
use prost::Message;
use tokio::io;
use tokio::sync::{oneshot, Mutex};

use crate::models::{BlockBody, BlockHeader, BlockId, PublicP2pState, Transaction, TransactionId};

use super::{ReqMessage, ResMessage};

pub struct PeerState<'a> {
    peer_id: PeerId,
    behaviour: Arc<Mutex<&'a mut super::Swarm>>,
    pending_requests: Arc<Mutex<HashMap<RequestId, oneshot::Sender<ResMessage>>>>,
}

impl PeerState<'_> {
    pub fn new<'a>(peer_id: PeerId, behaviour: Arc<Mutex<&'a mut super::Swarm>>) -> PeerState<'a> {
        PeerState {
            peer_id,
            behaviour,
            pending_requests: Arc::new(Mutex::new(HashMap::new())),
        }
    }
    pub async fn ping(&self, bytes: Vec<u8>) -> Result<Vec<u8>, io::Error> {
        let data = self.request(multiplexer_ids::PING, bytes).await?;
        Ok(data)
    }
    pub async fn public_state(&self) -> Result<PublicP2pState, io::Error> {
        let data = self.request(multiplexer_ids::PEER_STATE, vec![]).await?;
        PublicP2pState::decode(data.as_slice())
            .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not PublicP2PState"))
    }
    pub async fn next_block_adoption(&self) -> Result<BlockId, io::Error> {
        let data = self
            .request(multiplexer_ids::BLOCK_ADOPTION, vec![])
            .await?;
        BlockId::decode(data.as_slice())
            .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not BlockId"))
    }
    pub async fn next_transaction_notification(&self) -> Result<TransactionId, io::Error> {
        let data = self
            .request(multiplexer_ids::TRANSACTION_NOTIFICATION, vec![])
            .await?;
        TransactionId::decode(data.as_slice())
            .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not TransactionId"))
    }
    pub async fn fetch_header(&self, block_id: &BlockId) -> Result<Option<BlockHeader>, io::Error> {
        let data = self
            .request(multiplexer_ids::HEADER, block_id.encode_to_vec())
            .await?;
        if data.is_empty() {
            return Ok(None);
        }
        let h = BlockHeader::decode(data.as_slice())
            .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not BlockHeader"))?;
        Ok(Some(h))
    }
    pub async fn fetch_body(&self, block_id: &BlockId) -> Result<Option<BlockBody>, io::Error> {
        let data = self
            .request(multiplexer_ids::BODY, block_id.encode_to_vec())
            .await?;
        if data.is_empty() {
            return Ok(None);
        }
        let h = BlockBody::decode(data.as_slice())
            .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not BlockBody"))?;
        Ok(Some(h))
    }
    pub async fn fetch_transaction(
        &self,
        transaction_id: &TransactionId,
    ) -> Result<Option<Transaction>, io::Error> {
        let data = self
            .request(multiplexer_ids::TRANSACTION, transaction_id.encode_to_vec())
            .await?;
        if data.is_empty() {
            return Ok(None);
        }
        let h = Transaction::decode(data.as_slice())
            .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not Transaction"))?;
        Ok(Some(h))
    }
    pub async fn fetch_block_id_at_height(
        &self,
        height: &u64,
    ) -> Result<Option<BlockId>, io::Error> {
        let data = self
            .request(
                multiplexer_ids::BLOCK_ID_AT_HEIGHT,
                height.to_be_bytes().to_vec(),
            )
            .await?;
        if data.is_empty() {
            return Ok(None);
        }
        let h = BlockId::decode(data.as_slice())
            .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not BlockId"))?;
        Ok(Some(h))
    }

    pub async fn request(&self, port: u8, data: Vec<u8>) -> Result<Vec<u8>, io::Error> {
        let (sender, receiver) = oneshot::channel::<ResMessage>();
        let id = self
            .behaviour
            .lock()
            .await
            .behaviour_mut()
            .send_request(&self.peer_id, ReqMessage { port, data });
        self.pending_requests.lock().await.insert(id, sender);
        let res = receiver
            .await
            .map_err(|_| io::Error::other("OneShot error"))?;
        Ok(res.data)
    }
}

mod multiplexer_ids {
    pub const PING: u8 = 0;
    pub const PEER_STATE: u8 = 1;
    pub const BLOCK_ADOPTION: u8 = 2;
    pub const TRANSACTION_NOTIFICATION: u8 = 3;
    pub const HEADER: u8 = 4;
    pub const BODY: u8 = 5;
    pub const TRANSACTION: u8 = 6;
    pub const BLOCK_ID_AT_HEIGHT: u8 = 7;
}
