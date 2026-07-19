use super::checked_atomic_amount;

#[test]
fn atomic_amount_accepts_supported_decimal_precision() {
    assert_eq!(checked_atomic_amount(1.25, 8).unwrap(), 125_000_000);
    assert_eq!(checked_atomic_amount(0.1, 8).unwrap(), 10_000_000);
    assert_eq!(checked_atomic_amount(0.000_000_01, 8).unwrap(), 1);
}

#[test]
fn atomic_amount_accepts_only_the_documented_rounding_tolerance() {
    assert_eq!(checked_atomic_amount(0.000_001_000_000_5, 6).unwrap(), 1);
    assert!(checked_atomic_amount(0.000_001_000_002, 6).is_err());
}

#[test]
fn atomic_amount_rejects_non_finite_and_non_positive_values() {
    assert!(checked_atomic_amount(f64::NAN, 8).is_err());
    assert!(checked_atomic_amount(f64::INFINITY, 8).is_err());
    assert!(checked_atomic_amount(f64::NEG_INFINITY, 8).is_err());
    assert!(checked_atomic_amount(-1.0, 8).is_err());
    assert!(checked_atomic_amount(0.0, 8).is_err());
}

#[test]
fn atomic_amount_rejects_out_of_range_or_excess_precision() {
    assert!(checked_atomic_amount(f64::MAX, 8).is_err());
    assert!(checked_atomic_amount(u64::MAX as f64, 0).is_err());
    assert!(checked_atomic_amount(0.000_000_001, 8).is_err());
}

#[test]
fn atomic_amount_rejects_unsupported_asset_precision() {
    let error = checked_atomic_amount(1.0, 20).unwrap_err();

    assert_eq!(
        error.to_string(),
        "The asset decimal precision is unsupported"
    );
}
