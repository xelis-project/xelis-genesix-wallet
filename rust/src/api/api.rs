use std::sync::Mutex;

use tokio::runtime::Runtime;

use crate::api::logger;
use crate::api::logger::LogEntry;
use crate::frb_generated::StreamSink;

pub static TOKIO_RUNTIME: Mutex<Option<Runtime>> = Mutex::new(None);

pub async fn start_tokio_runtime_for_rust() -> anyhow::Result<()> {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .thread_name("native wallet")
        .build()?;

    *TOKIO_RUNTIME.lock().expect("Set tokio runtime") = Some(rt);
    Ok(())
}

pub fn create_log_stream(s: StreamSink<LogEntry>) -> anyhow::Result<()> {
    logger::SendToDartLogger::set_stream_sink(s);
    Ok(())
}

pub fn set_up_rust_logger() {
    logger::init_logger();
}
