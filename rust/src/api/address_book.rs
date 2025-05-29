use super::{
    models::address_book_dtos::{AddressBookData, ContactDetails},
    wallet::XelisWallet,
};
use anyhow::{bail, Result};
use regex::RegexBuilder;
use xelis_common::{
    api::{
        query::{Query, QueryElement, QueryValue},
        DataElement, DataValue,
    },
    crypto::Address,
};

const ADDRESS_BOOK_TREE_MAINNET: &str = "address_book_mainnet";
const ADDRESS_BOOK_TREE_TESTNET_DEV: &str = "address_book_testnet_dev";

// AddressBook trait for managing contacts
#[allow(async_fn_in_trait)]
pub trait AddressBook {
    async fn retrieve_all_contacts(&self) -> Result<AddressBookData>;

    async fn find_contacts_by_name(&self, name: String) -> Result<AddressBookData>;

    async fn upsert_contact(&self, entry: ContactDetails) -> Result<()>;

    async fn remove_contact(&self, address: String) -> Result<()>;

    async fn find_contact_by_address(&self, address: String) -> Result<ContactDetails>;

    async fn is_contact_present(&self, address: String) -> Result<bool>;
}

impl AddressBook for XelisWallet {
    // get all contacts
    // returns a map of address to ContactDetails
    async fn retrieve_all_contacts(&self) -> Result<AddressBookData> {
        let storage = self.get_wallet().get_storage().read().await;
        if self.get_wallet().get_network().is_mainnet() {
            let address_book =
                storage.query_db(ADDRESS_BOOK_TREE_MAINNET, None, None, None, None)?;
            Ok(AddressBookData::from(address_book.entries)?)
        } else {
            let address_book =
                storage.query_db(ADDRESS_BOOK_TREE_TESTNET_DEV, None, None, None, None)?;
            Ok(AddressBookData::from(address_book.entries)?)
        }
    }

    // get contacts by name
    async fn find_contacts_by_name(&self, name: String) -> Result<AddressBookData> {
        // Create a regex pattern to match contacts starting with the given name
        // The regex pattern is case-insensitive and matches the name followed by any number of letters, digits, underscores, or hyphens
        let regex = RegexBuilder::new(&format!(
            r"(?i)\b{}[\p{{L}}\p{{N}}_\-]*",
            regex::escape(&name)
        ))
        .unicode(true)
        .case_insensitive(true)
        .build()
        .expect("Failed to build regex");

        // Create a query to find contacts with names matching the regex pattern
        // The query uses the `AtKey` element to search for the "name" field in the address book
        let query_name = Query::Element(QueryElement::AtKey {
            key: DataValue::String("name".to_string()),
            query: Box::new(Query::Value(QueryValue::Matches(regex))),
        });

        let storage = self.get_wallet().get_storage().read().await;

        if self.get_wallet().get_network().is_mainnet() {
            let address_book = storage.query_db(
                ADDRESS_BOOK_TREE_MAINNET,
                None,
                Some(query_name),
                None,
                None,
            )?;
            Ok(AddressBookData::from(address_book.entries)?)
        } else {
            let address_book = storage.query_db(
                ADDRESS_BOOK_TREE_TESTNET_DEV,
                None,
                Some(query_name),
                None,
                None,
            )?;
            Ok(AddressBookData::from(address_book.entries)?)
        }
    }

    // update or add a contact
    async fn upsert_contact(&self, entry: ContactDetails) -> Result<()> {
        let address = Address::from_string(&entry.address).expect("Invalid address format");
        let mut storage = self.get_wallet().get_storage().write().await;
        if address.is_mainnet() {
            storage.set_custom_data(
                ADDRESS_BOOK_TREE_MAINNET,
                &DataValue::String(entry.address.clone()),
                &entry.to_data_element(),
            )
        } else {
            storage.set_custom_data(
                ADDRESS_BOOK_TREE_TESTNET_DEV,
                &DataValue::String(entry.address.clone()),
                &entry.to_data_element(),
            )
        }
    }

    // remove a contact
    async fn remove_contact(&self, address: String) -> Result<()> {
        let addr = Address::from_string(&address).expect("Invalid address format");
        let mut storage = self.get_wallet().get_storage().write().await;
        if addr.is_mainnet() {
            storage.delete_custom_data(ADDRESS_BOOK_TREE_MAINNET, &DataValue::String(address))
        } else {
            storage.delete_custom_data(ADDRESS_BOOK_TREE_TESTNET_DEV, &DataValue::String(address))
        }
    }

    // get a contact by address
    async fn find_contact_by_address(&self, address: String) -> Result<ContactDetails> {
        let addr = Address::from_string(&address).expect("Invalid address format");
        let storage = self.get_wallet().get_storage().read().await;

        let entry = if addr.is_mainnet() {
            storage.get_custom_data(ADDRESS_BOOK_TREE_MAINNET, &DataValue::String(address))?
        } else {
            storage.get_custom_data(ADDRESS_BOOK_TREE_TESTNET_DEV, &DataValue::String(address))?
        };

        match entry {
            DataElement::Fields(content) => {
                let entry = ContactDetails::from(content)?;
                Ok(entry)
            }
            _ => bail!("Address book entry not found"),
        }
    }

    // check if a contact is present
    async fn is_contact_present(&self, address: String) -> Result<bool> {
        let addr = Address::from_string(&address).expect("Invalid address format");
        let storage = self.get_wallet().get_storage().read().await;
        if addr.is_mainnet() {
            storage.has_custom_data(ADDRESS_BOOK_TREE_MAINNET, &DataValue::String(address))
        } else {
            storage.has_custom_data(ADDRESS_BOOK_TREE_TESTNET_DEV, &DataValue::String(address))
        }
    }
}
