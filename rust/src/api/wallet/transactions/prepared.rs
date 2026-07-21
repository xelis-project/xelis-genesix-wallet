use std::mem;

use anyhow::{bail, Context, Result};
use log::{error, warn};
use parking_lot::RwLock;
use xelis_common::crypto::Hash;

pub(super) enum PreparedTransactionState<T> {
    Empty,
    Ready { hash: Hash, transaction: T },
    InFlight { hash: Hash },
}

impl<T> Default for PreparedTransactionState<T> {
    fn default() -> Self {
        Self::Empty
    }
}

pub(in crate::api::wallet) struct PreparedTransactionStore<T> {
    pub(super) state: PreparedTransactionState<T>,
}

impl<T> Default for PreparedTransactionStore<T> {
    fn default() -> Self {
        Self {
            state: PreparedTransactionState::Empty,
        }
    }
}

impl<T> PreparedTransactionStore<T> {
    pub(in crate::api::wallet) fn ensure_replaceable(&self) -> Result<()> {
        if matches!(self.state, PreparedTransactionState::InFlight { .. }) {
            bail!(
                "Cannot replace a prepared transaction while another transaction is being submitted"
            );
        }

        Ok(())
    }

    pub(in crate::api::wallet) fn replace(&mut self, hash: Hash, transaction: T) -> Result<()> {
        self.ensure_replaceable()?;
        self.state = PreparedTransactionState::Ready { hash, transaction };
        Ok(())
    }

    pub(super) fn cancel(&mut self, hash: &Hash) -> Result<T> {
        match &self.state {
            PreparedTransactionState::InFlight {
                hash: submitted_hash,
            } if submitted_hash == hash => {
                bail!("Cannot cancel a transaction while it is being submitted")
            }
            PreparedTransactionState::Ready {
                hash: prepared_hash,
                ..
            } if prepared_hash == hash => {}
            _ => bail!("Cannot delete prepared transaction"),
        }

        match mem::take(&mut self.state) {
            PreparedTransactionState::Ready { transaction, .. } => Ok(transaction),
            previous_state => {
                self.state = previous_state;
                bail!("Prepared transaction state changed during cancellation")
            }
        }
    }

    pub(super) fn take_for_submission(&mut self, hash: &Hash) -> Result<T> {
        match &self.state {
            PreparedTransactionState::InFlight {
                hash: submitted_hash,
            } if submitted_hash == hash => {
                bail!("Transaction is already being submitted")
            }
            PreparedTransactionState::Ready {
                hash: prepared_hash,
                ..
            } if prepared_hash == hash => {}
            _ => bail!("Cannot find prepared transaction"),
        }

        match mem::take(&mut self.state) {
            PreparedTransactionState::Ready {
                hash: prepared_hash,
                transaction,
            } => {
                self.state = PreparedTransactionState::InFlight {
                    hash: prepared_hash,
                };
                Ok(transaction)
            }
            previous_state => {
                self.state = previous_state;
                bail!("Prepared transaction state changed before submission")
            }
        }
    }

    fn restore_after_submission(&mut self, hash: Hash, transaction: T) -> Result<()> {
        match &self.state {
            PreparedTransactionState::InFlight {
                hash: submitted_hash,
            } if submitted_hash == &hash => {
                self.state = PreparedTransactionState::Ready { hash, transaction };
                Ok(())
            }
            _ => bail!("Prepared transaction submission state is inconsistent"),
        }
    }

    fn finish_submission(&mut self, hash: &Hash) -> bool {
        if matches!(
            &self.state,
            PreparedTransactionState::InFlight {
                hash: submitted_hash
            } if submitted_hash == hash
        ) {
            self.state = PreparedTransactionState::Empty;
            true
        } else {
            false
        }
    }
}

pub(super) struct PreparedTransactionGuard<'a, T> {
    store: &'a RwLock<PreparedTransactionStore<T>>,
    hash: Hash,
    transaction: Option<T>,
}

impl<'a, T> PreparedTransactionGuard<'a, T> {
    pub(super) fn take(store: &'a RwLock<PreparedTransactionStore<T>>, hash: Hash) -> Result<Self> {
        let transaction = store.write().take_for_submission(&hash)?;
        Ok(Self {
            store,
            hash,
            transaction: Some(transaction),
        })
    }

    pub(super) fn transaction(&self) -> Result<&T> {
        self.transaction
            .as_ref()
            .context("Prepared transaction guard is empty")
    }

    pub(super) fn restore(mut self) -> Result<()> {
        let transaction = self
            .transaction
            .take()
            .context("Prepared transaction guard is empty")?;
        self.store
            .write()
            .restore_after_submission(self.hash.clone(), transaction)
    }

    pub(super) fn finish(mut self) -> Result<T> {
        let transaction = self
            .transaction
            .take()
            .context("Prepared transaction guard is empty")?;

        if !self.store.write().finish_submission(&self.hash) {
            self.transaction = Some(transaction);
            bail!("Prepared transaction submission state is inconsistent");
        }

        Ok(transaction)
    }
}

impl<T> Drop for PreparedTransactionGuard<'_, T> {
    fn drop(&mut self) {
        if let Some(transaction) = self.transaction.take() {
            if let Err(error) = self
                .store
                .write()
                .restore_after_submission(self.hash.clone(), transaction)
            {
                error!(
                    "Prepared transaction could not be restored after an interrupted submission: {error}"
                );
            } else {
                warn!(
                    "Prepared transaction {} restored after an interrupted submission",
                    self.hash
                );
            }
        }
    }
}

#[cfg(test)]
mod tests;
