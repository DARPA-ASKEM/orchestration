use std::process::Command;
use std::str::Utf8Error;
use crate::config::debug_mode::Debug;
use crate::models::deployment_environment::Environment;

pub(crate) fn get_status(env: Environment, debug_mode: Debug, pod: &bool, svc: &bool) -> Result<(), Utf8Error> {
    if *pod {
        println!("Status pod only");
    } else {
        let ssh_cmd_arg = format!("sudo kubectl get pod -o wide");
        if debug_mode >= Debug::INFO {
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
    }

    if *svc {
        println!("SVC supplied");
    }
    return Ok(());
}