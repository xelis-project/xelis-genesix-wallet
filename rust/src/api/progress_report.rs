use crate::frb_generated::StreamSink;
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;

lazy_static! {
    pub static ref PROGRESS_REPORT_STREAM_SINK: parking_lot::RwLock<Option<StreamSink<Report>>> =
        parking_lot::RwLock::new(None);
}

#[frb(sync)]
pub fn create_progress_report_stream(stream_sink: StreamSink<Report>) -> anyhow::Result<()> {
    let mut guard = PROGRESS_REPORT_STREAM_SINK.write();
    *guard = Some(stream_sink);
    drop(guard);
    Ok(())
}

pub fn add_progress_report(report: Report) {
    if let Some(sink) = &*PROGRESS_REPORT_STREAM_SINK.read() {
        sink.add(report)
            .expect("Error while adding Report to the stream");
    }
}

pub enum Report {
    TableGeneration {
        progress: f64,
        step: String,
        message: Option<String>,
    },
    Misc {
        message: String,
    },
}
