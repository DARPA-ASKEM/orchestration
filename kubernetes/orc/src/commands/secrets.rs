use std::collections::HashMap;
use std::io;
use std::io::Write;
use std::process::Command;
use std::str::Utf8Error;
use base64::prelude::*;
use colored::Colorize;
use serde_yaml::Value;
use thiserror::Error;
use crate::commands::commands::Operation;
use crate::commands::secrets::KeyValueError::{KeyMissing, ValueFailedToDecodeBase64, ValueFailedToDecodeBase64Utf8, ValueMissing};
use crate::config::debug_mode::Debug;
use crate::models::deployment_environment::Environment;
use crate::models::secret_files::{SecretFile, SecretFiles};

pub(crate) fn get_secrets(env: Environment, env_vars: HashMap<String, String>, debug_mode: Debug, operation: &Operation, file: &SecretFiles) -> Result<(), Utf8Error> {
    let op = match operation {
        Operation::Decrypt => "decrypt",
        Operation::Encrypt => "encrypt",
    };
    let file = SecretFile::create(file);

    if debug_mode >= Debug::INFO {
        println!("Secrets op:{}, file:{}", op, file.dec_name);
    }

    let enc_file_name = format!("{0}/{1}", env.secrets, file.enc_name);

    if debug_mode >= Debug::TRACE {
        println!("decrypting file: {}", enc_file_name.clone());
    }
    let output = Command::new("sops")
        .arg("--decrypt")
        .arg(enc_file_name.clone())
        .envs(&env_vars)
        .output()
        .expect("failed to execute");

    if output.status.success() {
        let output = std::str::from_utf8(&output.stdout)?;
        if debug_mode >= Debug::TRACE {
            println!("Reading yaml");
        }
        let secret_contents: Result<serde_yaml::Value, serde_yaml::Error> =
            serde_yaml::from_str(output);
        match secret_contents {
            Ok(secret_contents) => {
                if debug_mode >= Debug::TRACE {
                    println!("Getting data object");
                }
                let data = secret_contents["data"].as_mapping();
                match data {
                    Some(data) => {
                        if debug_mode >= Debug::TRACE {
                            println!("Walking over data object");
                        }
                        for (key, value) in data.iter() {
                            process_row(key, value);
                        }
                    }
                    None => {
                        if debug_mode >= Debug::INFO{
                            println!("nothing");
                        }
                    }
                }
            }
            Err(error) => {
                println!("Error: {}", error);
            }
        }
    } else {
        io::stderr().write_all(&output.stderr).unwrap();
        panic!("Error {} {}", "failed to decrypt".red(), enc_file_name);
    }
    Ok(())
}

#[derive(Error, Debug)]
enum KeyValueError {
    #[error("Value missing")]
    ValueMissing(),
    #[error("Value failed to decode from base64)")]
    ValueFailedToDecodeBase64(),
    #[error("Value failed to decode from base64 (utf8 step)")]
    ValueFailedToDecodeBase64Utf8(),
    #[error("Key missing")]
    KeyMissing(),
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
            println!("Error: {}", error);
        }
    }
}

fn decode_row(key: &Value, value: &Value) -> Result<(String, String), KeyValueError> {
    let val_base64 = value.as_str();
    if val_base64.is_none() { return Err(ValueMissing()) }
    let val_base64 = val_base64.unwrap().to_string();

    let val_decoded_from_base_64 =
        BASE64_STANDARD.decode(val_base64);
    if val_decoded_from_base_64.is_err() { return Err(ValueFailedToDecodeBase64()) }
    let val_decoded_from_base_64 = &val_decoded_from_base_64.unwrap();

    let val_decoded = std::str::from_utf8(val_decoded_from_base_64);
    if val_decoded.is_err() { return Err(ValueFailedToDecodeBase64Utf8()) }
    let value = val_decoded.unwrap().to_string();

    let key = key.as_str();
    if key.is_none() { return Err(KeyMissing()) }
    let key = key.unwrap().to_string();

    Ok((key, value))
}