use anyhow::{ensure, Context, Result};

pub(super) fn checked_atomic_amount(float_amount: f64, decimals: u8) -> Result<u64> {
    ensure!(
        float_amount.is_finite() && float_amount > 0.0,
        "The amount must be a finite positive number"
    );
    let factor = 10u64
        .checked_pow(decimals as u32)
        .context("The asset decimal precision is unsupported")?;
    let scaled = float_amount * factor as f64;
    ensure!(
        scaled.is_finite() && scaled < u64::MAX as f64,
        "The amount is too large"
    );
    let rounded = scaled.round();
    ensure!(
        (scaled - rounded).abs() <= 1e-6,
        "The amount has more decimal places than the asset supports"
    );
    let amount = rounded as u64;
    ensure!(amount > 0, "The amount is below the smallest asset unit");
    Ok(amount)
}

#[cfg(test)]
mod tests {
    use super::checked_atomic_amount;

    #[test]
    fn atomic_amount_accepts_supported_decimal_precision() {
        assert_eq!(checked_atomic_amount(1.25, 8).unwrap(), 125_000_000);
        assert_eq!(checked_atomic_amount(0.1, 8).unwrap(), 10_000_000);
    }

    #[test]
    fn atomic_amount_rejects_non_finite_and_non_positive_values() {
        assert!(checked_atomic_amount(f64::NAN, 8).is_err());
        assert!(checked_atomic_amount(f64::INFINITY, 8).is_err());
        assert!(checked_atomic_amount(-1.0, 8).is_err());
        assert!(checked_atomic_amount(0.0, 8).is_err());
    }

    #[test]
    fn atomic_amount_rejects_out_of_range_or_excess_precision() {
        assert!(checked_atomic_amount(f64::MAX, 8).is_err());
        assert!(checked_atomic_amount(u64::MAX as f64, 0).is_err());
        assert!(checked_atomic_amount(0.000_000_001, 8).is_err());
    }
}
