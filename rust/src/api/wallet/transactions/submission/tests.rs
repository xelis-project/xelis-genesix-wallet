use anyhow::Error;
use xelis_common::rpc::client::JsonRPCError;

use super::*;

fn daemon_rejection() -> WalletError {
    WalletError::from(Error::new(JsonRPCError::ServerError {
        code: -32_000,
        message: "rejected".to_owned(),
        data: None,
    }))
}

#[test]
fn daemon_server_errors_are_final_rejections() {
    let wallet_error = daemon_rejection();

    let WalletError::Any(inner_error) = &wallet_error else {
        panic!("daemon rejection must be wrapped in WalletError::Any");
    };
    assert!(is_daemon_rejection(inner_error));
    assert_eq!(
        classify_submit_error(&wallet_error),
        SubmitErrorClass::DaemonRejected
    );
}

#[test]
fn transport_and_offline_errors_are_retryable() {
    let transport = WalletError::from(Error::new(JsonRPCError::ConnectionError(
        "offline".to_owned(),
    )));

    assert_eq!(
        classify_submit_error(&transport),
        SubmitErrorClass::Retryable
    );
    assert_eq!(
        classify_submit_error(&WalletError::NotOnlineMode),
        SubmitErrorClass::Retryable
    );
    assert_eq!(
        classify_submit_error(&WalletError::NoNetworkHandler),
        SubmitErrorClass::Retryable
    );
}

#[test]
fn unrelated_wallet_errors_are_not_retryable() {
    assert_eq!(
        classify_submit_error(&WalletError::InvalidAddressParams),
        SubmitErrorClass::LocalFailure
    );
}

#[test]
fn rpc_error_taxonomy_is_conservative_and_explicit() {
    let retryable_cases = [
        JsonRPCError::ConnectionError("offline".to_owned()),
        JsonRPCError::TimedOut("submit_transaction".to_owned()),
        JsonRPCError::NoResponse("submit_transaction".to_owned(), "closed".to_owned()),
        JsonRPCError::SendError("submit_transaction".to_owned(), "closed".to_owned()),
    ];

    for error in retryable_cases {
        assert_eq!(
            classify_submit_error(&WalletError::from(Error::new(error))),
            SubmitErrorClass::Retryable
        );
    }

    let daemon_rejection_cases = [
        JsonRPCError::ParseError,
        JsonRPCError::InvalidRequest,
        JsonRPCError::MethodNotFound,
        JsonRPCError::InvalidParams,
    ];

    for error in daemon_rejection_cases {
        assert_eq!(
            classify_submit_error(&WalletError::from(Error::new(error))),
            SubmitErrorClass::DaemonRejected
        );
    }

    assert_eq!(
        classify_submit_error(&daemon_rejection()),
        SubmitErrorClass::DaemonRejected
    );
    assert_eq!(
        classify_submit_error(&WalletError::from(Error::new(
            JsonRPCError::InternalError {
                message: "internal".to_owned(),
                data: None,
            }
        ))),
        SubmitErrorClass::DaemonRejected
    );
    let conservative_local_failure_cases = [
        JsonRPCError::InvalidBatch,
        JsonRPCError::MissingResult,
        JsonRPCError::EventNotRegistered,
    ];

    for error in conservative_local_failure_cases {
        assert_eq!(
            classify_submit_error(&WalletError::from(Error::new(error))),
            SubmitErrorClass::LocalFailure
        );
    }

    assert_eq!(
        classify_submit_error(&WalletError::from(anyhow::anyhow!("unexpected"))),
        SubmitErrorClass::LocalFailure
    );
}
