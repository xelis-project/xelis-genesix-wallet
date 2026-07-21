// Full XSWD relayer implementation with network_handler and xswd:
// - Native + api_server: local XSWD server and relay connections
// - Native without api_server, and WASM: relay connections only
#[cfg(all(feature = "network_handler", feature = "xswd"))]
#[path = "impl.rs"]
pub(crate) mod imp;

// Stub implementation when either required feature is disabled:
// - No XSWD functionality at all (returns no-ops)
#[cfg(not(all(feature = "network_handler", feature = "xswd")))]
#[path = "stub.rs"]
pub(crate) mod imp;

// Compile and exercise the fallback contract in normal test builds even though
// the rest of the crate currently requires `network_handler` to compile.
#[cfg(all(test, feature = "network_handler", feature = "xswd"))]
#[allow(dead_code)]
#[path = "stub.rs"]
mod stub_under_test;

pub use imp::*;
