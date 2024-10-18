pub mod clock;
pub mod codecs;
pub mod consensus;
pub mod models;

pub fn add(left: u64, right: u64) -> u64 {
    left + right
}

pub fn create_tx() -> models::Transaction {
    let mut tx = models::Transaction::default();
    let mut out = models::TransactionOutput::default();
    out.quantity = 500;
    out.lock_address = Some(models::LockAddress {
        value: codecs::to_b58(&[0; 32]),
    });
    tx.outputs.push(out);
    return tx;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let tx = create_tx();
        let id = codecs::show_transaction_id(&codecs::transaction_id(&tx));
        println!("Transaction ID: {}", id);
        assert_eq!(tx.outputs.len(), 1);
    }
}
