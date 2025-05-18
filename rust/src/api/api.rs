use crate::api::logger;
use crate::api::logger::LogEntry;
use crate::api::progress_report::{ProgressReport, PROGRESS_REPORT_STREAM_SINK};
use crate::frb_generated::StreamSink;

pub fn set_up_rust_logger() {
    logger::init_logger();
    // flutter_rust_bridge::setup_default_user_utils();
}

pub fn create_log_stream(s: StreamSink<LogEntry>) -> anyhow::Result<()> {
    logger::SendToDartLogger::set_stream_sink(s);
    Ok(())
}

pub fn create_progress_report_stream(
    stream_sink: StreamSink<ProgressReport>,
) -> anyhow::Result<()> {
    let mut guard = PROGRESS_REPORT_STREAM_SINK.write();
    *guard = Some(stream_sink);
    drop(guard);
    Ok(())
}
