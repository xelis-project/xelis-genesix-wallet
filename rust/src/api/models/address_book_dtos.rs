use std::collections::HashMap;

use flutter_rust_bridge::frb;
use indexmap::IndexMap;
use serde::{Deserialize, Serialize};
use xelis_common::api::{DataConversionError, DataElement, DataValue};

#[derive(Clone, Debug)]
pub struct AddressBookData {
    pub contacts: HashMap<String, ContactDetails>,
}

impl AddressBookData {
    #[frb(ignore)]
    pub fn new() -> Self {
        AddressBookData {
            contacts: HashMap::new(),
        }
    }

    #[frb(ignore)]
    pub fn from(entries: IndexMap<DataValue, DataElement>) -> Result<Self, DataConversionError> {
        let mut address_book = AddressBookData::new();

        for (key, value) in entries {
            if let DataValue::String(address) = key {
                if let DataElement::Fields(fields) = value {
                    let name = fields
                        .get(&DataValue::String("name".to_string()))
                        .and_then(|v| v.as_value().ok())
                        .and_then(|v| v.as_string().ok())
                        .cloned()
                        .ok_or(DataConversionError::ExpectedValue)?;

                    let note = fields
                        .get(&DataValue::String("note".to_string()))
                        .and_then(|v| v.as_value().ok())
                        .and_then(|v| v.as_string().ok())
                        .cloned();

                    let contact_details = ContactDetails::new(name, address.clone(), note);

                    address_book.add_entry(address, contact_details);
                }
            }
        }

        Ok(address_book)
    }

    pub fn get_all_entries(&self) -> Vec<ContactDetails> {
        self.contacts.values().cloned().collect()
    }

    fn add_entry(&mut self, address: String, entry: ContactDetails) {
        self.contacts.insert(address, entry);
    }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ContactDetails {
    pub name: String,
    pub address: String,
    pub note: Option<String>,
}

impl ContactDetails {
    #[frb(ignore)]
    pub fn new(name: String, address: String, note: Option<String>) -> Self {
        ContactDetails {
            name,
            address,
            note,
        }
    }

    #[frb(ignore)]
    pub fn from(fields: HashMap<DataValue, DataElement>) -> Result<Self, DataConversionError> {
        let name = fields
            .get(&DataValue::String("name".to_string()))
            .and_then(|v| v.as_value().ok())
            .and_then(|v| v.as_string().ok())
            .cloned()
            .ok_or(DataConversionError::ExpectedValue)?;

        let address = fields
            .get(&DataValue::String("address".to_string()))
            .and_then(|v| v.as_value().ok())
            .and_then(|v| v.as_string().ok())
            .cloned()
            .ok_or(DataConversionError::ExpectedValue)?;

        let note = fields
            .get(&DataValue::String("note".to_string()))
            .and_then(|v| v.as_value().ok())
            .and_then(|v| v.as_string().ok())
            .cloned();

        Ok(ContactDetails {
            name,
            address,
            note,
        })
    }

    #[frb(ignore)]
    pub fn to_data_element(&self) -> DataElement {
        let mut fields = HashMap::new();
        fields.insert(
            DataValue::String("name".to_string()),
            DataElement::Value(DataValue::String(self.name.clone())),
        );
        fields.insert(
            DataValue::String("address".to_string()),
            DataElement::Value(DataValue::String(self.address.clone())),
        );
        if let Some(note) = &self.note {
            fields.insert(
                DataValue::String("note".to_string()),
                DataElement::Value(DataValue::String(note.clone())),
            );
        }

        DataElement::Fields(fields)
    }
}
