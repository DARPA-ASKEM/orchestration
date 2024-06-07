use std::collections::HashMap;
use std::fs::File;
use std::io;
use std::io::BufRead;
use std::path::Path;

fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
    where
        P: AsRef<Path>,
{
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}

pub(crate) fn read_env_file() -> HashMap<String, String> {
    let mut env_vars = HashMap::new();
    if let Ok(lines) = read_lines(".env") {
        for line in lines.flatten() {
            let pos = line.find('=').unwrap();
            let k = line[..pos].to_string();
            let v = line[pos + 1..].to_string();
            env_vars.insert(k.clone(), v.clone());
        }
    } else {
        panic!(".env file missing");
    }
    env_vars
}

