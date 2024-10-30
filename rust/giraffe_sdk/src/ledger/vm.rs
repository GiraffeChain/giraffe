use crate::models::Transaction;
use wasmer::{imports, wat2wasm, Instance, Module, Store};

pub async fn verify(transaction: &Transaction) -> Result<(), String> {
    for witness in &transaction.attestation {
        if let Some(script) = &witness.script {
            let wasm_bytes =
                wat2wasm(script.value.as_bytes()).map_err(|_| "Invalid WASM".to_string())?;
            let mut store = Store::default();
            let module = Module::new(&store, wasm_bytes).map_err(|e| e.to_string())?;
            let import_object = imports! {};
            let instance =
                Instance::new(&mut store, &module, &import_object).map_err(|e| e.to_string())?;
            let f = instance
                .exports
                .get_function("verify")
                .map_err(|_| "WASM function not found 'verify'")?;
            let results = f.call(&mut store, &[]).map_err(|e| e.to_string())?;
            let result = results[0].i32().ok_or("Invalid script result type")?;
            if result < 1 {
                return Err("Unsatisfied script".to_string());
            }
        } else {
            return Err("No script found".to_string());
        }
    }
    Ok(())
}
