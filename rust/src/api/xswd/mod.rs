#[cfg(not(target_arch = "wasm32"))]
#[path = "native.rs"]
pub(crate) mod imp;

#[cfg(target_arch = "wasm32")]
#[path = "stub.rs"]
pub(crate) mod imp;

pub use imp::*;
