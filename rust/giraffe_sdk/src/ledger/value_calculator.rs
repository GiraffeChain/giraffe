use prost_types::Struct;

use crate::models::{graph_entry, GraphEntry, TransactionOutput};

pub fn required_minimum_quantity(output: &TransactionOutput) -> u64 {
    let mut res: u64 = 100;
    if output.staking_registration.is_some() {
        res += 1000;
    }
    if let Some(graph_entry) = &output.graph_entry {
        res += graph_entry_minimum_quantity(&graph_entry);
    }
    if output.asset.is_some() {
        res += 100;
    }
    res
}

fn graph_entry_minimum_quantity(graph_entry: &GraphEntry) -> u64 {
    match &graph_entry.entry {
        Some(graph_entry::Entry::Vertex(vertex)) => {
            vertex.label.len() as u64 * 10
                + vertex
                    .data
                    .as_ref()
                    .map(|d| data_minimum_quantity(&d))
                    .unwrap_or(0)
        }
        Some(graph_entry::Entry::Edge(edge)) => {
            100 as u64
                + edge.label.len() as u64 * 10
                + edge
                    .data
                    .as_ref()
                    .map(|d| data_minimum_quantity(&d))
                    .unwrap_or(0)
        }
        _ => 0,
    }
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
