use giraffe_sdk::models::{Args, Transaction};

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

pub async fn init_blockchain() -> bool {
    let blockchain = std::sync::Arc::new(tokio::sync::Mutex::new(
        giraffe_sdk::blockchain::Blockchain::init().await.unwrap(),
    ));
    giraffe_sdk::p2p::start(2023, vec![], blockchain)
        .await
        .unwrap();
    true
}

pub async fn wasm_test(script: String, input: i32) -> bool {
    let tx = giraffe_sdk::models::Transaction {
        transaction_id: None,
        reward_parent_block_id: None,
        inputs: vec![],
        outputs: vec![],
        attestation: vec![giraffe_sdk::models::Witness {
            address: None,
            args: Some(Args {
                value: Some(prost_types::Struct {
                    fields: std::collections::BTreeMap::from([(
                        "0".to_string(),
                        prost_types::Value {
                            kind: Some(prost_types::value::Kind::StringValue(input.to_string())),
                        },
                    )]),
                }),
            }),
            script: Some(giraffe_sdk::models::Script { value: script }),
        }],
    };
    giraffe_sdk::ledger::vm::verify(&tx).await.unwrap()
}
