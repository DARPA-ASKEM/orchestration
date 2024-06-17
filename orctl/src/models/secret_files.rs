use clap::ValueEnum;

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
pub(crate) enum SecretFiles {
    /// DKG
    Dkg,
    /// BEAKER
    Beaker,
    /// ES
    Es,
    /// ADOBE
    Adobe,
    /// S3
    S3,
    /// RDS
    Rds,
    /// LOGGING
    Logging,
    /// MQ
    Mq,
    /// CHATGPT
    Chatgpt,
    /// SPICEDB
    Spicedb,
    /// XDD
    Xdd,
    /// KEYCLOAK
    Keycloak,
    /// NEO4J
    Neo4j,
}

pub(crate) struct SecretFile<'a> {
    pub(crate) enc_name: &'a str,
    pub(crate) dec_name: &'a str,
}

impl<'a> SecretFile<'a> {
    pub(crate) fn by_type(file: &SecretFiles) -> SecretFile {
        match file {
            SecretFiles::Dkg => DKG,
            SecretFiles::Beaker => BEAKER,
            SecretFiles::Es => ES,
            SecretFiles::Adobe => ADOBE,
            SecretFiles::S3 => S3,
            SecretFiles::Rds => RDS,
            SecretFiles::Logging => LOGGING,
            SecretFiles::Mq => MQ,
            SecretFiles::Chatgpt => CHATGPT,
            SecretFiles::Spicedb => SPICEDB,
            SecretFiles::Xdd => XDD,
            SecretFiles::Keycloak => KEYCLOAK,
            SecretFiles::Neo4j => NEO4J,
        }
    }
}

pub(crate) const DKG: SecretFile<'static> = SecretFile {
    enc_name: "secrets-dkg.enc.yaml",
    dec_name: "secrets-dkg.yaml",
};
pub(crate) const BEAKER: SecretFile<'static> = SecretFile {
    enc_name: "secrets-beaker-creds.enc.yaml",
    dec_name: "secrets-beaker-creds.yaml",
};
pub(crate) const ES: SecretFile<'static> = SecretFile {
    enc_name: "secrets-es-creds.enc.yaml",
    dec_name: "secrets-es-creds.yaml",
};
pub(crate) const ADOBE: SecretFile<'static> = SecretFile {
    enc_name: "secrets-adobe-api-key.enc.yaml",
    dec_name: "secrets-adobe-api-key.yaml",
};
pub(crate) const S3: SecretFile<'static> = SecretFile {
    enc_name: "secrets-data-service-s3.enc.yaml",
    dec_name: "secrets-data-service-s3.yaml",
};
pub(crate) const RDS: SecretFile<'static> = SecretFile {
    enc_name: "secrets-rds-creds.enc.yaml",
    dec_name: "secrets-rds-creds.yaml",
};
pub(crate) const LOGGING: SecretFile<'static> = SecretFile {
    enc_name: "secrets-logging-creds.enc.yaml",
    dec_name: "secrets-logging-creds.yaml",
};
pub(crate) const MQ: SecretFile<'static> = SecretFile {
    enc_name: "secrets-mq-creds.enc.yaml",
    dec_name: "secrets-mq-creds.yaml",
};
pub(crate) const CHATGPT: SecretFile<'static> = SecretFile {
    enc_name: "secrets-chatgpt.enc.yaml",
    dec_name: "secrets-chatgpt.yaml",
};
pub(crate) const SPICEDB: SecretFile<'static> = SecretFile {
    enc_name: "secrets-spicedb-shared.enc.yaml",
    dec_name: "secrets-spicedb-shared.yaml",
};
pub(crate) const XDD: SecretFile<'static> = SecretFile {
    enc_name: "secrets-xdd-api-key.enc.yaml",
    dec_name: "secrets-xdd-api-key.yaml",
};
pub(crate) const KEYCLOAK: SecretFile<'static> = SecretFile {
    enc_name: "secrets-keycloak-creds.enc.yaml",
    dec_name: "secrets-keycloak-creds.yaml",
};
pub(crate) const NEO4J: SecretFile<'static> = SecretFile {
    enc_name: "secrets-neo4j-auth.enc.yaml",
    dec_name: "secrets-neo4j-auth.yaml",
};
