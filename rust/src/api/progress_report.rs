use lazy_static::lazy_static;

use crate::frb_generated::StreamSink;

lazy_static! {
    pub static ref PROGRESS_REPORT_STREAM_SINK: parking_lot::RwLock<Option<StreamSink<ProgressReport>>> =
        parking_lot::RwLock::new(None);
}

pub struct ProgressReport {
    pub progress: f64,
    pub step: String,
    pub message: Option<String>,
}

pub fn add_progress_report(report: ProgressReport) {
    if let Some(sink) = &*PROGRESS_REPORT_STREAM_SINK.read() {
        sink.add(report)
            .expect("Error while adding Report to the stream");
    }
}
