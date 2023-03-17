use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_create_key_pair(port_: i64, seed: *mut wire_uint_8_list) {
    wire_create_key_pair_impl(port_, seed)
}

#[no_mangle]
pub extern "C" fn wire_set_network_to_mainnet(port_: i64) {
    wire_set_network_to_mainnet_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_set_network_to_testnet(port_: i64) {
    wire_set_network_to_testnet_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_set_network_to_dev(port_: i64) {
    wire_set_network_to_dev_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_get_address__method__XelisKeyPair(port_: i64, that: *mut wire_XelisKeyPair) {
    wire_get_address__method__XelisKeyPair_impl(port_, that)
}

#[no_mangle]
pub extern "C" fn wire_get_seed__method__XelisKeyPair(
    port_: i64,
    that: *mut wire_XelisKeyPair,
    language_index: usize,
) {
    wire_get_seed__method__XelisKeyPair_impl(port_, that, language_index)
}

#[no_mangle]
pub extern "C" fn wire_sign__method__XelisKeyPair(
    port_: i64,
    that: *mut wire_XelisKeyPair,
    data: *mut wire_uint_8_list,
) {
    wire_sign__method__XelisKeyPair_impl(port_, that, data)
}

#[no_mangle]
pub extern "C" fn wire_verify_signature__method__XelisKeyPair(
    port_: i64,
    that: *mut wire_XelisKeyPair,
    hash: *mut wire_uint_8_list,
    signature: wire_Signature,
) {
    wire_verify_signature__method__XelisKeyPair_impl(port_, that, hash, signature)
}

#[no_mangle]
pub extern "C" fn wire_get_estimated_fees__method__XelisKeyPair(
    port_: i64,
    that: *mut wire_XelisKeyPair,
    address: *mut wire_uint_8_list,
    amount: u64,
    asset: *mut wire_uint_8_list,
    nonce: u64,
) {
    wire_get_estimated_fees__method__XelisKeyPair_impl(port_, that, address, amount, asset, nonce)
}

#[no_mangle]
pub extern "C" fn wire_create_tx__method__XelisKeyPair(
    port_: i64,
    that: *mut wire_XelisKeyPair,
    address: *mut wire_uint_8_list,
    amount: u64,
    asset: *mut wire_uint_8_list,
    balance: u64,
    nonce: u64,
) {
    wire_create_tx__method__XelisKeyPair_impl(port_, that, address, amount, asset, balance, nonce)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_KeyPair() -> wire_KeyPair {
    wire_KeyPair::new_with_null_ptr()
}

#[no_mangle]
pub extern "C" fn new_Signature() -> wire_Signature {
    wire_Signature::new_with_null_ptr()
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_xelis_key_pair_0() -> *mut wire_XelisKeyPair {
    support::new_leak_box_ptr(wire_XelisKeyPair::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
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

#[no_mangle]
pub extern "C" fn drop_opaque_Signature(ptr: *const c_void) {
    unsafe {
        Arc::<Signature>::decrement_strong_count(ptr as _);
    }
}

#[no_mangle]
pub extern "C" fn share_opaque_Signature(ptr: *const c_void) -> *const c_void {
    unsafe {
        Arc::<Signature>::increment_strong_count(ptr as _);
        ptr
    }
}

// Section: impl Wire2Api

impl Wire2Api<RustOpaque<KeyPair>> for wire_KeyPair {
    fn wire2api(self) -> RustOpaque<KeyPair> {
        unsafe { support::opaque_from_dart(self.ptr as _) }
    }
}
impl Wire2Api<RustOpaque<Signature>> for wire_Signature {
    fn wire2api(self) -> RustOpaque<Signature> {
        unsafe { support::opaque_from_dart(self.ptr as _) }
    }
}
impl Wire2Api<String> for *mut wire_uint_8_list {
    fn wire2api(self) -> String {
        let vec: Vec<u8> = self.wire2api();
        String::from_utf8_lossy(&vec).into_owned()
    }
}
impl Wire2Api<XelisKeyPair> for *mut wire_XelisKeyPair {
    fn wire2api(self) -> XelisKeyPair {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<XelisKeyPair>::wire2api(*wrap).into()
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}

impl Wire2Api<XelisKeyPair> for wire_XelisKeyPair {
    fn wire2api(self) -> XelisKeyPair {
        XelisKeyPair {
            key_pair: self.key_pair.wire2api(),
        }
    }
}
// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_KeyPair {
    ptr: *const core::ffi::c_void,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_Signature {
    ptr: *const core::ffi::c_void,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_XelisKeyPair {
    key_pair: wire_KeyPair,
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
impl NewWithNullPtr for wire_Signature {
    fn new_with_null_ptr() -> Self {
        Self {
            ptr: core::ptr::null(),
        }
    }
}

impl NewWithNullPtr for wire_XelisKeyPair {
    fn new_with_null_ptr() -> Self {
        Self {
            key_pair: wire_KeyPair::new_with_null_ptr(),
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
