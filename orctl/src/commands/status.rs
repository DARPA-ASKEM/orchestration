use std::process::Command;
use std::str::Utf8Error;
use crate::config::verbosity::Verbosity;
use crate::models::deployment_environment::Environment;

pub(crate) fn get_status(env: Environment, verbosity: Verbosity, pod: &bool, svc: &bool) -> Result<(), Utf8Error> {
    if verbosity >= Verbosity::INFO {
        print!("Status of :");
    }

    let mut status_of = "".to_owned();
    if *pod {
        if verbosity >= Verbosity::INFO {
            print!(" pod");
        }
        status_of = "pod".to_owned();
    }

    if *svc {
        if verbosity >= Verbosity::INFO {
            print!(" svc");
        }
        if status_of.len() > 0 {
            status_of = status_of.to_owned() + ",svc";
        } else {
            status_of = "svc".to_owned();
        }
    }
    if verbosity >= Verbosity::INFO {
        println!("");
    }

    let ssh_cmd_arg = format!("sudo kubectl -n terarium get {} -o wide", status_of);
    if verbosity >= Verbosity::INFO {
        println!("Status to be fetched {}", ssh_cmd_arg);
    }
    let output = Command::new("ssh")
        .arg(env.ssh_cmd)
        .arg(ssh_cmd_arg)
        .output()
        .expect("failed to execute");
    if output.status.success() {
        let output = std::str::from_utf8(&output.stdout)?;
        println!("{}", output.to_string());
    } else {
        panic!("Error: {}", std::str::from_utf8(&output.stderr)?);
    }
    return Ok(());
}