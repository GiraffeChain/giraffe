use crate::models::Transaction;
use wasmer::{imports, wat2wasm, Instance, Module, Store};

pub async fn verify(transaction: &Transaction) -> Result<bool, String> {
    for witness in &transaction.attestation {
        if let Some(script) = &witness.script {
            let wasm_bytes =
                wat2wasm(script.value.as_bytes()).map_err(|_| "Invalid WASM".to_string())?;
            let mut store = Store::default();
            let module = Module::new(&store, wasm_bytes).map_err(|e| e.to_string())?;
            let import_object = imports! {};
            let instance =
                Instance::new(&mut store, &module, &import_object).map_err(|e| e.to_string())?;
            let arg0 = witness
                .args
                .clone()
                .and_then(|v| v.value?.fields.get("0")?.kind.clone())
                .ok_or("No args")?;
            let arg0_i32 = match arg0 {
                prost_types::value::Kind::StringValue(v) => v
                    .parse::<i32>()
                    .map_err(|_| "Invalid arg type".to_string())?,
                _ => return Err("Invalid arg type".to_string()),
            };
            let f = instance
                .exports
                .get_function("verify")
                .map_err(|_| "WASM function not found 'verify'")?;
            let results = f
                .call(&mut store, &[wasmer::Value::I32(arg0_i32)])
                .map_err(|e| e.to_string())?;
            let result = results[0].i32().ok_or("Invalid script result type")?;
            if result < 1 {
                return Ok(false);
            }
        } else {
            return Err("No script found".to_string());
        }
    }
    Ok(true)
}
