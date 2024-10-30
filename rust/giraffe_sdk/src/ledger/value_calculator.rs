use prost_types::Struct;

use crate::models::TransactionOutput;

pub fn required_minimum_quantity(output: &TransactionOutput) -> u64 {
    let mut res: u64 = 100;
    if output.asset.is_some() {
        res += 100;
    }
    if let Some(label) = &output.label {
        res += label.len() as u64 * 10;
    }
    if let Some(data) = &output.data {
        res += data_minimum_quantity(&data);
    }
    if output.edge.is_some() {
        res += 100;
    }
    if output.staking_registration.is_some() {
        res += 1000;
    }
    res
}

fn data_minimum_quantity(value: &Struct) -> u64 {
    let mut res: u64 = 0;
    for (key, value) in value.fields.iter() {
        res += key.len() as u64 + value_minimum_quantity(value);
    }
    res
}

fn value_minimum_quantity(value: &prost_types::Value) -> u64 {
    match value.kind.as_ref().unwrap() {
        prost_types::value::Kind::NumberValue(n) => n.to_string().len() as u64 * 10,
        prost_types::value::Kind::StringValue(s) => s.len() as u64 * 10,
        prost_types::value::Kind::StructValue(s) => data_minimum_quantity(&s),
        prost_types::value::Kind::ListValue(l) => {
            l.values.iter().map(|v| value_minimum_quantity(v)).sum()
        }
        _ => 10,
    }
}
