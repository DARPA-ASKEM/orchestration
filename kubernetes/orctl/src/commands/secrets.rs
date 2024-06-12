use std::collections::HashMap;
use std::io;
use thiserror::Error;
use crate::commands::commands::SecretCommand;
use crate::config::verbosity::Verbosity;
use crate::models::deployment_environment::Environment;

mod common;
mod decrypt;
mod encrypt;

#[derive(Error, Debug)]
pub(crate) enum OperateOnSecretsError {
    #[error("Failed to decrypt (file {file:?})")]
    FailedToDecrypt { file: String, },
    #[error("Failed to convert from utf8 (file {file:?})")]
    FailedToConvertFileFromUtf8 { file: String, },
    #[error("Failed to convert file contents to yaml")]
    FailedToConvertFileToYaml(),

    #[error("YAML file missing 'data' section")]
    MissingDataSection(),
    #[error("YAML file missing specified key: {key:?}")]
    MissingKeySection { key: String },

    #[error("File error: {error:?}")]
    FileError{ error: io::Error },
    #[error("Writing Yaml error: {error:?}")]
    WriteYaml{ error: serde_yaml::Error },

    #[error("Value missing")]
    ValueMissing(),
    #[error("Value failed to decode from base64)")]
    ValueFailedToDecodeBase64(),
    #[error("Value failed to decode from base64 (utf8 step)")]
    ValueFailedToDecodeBase64Utf8(),
    #[error("Key missing")]
    KeyMissing(),
}

pub(crate) fn operate_on_secrets(commands: &SecretCommand, env: Environment, env_vars: HashMap<String, String>, verbosity: Verbosity) -> Result<(), OperateOnSecretsError> {
    match commands {
        SecretCommand::Decrypt { file } => {
            decrypt::get_secrets(env, env_vars, verbosity, file)
        }
        SecretCommand::Encrypt { file, key, value } => {
            encrypt::put_secret(env, env_vars, verbosity, file, key, value)
        }
    }
}
