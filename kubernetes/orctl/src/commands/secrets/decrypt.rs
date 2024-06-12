use std::collections::HashMap;
use serde_yaml::Value;
use colored::Colorize;
use crate::commands::secrets::{common, OperateOnSecretsError};
use crate::config::verbosity::Verbosity;
use crate::models::deployment_environment::Environment;
use crate::models::secret_files::{SecretFile, SecretFiles};

pub fn get_secrets(env: Environment, env_vars: HashMap<String, String>, verbosity: Verbosity, file_type: &SecretFiles) -> Result<(), OperateOnSecretsError> {
    let file = SecretFile::by_type(file_type);
    if verbosity >= Verbosity::INFO {
        println!("Secrets op:decrypt, file:{}", file.dec_name);
    }
    let yaml_content = common::get_yaml_contents_from_file(env.secrets_path, file.enc_name, env_vars, verbosity)?;

    if verbosity >= Verbosity::TRACE {
        println!("Getting data object");
    }
    match yaml_content["data"].as_mapping() {
        Some(data) => {
            for (key, value) in data.iter() {
                print_row(key, value);
            }
        }
        None => {
            return Err(OperateOnSecretsError::MissingDataSection());
        }
    }
    Ok(())
}

fn print_row(key: &Value, value: &Value) {
    match common::decode_row(key, value) {
        Ok((key,value)) => {
            println!(
                "{}: {}",
                key.yellow(),
                value.purple(),
            );
        },
        Err(error) => {
            // catch and continue - attempt to process as much as possible
            println!("Error: {}", error);
        }
    }
}
