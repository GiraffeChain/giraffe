pub mod codecs;
pub mod models;

pub fn add(left: u64, right: u64) -> u64 {
    left + right
}

pub fn create_tx() -> models::Transaction {
    let mut tx = models::Transaction::default();
    tx.inputs.push(models::TransactionInput::default());
    tx.outputs.push(models::TransactionOutput::default());
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
