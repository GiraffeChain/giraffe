pub mod com {
    pub mod giraffechain {
        pub mod models {
            include!(concat!(env!("OUT_DIR"), "/com.giraffechain.models.rs"));
        }
    }
}

pub fn add(left: u64, right: u64) -> u64 {
    left + right
}

pub fn create_tx() -> com::giraffechain::models::Transaction {
    let mut tx = com::giraffechain::models::Transaction::default();
    tx.inputs
        .push(com::giraffechain::models::TransactionInput::default());
    tx.outputs
        .push(com::giraffechain::models::TransactionOutput::default());
    return tx;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let tx = create_tx();
        assert_eq!(tx.inputs.len(), 1);
    }
}
