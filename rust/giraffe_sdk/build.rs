use std::env::current_dir;
use std::io::Result;
use std::path::Path;
use std::{fs, io};

fn main() -> Result<()> {
    println!("{}", current_dir()?.to_str().unwrap());
    let _ = copy_dir_all("../../proto", "src/proto/internal");
    let _ = copy_dir_all("../../external_proto", "src/proto/external");
    prost_build::compile_protos(
        &["src/proto/internal/models/core.proto"],
        &["src/proto/internal", "src/proto/external"],
    )?;
    fs::remove_dir_all("src/proto")?;
    Ok(())
}

fn copy_dir_all(src: impl AsRef<Path>, dst: impl AsRef<Path>) -> io::Result<()> {
    fs::create_dir_all(&dst)?;
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let ty = entry.file_type()?;
        if ty.is_dir() {
            copy_dir_all(entry.path(), dst.as_ref().join(entry.file_name()))?;
        } else {
            fs::copy(entry.path(), dst.as_ref().join(entry.file_name()))?;
        }
    }
    Ok(())
}
