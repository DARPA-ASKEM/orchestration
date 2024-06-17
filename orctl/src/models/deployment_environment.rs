use clap::ValueEnum;

pub(crate) struct Environment<'a> {
    pub ssh_cmd: &'a str,
    pub secrets_path: &'a str,
}

const PRODUCTION: Environment<'static> = crate::Environment {
    ssh_cmd: "uncharted-askem-prod-askem-prod-kube-manager-3",
    secrets_path: "overlays/prod/overlays/askem-production/secrets",
};
const STAGING: Environment<'static> = crate::Environment {
    ssh_cmd: "uncharted-askem-prod-askem-staging-kube-manager-3",
    secrets_path: "overlays/prod/overlays/askem-staging/secrets",
};
const DEV: Environment<'static> = crate::Environment {
    ssh_cmd: "askem-dev-kube-manager-3",
    secrets_path: "overlays/prod/overlays/askem-dev/secrets",
};

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
pub(crate) enum DeploymentEnvironments {
    /// Production
    Production,
    /// Staging
    Staging,
    /// Dev
    Dev,
}

pub(crate) fn get_deployment_environment(env: DeploymentEnvironments) -> Environment<'static> {
    match env {
        DeploymentEnvironments::Production => PRODUCTION,
        DeploymentEnvironments::Staging => STAGING,
        DeploymentEnvironments::Dev => DEV,
    }
}
