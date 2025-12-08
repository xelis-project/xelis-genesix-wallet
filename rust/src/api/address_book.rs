use super::{
    models::address_book_dtos::{AddressBookData, ContactDetails},
    wallet::XelisWallet,
};
use anyhow::{bail, Result};
use regex::RegexBuilder;
use xelis_common::{
    api::{
        DataElement, DataValue, query::{Query, QueryElement, QueryValue}
    },
    crypto::Address,
};

const ADDRESS_BOOK_TREE: &str = "address_book";

// AddressBook trait for managing contacts
#[allow(async_fn_in_trait)]
pub trait AddressBook {
    async fn retrieve_contacts(&self, skip: Option<usize>, take: Option<usize>) -> Result<AddressBookData>;

    async fn count_contacts(&self) -> Result<usize>;

    async fn find_contacts_by_name(&self, name: String, skip: Option<usize>, take: Option<usize>) -> Result<AddressBookData>;

    async fn upsert_contact(&self, entry: ContactDetails) -> Result<()>;

    async fn remove_contact(&self, address: String) -> Result<()>;

    async fn find_contact_by_address(&self, address: String) -> Result<ContactDetails>;

    async fn is_contact_present(&self, address: String) -> Result<bool>;
}

impl AddressBook for XelisWallet {
    // get contacts with pagination
    // returns a map of address to ContactDetails
    async fn retrieve_contacts(&self, skip: Option<usize>, take: Option<usize>) -> Result<AddressBookData> {
        let storage = self.get_wallet().get_storage().read().await;
        let address_book = storage.query_db(ADDRESS_BOOK_TREE, None, None, take, skip)?;
        Ok(AddressBookData::from(address_book.entries)?)
    }

    // count total contacts
    async fn count_contacts(&self) -> Result<usize> {
        let storage = self.get_wallet().get_storage().read().await;
        storage.count_custom_tree_entries(ADDRESS_BOOK_TREE, &None, &None)
    }

    // get contacts by name with pagination
    async fn find_contacts_by_name(&self, name: String, skip: Option<usize>, take: Option<usize>) -> Result<AddressBookData> {
        // Create a regex pattern to match contacts containing the given name
        // The regex pattern is case-insensitive and does a substring match
        let regex = RegexBuilder::new(&regex::escape(&name))
            .unicode(true)
            .case_insensitive(true)
            .build()?;

        // Create a query to find contacts with names matching the regex pattern
        // The query uses the `AtKey` element to search for the "name" field in the address book
        let query_name = Query::Element(QueryElement::AtKey {
            key: DataValue::String("name".to_string()),
            query: Box::new(Query::Value(QueryValue::Matches(regex))),
        });

        let storage = self.get_wallet().get_storage().read().await;

        let address_book = storage.query_db(
            ADDRESS_BOOK_TREE,
            None,
            Some(query_name),
            take,
            skip,
        )?;
        Ok(AddressBookData::from(address_book.entries)?)
    }

    // update or add a contact
    async fn upsert_contact(&self, entry: ContactDetails) -> Result<()> {
        let address = Address::from_string(&entry.address)?;
        if address.is_mainnet() != self.get_wallet().get_network().is_mainnet() {
            bail!("Cannot add contact with address from a different network");
        }

        let mut storage = self.get_wallet().get_storage().write().await;

        storage.set_custom_data(
            ADDRESS_BOOK_TREE,
            &DataValue::String(entry.address.clone()),
            &entry.to_data_element(),
        )
    }

    // remove a contact
    async fn remove_contact(&self, address: String) -> Result<()> {
        let addr = Address::from_string(&address)?;
        if addr.is_mainnet() != self.get_wallet().get_network().is_mainnet() {
            bail!("Cannot add contact with address from a different network");
        }

        let mut storage = self.get_wallet().get_storage().write().await;
        storage.delete_custom_data(ADDRESS_BOOK_TREE, &DataValue::String(address))
    }

    // get a contact by address
    async fn find_contact_by_address(&self, address: String) -> Result<ContactDetails> {
        let addr = Address::from_string(&address)?;
        if addr.is_mainnet() != self.get_wallet().get_network().is_mainnet() {
            bail!("Cannot find contact with address from a different network");
        }
        let storage = self.get_wallet().get_storage().read().await;

        let entry = storage.get_custom_data(
            ADDRESS_BOOK_TREE,
            &DataValue::String(address.clone()),
        )?;

        match entry {
            DataElement::Fields(content) => {
                let entry = ContactDetails::from(content)?;
                Ok(entry)
            }
            _ => bail!("Data for address {} is not a valid contact entry", address),
        }
    }

    // check if a contact is present
    async fn is_contact_present(&self, address: String) -> Result<bool> {
        let addr = Address::from_string(&address)?;
        if addr.is_mainnet() != self.get_wallet().get_network().is_mainnet() {
            bail!("Cannot check contact with address from a different network");
        }

        let storage = self.get_wallet().get_storage().read().await;
        storage.has_custom_data(ADDRESS_BOOK_TREE, &DataValue::String(address))
    }
}
