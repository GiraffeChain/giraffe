use futures::StreamExt;
use libp2p::swarm::DialError;
use libp2p::StreamProtocol;
use libp2p::{request_response, swarm::SwarmEvent, Multiaddr};
use peer_blockchain_interface::PeerState;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;
use tracing_subscriber::EnvFilter;

use crate::blockchain::Blockchain;

pub mod peer_blockchain_interface;

type Swarm = libp2p::swarm::Swarm<request_response::cbor::Behaviour<ReqMessage, ResMessage>>;

pub async fn start(
    port: u32,
    known_peers: Vec<String>,
    blockchain: Arc<tokio::sync::Mutex<Blockchain>>,
) -> Result<(), Error> {
    let _ = tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .try_init();

    let swarm = Arc::new(tokio::sync::Mutex::new(
        libp2p::SwarmBuilder::with_new_identity()
            .with_tokio()
            .with_tcp(
                libp2p::tcp::Config::default(),
                libp2p::noise::Config::new,
                libp2p::yamux::Config::default,
            )
            .map_err(|e| Error::Other(e.to_string()))?
            .with_quic()
            .with_behaviour(|_| {
                request_response::cbor::Behaviour::<ReqMessage, ResMessage>::new(
                    [(
                        StreamProtocol::new("/blockchain/1"),
                        request_response::ProtocolSupport::Full,
                    )],
                    request_response::Config::default(),
                )
            })
            .map_err(|e| Error::Other(e.to_string()))?
            .with_swarm_config(|cfg| {
                cfg.with_idle_connection_timeout(Duration::from_secs(u64::MAX))
            }) // Allows us to observe pings indefinitely.
            .build(),
    ));

    swarm
        .lock()
        .await
        .listen_on(format!("/ip4/0.0.0.0/tcp/{}", port).parse()?)
        .map_err(|e| Error::Other(e.to_string()))?;

    for known_peer in known_peers {
        let parts: Vec<&str> = known_peer.split(':').collect();
        let port: u32 = if let Some(str) = parts.get(1) {
            str.parse()
                .map_err(|_| Error::Other("Unparseable port".to_string()))?
        } else {
            DEFAULT_PORT
        };
        let remote: Multiaddr = format!("/ip4/{}/tcp/{}", parts[0], port).parse()?;
        swarm.lock().await.dial(remote)?;
    }

    let peer_interfaces = Arc::new(tokio::sync::Mutex::new(HashMap::new()));

    tokio::spawn(async move {
        loop {
            match swarm.clone().lock().await.select_next_some().await {
                SwarmEvent::NewListenAddr { address, .. } => println!("Listening on {address:?}"),
                SwarmEvent::ConnectionEstablished { peer_id, .. } => {
                    println!("Connected to {peer_id:?}");
                    let peer_state = PeerState::new(peer_id, swarm.clone(), blockchain.clone());
                    peer_interfaces
                        .clone()
                        .lock()
                        .await
                        .insert(peer_id, peer_state);
                }
                SwarmEvent::ConnectionClosed { peer_id, .. } => {
                    println!("Disconnected from {peer_id:?}");
                    peer_interfaces.clone().lock().await.remove(&peer_id);
                }
                SwarmEvent::Behaviour(event) => match event {
                    request_response::Event::Message { peer, message, .. } => {
                        if let Some(peer_state) = peer_interfaces.clone().lock().await.get(&peer) {
                            let r = match message {
                                request_response::Message::Request {
                                    request, channel, ..
                                } => peer_state.handle_request(request, channel).await,
                                request_response::Message::Response {
                                    request_id,
                                    response,
                                } => peer_state.handle_response(&request_id, response).await,
                            };
                            match r {
                                Ok(_) => {}
                                Err(e) => {
                                    let _ = swarm.clone().lock().await.disconnect_peer_id(peer);
                                    println!("Error: {e:?}");
                                }
                            }
                        } else {
                            println!("Received message from unknown peer {peer:?}");
                        }
                    }
                    _ => {}
                },
                _ => {}
            }
        }
    });
    Ok(())
}

const DEFAULT_PORT: u32 = 2024;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReqMessage {
    port: u8,
    data: Vec<u8>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ResMessage {
    data: Vec<u8>,
}

#[derive(Debug)]
pub enum Error {
    Dial(DialError),
    Other(String),
}

impl From<DialError> for Error {
    fn from(e: DialError) -> Self {
        Error::Dial(e)
    }
}

impl From<libp2p::multiaddr::Error> for Error {
    fn from(e: libp2p::multiaddr::Error) -> Self {
        Error::Other(e.to_string())
    }
}
