use super::{
    models::address_book_dtos::{AddressBookData, ContactDetails},
    wallet::XelisWallet,
};
use anyhow::{bail, Result};
use xelis_common::api::{
    query::{Query, QueryValue},
    DataElement, DataValue,
};

const ADDRESS_BOOK_TREE: &str = "address_book";

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
        let address_book = storage.query_db(ADDRESS_BOOK_TREE, None, None, None, None)?;
        let address_book = AddressBookData::from(address_book.entries)?;
        Ok(address_book)
    }

    // get contacts by name
    async fn find_contacts_by_name(&self, name: String) -> Result<AddressBookData> {
        let storage = self.get_wallet().get_storage().read().await;
        let query_name = Query::Value(QueryValue::StartsWith(DataValue::String(name)));
        let address_book =
            storage.query_db(ADDRESS_BOOK_TREE, None, Some(query_name), None, None)?;
        let address_book = AddressBookData::from(address_book.entries)?;
        Ok(address_book)
    }

    // update or add a contact
    async fn upsert_contact(&self, entry: ContactDetails) -> Result<()> {
        let mut storage = self.get_wallet().get_storage().write().await;
        storage.set_custom_data(
            ADDRESS_BOOK_TREE,
            &DataValue::String(entry.address.clone()),
            &entry.to_data_element(),
        )
    }

    // remove a contact
    async fn remove_contact(&self, address: String) -> Result<()> {
        let mut storage = self.get_wallet().get_storage().write().await;
        storage.delete_custom_data(ADDRESS_BOOK_TREE, &DataValue::String(address))
    }

    // get a contact by address
    async fn find_contact_by_address(&self, address: String) -> Result<ContactDetails> {
        let storage = self.get_wallet().get_storage().read().await;
        let entry = storage.get_custom_data(ADDRESS_BOOK_TREE, &DataValue::String(address))?;

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
        let storage = self.get_wallet().get_storage().read().await;
        storage.has_custom_data(ADDRESS_BOOK_TREE, &DataValue::String(address))
    }
}
