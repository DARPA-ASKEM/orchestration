use clap::ValueEnum;

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
pub(crate) enum Debug {
    NONE,
    INFO,
    TRACE,
}

pub(crate) fn get_debug_mode(debug: u8) -> Debug {
    match debug {
        0 => Debug::NONE,
        1 => Debug::INFO,
        2 => Debug::TRACE,
        _ => {
            println!("Don't be crazy");
            Debug::TRACE
        }
    }
}
