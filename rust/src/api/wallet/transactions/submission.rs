use anyhow::{bail, Result};
use xelis_common::rpc::client::JsonRPCError;
use xelis_wallet::error::WalletError;

pub(super) enum SubmissionResolution {
    Submitted,
    Retryable(WalletError),
    DaemonRejected(WalletError),
    LocalFailure(WalletError),
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(super) enum SubmitErrorClass {
    Retryable,
    DaemonRejected,
    LocalFailure,
}

pub(super) fn ensure_wallet_online(is_online: bool) -> Result<()> {
    if !is_online {
        bail!("Wallet is offline, transaction cannot be submitted");
    }

    Ok(())
}

pub(super) fn resolve_submission(
    submit_result: std::result::Result<(), WalletError>,
) -> SubmissionResolution {
    match submit_result {
        Ok(()) => SubmissionResolution::Submitted,
        Err(error) => match classify_submit_error(&error) {
            SubmitErrorClass::Retryable => SubmissionResolution::Retryable(error),
            SubmitErrorClass::DaemonRejected => SubmissionResolution::DaemonRejected(error),
            SubmitErrorClass::LocalFailure => SubmissionResolution::LocalFailure(error),
        },
    }
}

pub(super) fn is_daemon_rejection(error: &anyhow::Error) -> bool {
    matches!(
        error.downcast_ref::<JsonRPCError>(),
        Some(
            JsonRPCError::ParseError
                | JsonRPCError::InvalidRequest
                | JsonRPCError::MethodNotFound
                | JsonRPCError::InvalidParams
                | JsonRPCError::InternalError { .. }
                | JsonRPCError::ServerError { .. }
        )
    )
}

fn is_retryable_rpc_error(error: &anyhow::Error) -> bool {
    matches!(
        error.downcast_ref::<JsonRPCError>(),
        Some(
            JsonRPCError::NoResponse(_, _)
                | JsonRPCError::TimedOut(_)
                | JsonRPCError::HttpError(_)
                | JsonRPCError::ConnectionError(_)
                | JsonRPCError::SocketError(_)
                | JsonRPCError::SendError(_, _)
        )
    )
}

pub(super) fn classify_submit_error(error: &WalletError) -> SubmitErrorClass {
    // Retain the prepared transaction only for explicitly known transport or
    // offline failures. New or wrapped error variants must remain final until
    // their retry semantics have been reviewed.
    match error {
        WalletError::Any(error) if is_retryable_rpc_error(error) => SubmitErrorClass::Retryable,
        WalletError::Any(error) if is_daemon_rejection(error) => SubmitErrorClass::DaemonRejected,
        WalletError::NotOnlineMode | WalletError::NoNetworkHandler => SubmitErrorClass::Retryable,
        _ => SubmitErrorClass::LocalFailure,
    }
}

#[cfg(test)]
mod tests;
