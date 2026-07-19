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
mod tests;
