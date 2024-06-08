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
        /// What operation to perform
        #[arg(value_enum)]
        operation: Operation,

        /// What secret file to operate on
        #[arg(value_enum)]
        file: SecretFiles,
    },
}

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
pub(crate) enum Operation {
    /// Decrypt
    Decrypt,
    /// Encrypt
    Encrypt,
}
