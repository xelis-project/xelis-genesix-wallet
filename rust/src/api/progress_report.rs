use lazy_static::lazy_static;

use crate::frb_generated::StreamSink;

lazy_static! {
    pub static ref PROGRESS_REPORT_STREAM_SINK: parking_lot::RwLock<Option<StreamSink<Report>>> =
        parking_lot::RwLock::new(None);
}

pub enum Report {
    TableGeneration {
        progress: f64,
        step: String,
        message: Option<String>,
    },
    Misc {
        message: Option<String>,
    },
}

pub fn add_progress_report(report: Report) {
    if let Some(sink) = &*PROGRESS_REPORT_STREAM_SINK.read() {
        sink.add(report)
            .expect("Error while adding Report to the stream");
    }
}
