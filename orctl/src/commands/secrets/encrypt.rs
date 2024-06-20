use std::fs::File;
use std::io;
use std::io::Write;
use std::process::Command;
use base64::Engine;
use base64::prelude::BASE64_STANDARD;
use serde_yaml::Value;
use crate::commands::secrets::{common, OperateOnSecretsError};
use crate::commands::secrets::common::{AGE_PUBLIC_KEY, get_env_value};
use crate::config::verbosity::Verbosity;
use crate::models::deployment_environment::Environment;
use crate::models::secret_files::{SecretFile, SecretFiles};

pub(crate) fn put_secret(env: Environment, verbosity: Verbosity, file_type: &SecretFiles, key_to_find: &String, new_value: &String) -> Result<(), OperateOnSecretsError> {
    let file = SecretFile::by_type(file_type);
    if verbosity >= Verbosity::INFO {
        println!("Secrets op:encrypt, file:{}, key:{}, value:{}", file.dec_name, key_to_find, new_value);
    }
    let yaml_content = common::get_yaml_contents_from_file(env.secrets_path, file.clone(), verbosity)?;

    if verbosity >= Verbosity::TRACE {
        println!("Replacing value");
    }
    let yaml_content = replace_key_value(yaml_content, key_to_find, new_value)?;

    let dec_file_name = format!("{0}{1}{2}", env.secrets_path, file.folder, file.dec_name);
    let buffer = File::create(dec_file_name.clone());
    match buffer {
        Ok(buffer) => {

            if verbosity >= Verbosity::TRACE {
                println!("Generating new yaml content");
            }
             let res = serde_yaml::to_writer(buffer, &yaml_content);
            match res {
                Ok(_) => {
                    if verbosity >= Verbosity::TRACE {
                        println!("Encrypting yaml content");
                    }
                    let enc_file_name = format!("{0}{1}{2}", env.secrets_path, file.folder, file.enc_name);
                    let encrypted_contents = encrypt_file(dec_file_name, verbosity)?;

                    let buffer = File::create(enc_file_name.clone());
                    match buffer {
                        Ok(mut buffer) => {
                            if verbosity >= Verbosity::TRACE {
                                println!("Writing encrypted yaml to file: {}", enc_file_name);
                            }
                            let res = buffer.write_all(encrypted_contents.as_ref());
                            match res {
                                Ok(_) => {
                                    if verbosity >= Verbosity::TRACE {
                                        println!("Success");
                                    }
                                },
                                Err(error) => {
                                    return Err(OperateOnSecretsError::FileError { error: error });
                                }
                            }
                        },
                        Err(error) => {
                            return Err(OperateOnSecretsError::FileError { error: error });
                        }
                    }
                },
                Err(error) => {
                    return Err(OperateOnSecretsError::WriteYaml { error: error });
                }
            }
        },
        Err(error) => {
            return Err(OperateOnSecretsError::FileError{ error: error });
        }
    }

    Ok(())
}

fn encrypt_file(dec_file_name: String, verbosity: Verbosity) -> Result<String, OperateOnSecretsError> {
    let age_public_key_arg = format!("--age={}", get_env_value(AGE_PUBLIC_KEY));

    if verbosity >= Verbosity::TRACE {
        println!("encrypting file: {}", dec_file_name.clone());
    }
    let output = Command::new("sops")
        .arg("--encrypt")
        .arg(age_public_key_arg)
        .arg("--encrypted-regex")
        .arg("^(data|stringData)$")
        .arg(dec_file_name.clone())
        .envs(&common::age_env_vars())
        .output()
        .expect("failed to execute");

    if output.status.success() {
        let file_contents = std::str::from_utf8(&output.stdout);
        if file_contents.is_err() {
            return Err(OperateOnSecretsError::FailedToConvertFileFromUtf8 { file: dec_file_name});
        }

        Ok(file_contents.unwrap().to_owned())
    } else {
        io::stderr().write_all(&output.stderr).unwrap();
        return Err(OperateOnSecretsError::FailedToEncrypt { file: dec_file_name});
    }
}

fn replace_key_value(mut yaml_content: Value, key_to_find: &String, new_value: &String) -> Result<Value, OperateOnSecretsError> {
    let new_value_base64 = BASE64_STANDARD.encode(new_value);

    *yaml_content
        .get_mut("data")
        .ok_or(Err::<&mut Value, OperateOnSecretsError>(
            OperateOnSecretsError::MissingDataSection()
        )).unwrap()
        .get_mut(key_to_find)
        .ok_or(Err::<&mut Value, OperateOnSecretsError>(
            OperateOnSecretsError::MissingKeySection{ key: key_to_find.clone() })
        ).unwrap() = new_value_base64.as_str().into();
    Ok(yaml_content)
}
