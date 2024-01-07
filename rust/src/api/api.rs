use crate::api::logger;
use crate::api::logger::LogEntry;
use crate::frb_generated::StreamSink;

pub fn create_log_stream(s: StreamSink<LogEntry>) -> anyhow::Result<()> {
    logger::SendToDartLogger::set_stream_sink(s);
    Ok(())
}

pub fn set_up_rust_logger() {
    // flutter_rust_bridge::setup_default_user_utils();
    logger::init_logger();
}
