// Full XSWD implementation with network_handler feature:
// - Native: Local XSWD server + relay connections
// - WASM: Relay connections only (server disabled via cfg gates)
#[cfg(feature = "network_handler")]
#[path = "impl.rs"]
pub(crate) mod imp;

// Stub implementation when network_handler is disabled:
// - No XSWD functionality at all (returns no-ops)
#[cfg(not(feature = "network_handler"))]
#[path = "stub.rs"]
pub(crate) mod imp;

pub use imp::*;
