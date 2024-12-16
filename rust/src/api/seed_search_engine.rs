use anyhow::{Ok, Result};
use flutter_rust_bridge::frb;
use trie_rs::{Trie, TrieBuilder};
use xelis_wallet::mnemonics::{languages::english::ENGLISH, LANGUAGES};

pub struct SearchEngine {
    trie: Trie<u8>,
}

impl SearchEngine {
    #[frb(sync)]
    pub fn init(language_index: usize) -> Self {
        let language = LANGUAGES.get(language_index).unwrap_or(&ENGLISH);
        let mut builder = TrieBuilder::new();
        for &word in language.get_words() {
            builder.push(word);
        }
        Self {
            trie: builder.build(),
        }
    }

    #[frb(sync)]
    // Search for words that match the query
    pub fn search(&self, query: String) -> Result<Vec<String>> {
        let results: Vec<String> = self.trie.predictive_search(query).collect();
        Ok(results)
    }

    #[frb(sync)]
    // Check if the seed is valid, return the invalid words
    pub fn check_seed(&self, seed: Vec<String>) -> Result<Vec<String>> {
        let mut results: Vec<String> = Vec::new();
        for word in seed {
            if !self.trie.exact_match(word.clone()) {
                results.push(word);
            }
        }
        Ok(results)
    }
}
