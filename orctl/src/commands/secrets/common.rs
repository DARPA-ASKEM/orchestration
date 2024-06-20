use std::collections::HashMap;
use std::env::VarError;
use std::process::Command;
use std::{env, io};
use std::io::Write;
use std::string::ToString;
use serde_yaml::Value;
use base64::engine::general_purpose::STANDARD as BASE64_STANDARD;
use base64::Engine;
use crate::commands::secrets::OperateOnSecretsError;
use crate::config::verbosity::Verbosity;
use crate::models::secret_files::SecretFile;

pub(crate) const AGE_PUBLIC_KEY: &str = "AGE_PUBLIC_KEY";
const SOPS_AGE_KEY_FILE: &str = "SOPS_AGE_KEY_FILE";

pub(crate) fn age_env_vars() -> HashMap<String, String> {
    let mut env_vars: HashMap<String, String> = HashMap::new();
    env_vars.insert(AGE_PUBLIC_KEY.to_string(), get_env_value(AGE_PUBLIC_KEY));
    env_vars.insert(SOPS_AGE_KEY_FILE.to_string(), get_env_value(SOPS_AGE_KEY_FILE));
    env_vars
}

pub(crate) fn get_env_value(key: &str) -> String {
    match env::var(key) {
        Ok(value) => value,
        Err(VarError::NotPresent) | Err(VarError::NotUnicode(_)) => {
            panic!("Environment Variable {} is missing", key);
        },
    }
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

pub(crate) fn decode_row(key: &Value, value: &Value) -> Result<(String, String), OperateOnSecretsError> {
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

pub(crate) fn get_yaml_contents_from_file(path: &str, file: SecretFile, verbosity: Verbosity) -> Result<Value, OperateOnSecretsError> {
    let enc_file_name = format!("{0}{1}{2}", path, file.folder,  file.enc_name);
    let file_contents = decrypt_file(enc_file_name, age_env_vars(), verbosity)?;
    read_yaml(file_contents, verbosity)
}