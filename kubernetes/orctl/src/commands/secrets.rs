use std::collections::HashMap;
use std::io;
use std::io::Write;
use std::process::Command;
use base64::prelude::*;
use colored::Colorize;
use serde_yaml::Value;
use thiserror::Error;
use crate::commands::commands::Operation;
use crate::config::verbosity::Verbosity;
use crate::models::deployment_environment::Environment;
use crate::models::secret_files::{SecretFile, SecretFiles};

#[derive(Error, Debug)]
pub(crate) enum OperateOnSecretsError {
    #[error("Not Implemented")]
    NotImplemented(),

    #[error("Failed to decrypt (file {file:?})")]
    FailedToDecrypt {
        file: String,
    },
    #[error("Failed to convert from utf8 (file {file:?})")]
    FailedToConvertFileFromUtf8 {
        file: String,
    },
    #[error("Failed to convert file contents to yaml")]
    FailedToConvertFileToYaml(),

    #[error("Value missing")]
    ValueMissing(),
    #[error("Value failed to decode from base64)")]
    ValueFailedToDecodeBase64(),
    #[error("Value failed to decode from base64 (utf8 step)")]
    ValueFailedToDecodeBase64Utf8(),
    #[error("Key missing")]
    KeyMissing(),
}

pub(crate) fn operate_on_secrets(env: Environment, env_vars: HashMap<String, String>, debug_mode: Verbosity, operation: &Operation, file: &SecretFiles) -> Result<(), OperateOnSecretsError> {
    match operation {
        Operation::Decrypt => get_secrets(env, env_vars, debug_mode, file),
        Operation::Encrypt => put_secret(),
    }
}

fn put_secret() -> Result<(), OperateOnSecretsError> {
    Err(OperateOnSecretsError::NotImplemented())
}

fn get_secrets(env: Environment, env_vars: HashMap<String, String>, verbosity: Verbosity, file: &SecretFiles) -> Result<(), OperateOnSecretsError> {
    let file = SecretFile::create(file);
    if verbosity >= Verbosity::INFO {
        println!("Secrets op:decrypt, file:{}", file.dec_name);
    }
    let enc_file_name = format!("{0}/{1}", env.secrets, file.enc_name);

    let file_contents = decrypt_file(enc_file_name, env_vars, verbosity)?;

    let yaml_content = read_yaml(file_contents, verbosity)?;

    if verbosity >= Verbosity::TRACE {
        println!("Getting data object");
    }
    let data = yaml_content["data"].as_mapping();
    match data {
        Some(data) => {
            if verbosity >= Verbosity::TRACE {
                println!("Walking over data object");
            }
            for (key, value) in data.iter() {
                process_row(key, value);
            }
        }
        None => {
            if verbosity >= Verbosity::INFO{
                println!("nothing");
            }
        }
    }
    Ok(())
}

fn read_yaml(file_contents: String, verbosity: Verbosity) -> Result<Value, OperateOnSecretsError> {
    if verbosity >= Verbosity::TRACE {
        println!("Reading yaml");
    }
    let secret_contents: Result<serde_yaml::Value, serde_yaml::Error> =
        serde_yaml::from_str(&*file_contents);
    if secret_contents.is_err() {
        return Err(OperateOnSecretsError::FailedToConvertFileToYaml());
    }
    Ok(secret_contents.unwrap())
}

fn decrypt_file(enc_file_name: String, env_vars: HashMap<String, String>, verbosity: Verbosity) -> Result<String, OperateOnSecretsError> {
    if verbosity >= Verbosity::TRACE {
        println!("decrypting file: {}", enc_file_name.clone());
    }
    let output = Command::new("sops")
        .arg("--decrypt")
        .arg(enc_file_name.clone())
        .envs(&env_vars)
        .output()
        .expect("failed to execute");

    if output.status.success() {
        let file_contents = std::str::from_utf8(&output.stdout);
        if file_contents.is_err() {
            return Err(OperateOnSecretsError::FailedToConvertFileFromUtf8 { file: enc_file_name});
        }

        Ok(file_contents.unwrap().to_owned())
    } else {
        io::stderr().write_all(&output.stderr).unwrap();
        return Err(OperateOnSecretsError::FailedToDecrypt { file: enc_file_name});
    }
}

fn process_row(key: &Value, value: &Value) {
    match decode_row(key, value) {
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

fn decode_row(key: &Value, value: &Value) -> Result<(String, String), OperateOnSecretsError> {
    let val_base64 = value.as_str();
    if val_base64.is_none() { return Err(OperateOnSecretsError::ValueMissing()) }
    let val_base64 = val_base64.unwrap().to_string();

    let val_decoded_from_base_64 =
        BASE64_STANDARD.decode(val_base64);
    if val_decoded_from_base_64.is_err() { return Err(OperateOnSecretsError::ValueFailedToDecodeBase64()) }
    let val_decoded_from_base_64 = &val_decoded_from_base_64.unwrap();

    let val_decoded = std::str::from_utf8(val_decoded_from_base_64);
    if val_decoded.is_err() { return Err(OperateOnSecretsError::ValueFailedToDecodeBase64Utf8()) }
    let value = val_decoded.unwrap().to_string();

    let key = key.as_str();
    if key.is_none() { return Err(OperateOnSecretsError::KeyMissing()) }
    let key = key.unwrap().to_string();

    Ok((key, value))
}