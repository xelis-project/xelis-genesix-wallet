use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_create_key_pair(port_: i64) {
    wire_create_key_pair_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_get_address(port_: i64, key_pair: wire_KeyPair) {
    wire_get_address_impl(port_, key_pair)
}

#[no_mangle]
pub extern "C" fn wire_rust_release_mode(port_: i64) {
    wire_rust_release_mode_impl(port_)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_KeyPair() -> wire_KeyPair {
    wire_KeyPair::new_with_null_ptr()
}

// Section: related functions

#[no_mangle]
pub extern "C" fn drop_opaque_KeyPair(ptr: *const c_void) {
    unsafe {
        Arc::<KeyPair>::decrement_strong_count(ptr as _);
    }
}

#[no_mangle]
pub extern "C" fn share_opaque_KeyPair(ptr: *const c_void) -> *const c_void {
    unsafe {
        Arc::<KeyPair>::increment_strong_count(ptr as _);
        ptr
    }
}

// Section: impl Wire2Api

impl Wire2Api<RustOpaque<KeyPair>> for wire_KeyPair {
    fn wire2api(self) -> RustOpaque<KeyPair> {
        unsafe { support::opaque_from_dart(self.ptr as _) }
    }
}
// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_KeyPair {
    ptr: *const core::ffi::c_void,
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

impl NewWithNullPtr for wire_KeyPair {
    fn new_with_null_ptr() -> Self {
        Self {
            ptr: core::ptr::null(),
        }
    }
}
// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
