use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};

use libp2p::request_response::ResponseChannel;
use libp2p::{request_response::RequestId, PeerId};
use prost::Message;
use tokio::io;
use tokio::sync::oneshot;

use crate::blockchain::Blockchain;
use crate::data;
use crate::models::{
    BlockBody, BlockHeader, BlockId, ConnectedPeer, PublicP2pState, Transaction, TransactionId,
};

use super::{ReqMessage, ResMessage};

pub struct PeerState {
    peer_id: PeerId,
    swarm: Arc<tokio::sync::Mutex<super::Swarm>>,
    blockchain: Arc<tokio::sync::Mutex<Blockchain>>,
    pending_requests: Arc<Mutex<HashMap<RequestId, oneshot::Sender<ResMessage>>>>,
}

impl PeerState {
    pub fn new(
        peer_id: PeerId,
        swarm: Arc<tokio::sync::Mutex<super::Swarm>>,
        blockchain: Arc<tokio::sync::Mutex<Blockchain>>,
    ) -> PeerState {
        PeerState {
            peer_id,
            swarm,
            blockchain,
            pending_requests: Arc::new(Mutex::new(HashMap::new())),
        }
    }
    pub async fn handle_request(
        &self,
        req: ReqMessage,
        channel: ResponseChannel<ResMessage>,
    ) -> Result<(), io::Error> {
        match req.port {
            multiplexer_ids::PING => self
                .swarm
                .lock()
                .await
                .behaviour_mut()
                .send_response(channel, ResMessage { data: req.data })
                .map_err(|_| io::Error::other("Failed to handle response")),
            multiplexer_ids::PEER_STATE => {
                let swarm = self.swarm.lock().await;
                let peer_id = swarm.local_peer_id().clone();
                let local_addresses: Vec<String> =
                    swarm.external_addresses().map(|v| v.to_string()).collect();
                let public_state = PublicP2pState {
                    local_peer: Some(ConnectedPeer {
                        peer_id: peer_id.to_string(),
                        addresses: local_addresses,
                    }),
                    peers: vec![],
                };
                let data = public_state.encode_to_vec();
                self.swarm
                    .lock()
                    .await
                    .behaviour_mut()
                    .send_response(channel, ResMessage { data })
                    .map_err(|_| io::Error::other("Failed to handle response"))
            }
            multiplexer_ids::BLOCK_ADOPTION => {
                let block_id = self
                    .blockchain
                    .lock()
                    .await
                    .consensus
                    .local_chain
                    .receiver
                    .recv()
                    .await
                    .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not BlockId"))?;
                let data = block_id.encode_to_vec();
                self.swarm
                    .lock()
                    .await
                    .behaviour_mut()
                    .send_response(channel, ResMessage { data })
                    .map_err(|_| io::Error::other("Failed to handle response"))
            }
            multiplexer_ids::TRANSACTION_NOTIFICATION => {
                todo!()
            }
            multiplexer_ids::HEADER => {
                let block_id = BlockId::decode(req.data.as_slice())
                    .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not BlockId"))?;
                let blockchain = self.blockchain.lock().await;
                let header = data::fetch_header(&blockchain.connection, block_id).await;
                let data = header.map_or(vec![], |v| v.encode_to_vec());
                self.swarm
                    .lock()
                    .await
                    .behaviour_mut()
                    .send_response(channel, ResMessage { data })
                    .map_err(|_| io::Error::other("Failed to handle response"))
            }
            multiplexer_ids::BODY => {
                let block_id = BlockId::decode(req.data.as_slice())
                    .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not BlockId"))?;
                let blockchain = self.blockchain.lock().await;
                let body = data::fetch_body(&blockchain.connection, block_id).await;
                let data = body.map_or(vec![], |v| v.encode_to_vec());
                self.swarm
                    .lock()
                    .await
                    .behaviour_mut()
                    .send_response(channel, ResMessage { data })
                    .map_err(|_| io::Error::other("Failed to handle response"))
            }
            multiplexer_ids::TRANSACTION => {
                let tx_id = TransactionId::decode(req.data.as_slice()).map_err(|_| {
                    io::Error::new(std::io::ErrorKind::InvalidData, "Not TransactionId")
                })?;
                let blockchain = self.blockchain.lock().await;
                let tx = data::fetch_transaction(&blockchain.connection, tx_id).await;
                let data = tx.map_or(vec![], |v| v.encode_to_vec());
                self.swarm
                    .lock()
                    .await
                    .behaviour_mut()
                    .send_response(channel, ResMessage { data })
                    .map_err(|_| io::Error::other("Failed to handle response"))
            }
            multiplexer_ids::BLOCK_ID_AT_HEIGHT => {
                let height = i64::from_be_bytes(
                    req.data
                        .as_slice()
                        .try_into()
                        .map_err(|_| io::Error::new(std::io::ErrorKind::InvalidData, "Not i64"))?,
                );
                let mut blockchain = self.blockchain.lock().await;
                let id = blockchain
                    .consensus
                    .local_chain
                    .block_id_at_height(height)
                    .await
                    .map_err(|_| io::Error::other("Failed to handle response"))?;
                let data = id.map_or(vec![], |v| v.encode_to_vec());
                self.swarm
                    .lock()
                    .await
                    .behaviour_mut()
                    .send_response(channel, ResMessage { data })
                    .map_err(|_| io::Error::other("Failed to handle response"))
            }
            _ => Err(io::Error::other("Invalid port")),
        }
    }
    pub async fn handle_response(
        &self,
        request_id: &RequestId,
        res: ResMessage,
    ) -> Result<(), io::Error> {
        if let Some(sender) = self
            .pending_requests
            .lock()
            .map_err(|_| io::Error::other("Failed to handle response"))?
            .remove(request_id)
        {
            let _ = sender
                .send(res.clone())
                .map_err(|_| io::Error::other("Failed to handle response"))?;
        } else {
            return Err(io::Error::new(
                std::io::ErrorKind::InvalidData,
                "Invalid request id",
            ));
        }
        Ok(())
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
            .swarm
            .lock()
            .await
            .behaviour_mut()
            .send_request(&self.peer_id, ReqMessage { port, data });
        self.pending_requests
            .lock()
            .map_err(|_| io::Error::other("Failed to handle request"))?
            .insert(id, sender);
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
