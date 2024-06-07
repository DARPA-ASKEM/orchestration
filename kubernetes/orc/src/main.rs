use std::error::Error;
use clap::Parser;

use crate::commands::commands::Commands;
use crate::commands::status::get_status;
use crate::commands::secrets::get_secrets;
use crate::config::env_file::read_env_file;
use crate::config::debug_mode::get_debug_mode;
use crate::models::deployment_environment::get_deployment_environment;
use crate::models::deployment_environment::{Environment, DeploymentEnvironments};

mod models;
mod commands;
mod config;

#[derive(Parser)]
#[command(version, name = "kube stuff", about = "Various useful tasks.")]
struct Cli {
    /// Turn debugging information on
    #[arg(short, long, action = clap::ArgAction::Count)]
    debug: u8,

    /// What environment to run against
    #[arg(value_enum)]
    env: DeploymentEnvironments,

    #[command(subcommand)]
    command: Option<Commands>,
}

fn main() -> Result<(), Box<dyn Error>> {
    let cli = Cli::parse();

    let debug_mode = get_debug_mode(cli.debug);
    let env = get_deployment_environment(cli.env);
    let env_vars = read_env_file();

    match &cli.command {
        Some(Commands::Status { pod, svc }) => {
            get_status(env, debug_mode, pod, svc)?
        },
        Some(Commands::Secrets { operation, file }) => {
            get_secrets(env, env_vars, debug_mode, operation, file)?
        },
        None => {
            panic!("Missing Command.");
        }
    };
    Ok(())
}

