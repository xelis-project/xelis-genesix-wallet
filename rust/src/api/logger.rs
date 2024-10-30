use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use log::{error, warn, Log, Metadata, Record};
pub use log::{Level, LevelFilter};
use simplelog::{CombinedLogger, Config, SharedLogger};
use std::sync::Once;

use crate::frb_generated::StreamSink;

// use super::time;

lazy_static! {
    pub static ref SEND_TO_DART_LOGGER_STREAM_SINK: parking_lot::RwLock<Option<StreamSink<LogEntry>>> =
        parking_lot::RwLock::new(None);
}

static INIT_LOGGER_ONCE: Once = Once::new();

pub fn init_logger() {
    INIT_LOGGER_ONCE.call_once(|| {
        CombinedLogger::init(vec![
            Box::new(SendToDartLogger {
                level: LevelFilter::Debug,
            }),
            // Box::new(SendToDartLogger { level: LevelFilter::Info }),
            // Box::new(SendToDartLogger { level: LevelFilter::Trace }),
        ])
        .unwrap_or_else(|e| {
            error!("init_logger (inside 'once') has error: {:?}", e);
        });
    });
}

pub struct LogEntry {
    pub level: Level,
    pub tag: String,
    pub msg: String,
}

#[frb(mirror(Level))]
pub enum _Level {
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

pub struct SendToDartLogger {
    pub level: LevelFilter,
}

impl SendToDartLogger {
    pub fn set_stream_sink(stream_sink: StreamSink<LogEntry>) {
        let mut guard = SEND_TO_DART_LOGGER_STREAM_SINK.write();
        let overriding = guard.is_some();

        *guard = Some(stream_sink);

        drop(guard);

        if overriding {
            warn!(
                "SendToDartLogger::set_stream_sink but already exist a sink, thus overriding. \
                (This may or may not be a problem. It will happen normally if hot-reload Flutter app.)"
            );
        }
    }

    fn record_to_entry(record: &Record) -> LogEntry {
        let level = record.level();
        let tag = record.file().unwrap_or_else(|| record.target()).to_owned();
        let msg = format!("{}", record.args());

        LogEntry { level, tag, msg }
    }
}

impl Log for SendToDartLogger {
    fn enabled(&self, _metadata: &Metadata) -> bool {
        true
    }

    fn log(&self, record: &Record) {
        let entry = Self::record_to_entry(record);
        if let Some(sink) = &*SEND_TO_DART_LOGGER_STREAM_SINK.read() {
            sink.add(entry).unwrap();
        }
    }

    fn flush(&self) {
        // no need
    }
}

impl SharedLogger for SendToDartLogger {
    fn level(&self) -> LevelFilter {
        self.level
    }

    fn config(&self) -> Option<&Config> {
        None
    }

    fn as_log(self: Box<SendToDartLogger>) -> Box<dyn Log> {
        Box::new(*self)
    }
}
