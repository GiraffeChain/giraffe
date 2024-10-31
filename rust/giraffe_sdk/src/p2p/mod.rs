use futures::StreamExt;
use libp2p::{request_response, swarm::SwarmEvent, Multiaddr};
use libp2p::{PeerId, StreamProtocol};
use peer_blockchain_interface::PeerState;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::error::Error;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;
use tracing_subscriber::EnvFilter;

pub mod peer_blockchain_interface;

type Swarm = libp2p::swarm::Swarm<request_response::cbor::Behaviour<ReqMessage, ResMessage>>;

pub async fn start(port: u32, known_peers: Vec<String>) -> Result<(), Box<dyn Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    let mut swarm: Swarm = libp2p::SwarmBuilder::with_new_identity()
        .with_tokio()
        .with_tcp(
            libp2p::tcp::Config::default(),
            libp2p::noise::Config::new,
            libp2p::yamux::Config::default,
        )?
        .with_quic()
        .with_behaviour(|k| {
            request_response::cbor::Behaviour::<ReqMessage, ResMessage>::new(
                [(
                    StreamProtocol::new("/blockchain/1"),
                    request_response::ProtocolSupport::Full,
                )],
                request_response::Config::default(),
            )
        })?
        .with_swarm_config(|cfg| cfg.with_idle_connection_timeout(Duration::from_secs(u64::MAX))) // Allows us to observe pings indefinitely.
        .build();

    swarm.listen_on(format!("/ip4/0.0.0.0/tcp/{}", port).parse()?)?;

    for known_peer in known_peers {
        let parts: Vec<&str> = known_peer.split(':').collect();
        let port: u32 = if let Some(str) = parts.get(1) {
            str.parse()?
        } else {
            DEFAULT_PORT
        };
        let remote: Multiaddr = format!("/ip4/{}/tcp/{}", parts[0], port).parse()?;
        swarm.dial(remote)?;
    }

    let mut peer_interfaces: HashMap<PeerId, PeerState> = HashMap::new();

    let swarm_arc_mutex = Arc::new(Mutex::new(&mut swarm));

    loop {
        match swarm_arc_mutex.lock().await.select_next_some().await {
            SwarmEvent::NewListenAddr { address, .. } => println!("Listening on {address:?}"),
            SwarmEvent::ConnectionEstablished { peer_id, .. } => {
                println!("Connected to {peer_id:?}");
                let peer_state = PeerState::new(peer_id, swarm_arc_mutex.clone());
                peer_interfaces.insert(peer_id, peer_state);
            }
            SwarmEvent::Behaviour(event) => println!("{event:?}"),
            _ => {}
        }
    }
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
