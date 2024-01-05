pub use xelis_common::network::Network;
use xelis_common::utils::set_network_to;

pub fn set_network_to_mainnet() {
    set_network_to(Network::Mainnet);
}

pub fn set_network_to_testnet() {
    set_network_to(Network::Testnet);
}

pub fn set_network_to_dev() {
    set_network_to(Network::Dev);
}
