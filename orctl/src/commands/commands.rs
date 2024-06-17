use clap::{Subcommand, ValueEnum};
use crate::models::secret_files::SecretFiles;

#[derive(Subcommand)]
pub(crate) enum Commands {
    /// get the status of a deployment
    Status {
        #[arg(short, long)]
        pod: bool,
        #[arg(short, long)]
        svc: bool,
    },
    /// get secret values for a deployment
    Secrets {
        #[command(subcommand)]
        command: SecretCommand,
    },
}

#[derive(Subcommand)]
pub(crate) enum SecretCommand {
    /// Decrypt
    Decrypt {
        /// What secret file to operate on
        #[arg(value_enum)]
        file: SecretFiles,
    },
    /// Encrypt
    Encrypt {
        /// What secret file to operate on
        #[arg(value_enum)]
        file: SecretFiles,

        /// What key to operate on
        key: String,

        /// If decrypt what value to encode
        value: String,
    },
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
pub(crate) enum Operation {
    /// Decrypt
    Decrypt,
    /// Encrypt
    Encrypt,
}
