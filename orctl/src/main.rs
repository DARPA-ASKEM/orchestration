use std::error::Error;
use clap::Parser;

use crate::commands::commands::Commands;
use crate::commands::status::get_status;
use crate::commands::secrets::operate_on_secrets;
use crate::config::env_file::read_env_file;
use crate::config::verbosity::get_verbosity;
use crate::models::deployment_environment::get_deployment_environment;
use crate::models::deployment_environment::{Environment, DeploymentEnvironments};

mod models;
mod commands;
mod config;

#[derive(Parser)]
#[command(version, name = "Orchestration Control", about = "Various useful tasks.")]
struct Cli {
    /// Turn debugging information on
    #[arg(short, long, action = clap::ArgAction::Count)]
    verbose: u8,

    /// What environment to run against
    #[arg(value_enum)]
    env: DeploymentEnvironments,

    #[command(subcommand)]
    command: Option<Commands>,
}

fn main() -> Result<(), Box<dyn Error>> {
    let cli = Cli::parse();

    let verbosity = get_verbosity(cli.verbose);
    let env = get_deployment_environment(cli.env);
    let env_vars = read_env_file();

    match &cli.command {
        Some(Commands::Status { pod, svc }) => {
            get_status(env, verbosity, pod, svc)?
        },
        Some(Commands::Secrets { command }) => {
            operate_on_secrets(command, env, env_vars, verbosity)?
        },
        // Some(Commands::Secrets { operation, file, key, value }) => {
        //     operate_on_secrets(env, env_vars, verbosity, operation, file, key, value)?
        // },
        None => {
            panic!("Missing Command.");
        }
    };
    Ok(())
}

