use clap::ValueEnum;

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
pub(crate) enum Verbosity {
    NONE,
    INFO,
    TRACE,
}

pub(crate) fn get_verbosity(debug: u8) -> Verbosity {
    match debug {
        0 => Verbosity::NONE,
        1 => Verbosity::INFO,
        2 => Verbosity::TRACE,
        _ => {
            println!("Don't be crazy");
            Verbosity::TRACE
        }
    }
}
