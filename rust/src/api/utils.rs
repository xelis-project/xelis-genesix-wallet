use flutter_rust_bridge::frb;
use xelis_common::crypto::Address;

#[frb(sync)]
pub fn is_address_valid(str_address: String) -> bool {
    match Address::from_string(&str_address) {
        Ok(_) => true,
        Err(_) => false,
    }
}
