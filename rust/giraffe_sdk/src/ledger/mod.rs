use std::hash::Hash;

use crate::models::{Transaction, TransactionId, TransactionOutputReference};

pub mod utxos;
pub mod validation;
pub mod value_calculator;

pub fn get_dependencies(transaction: &Transaction) -> Vec<TransactionOutputReference> {
    let mut deps = Vec::new();
    for input in &transaction.inputs {
        if let Some(reference) = &input.reference {
            if !deps.contains(reference) {
                deps.push(reference.clone());
            }
        }
    }
    for output in &transaction.outputs {
        if let Some(edge) = &output.edge {
            if let Some(a) = edge.a.clone().filter(|r| r.transaction_id.is_some()) {
                if !deps.contains(&a) {
                    deps.push(a);
                }
            }
            if let Some(b) = edge.b.clone().filter(|r| r.transaction_id.is_some()) {
                if !deps.contains(&b) {
                    deps.push(b);
                }
            }
        }
    }
    deps
}

impl Eq for TransactionOutputReference {}

impl Hash for TransactionId {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.value.hash(state);
    }
}

impl Hash for TransactionOutputReference {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.transaction_id.hash(state);
        self.index.hash(state);
    }
}
