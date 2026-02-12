/// Fiat and popular currencies supported by CoinGecko for price conversion.
///
/// The [code] is used as the `vs_currency` parameter in CoinGecko API calls.
enum DisplayCurrency {
  usd('usd', '\$', 'US Dollar'),
  eur('eur', '€', 'Euro'),
  gbp('gbp', '£', 'British Pound'),
  jpy('jpy', '¥', 'Japanese Yen'),
  cny('cny', '¥', 'Chinese Yuan'),
  krw('krw', '₩', 'South Korean Won'),
  inr('inr', '₹', 'Indian Rupee'),
  cad('cad', 'CA\$', 'Canadian Dollar'),
  aud('aud', 'A\$', 'Australian Dollar'),
  chf('chf', 'CHF', 'Swiss Franc'),
  brl('brl', 'R\$', 'Brazilian Real'),
  rub('rub', '₽', 'Russian Ruble'),
  try_('try', '₺', 'Turkish Lira'),
  mxn('mxn', 'MX\$', 'Mexican Peso'),
  sgd('sgd', 'S\$', 'Singapore Dollar'),
  hkd('hkd', 'HK\$', 'Hong Kong Dollar'),
  nok('nok', 'kr', 'Norwegian Krone'),
  sek('sek', 'kr', 'Swedish Krona'),
  dkk('dkk', 'kr', 'Danish Krone'),
  pln('pln', 'zł', 'Polish Zloty'),
  czk('czk', 'Kč', 'Czech Koruna'),
  zar('zar', 'R', 'South African Rand'),
  nzd('nzd', 'NZ\$', 'New Zealand Dollar'),
  thb('thb', '฿', 'Thai Baht'),
  twd('twd', 'NT\$', 'Taiwan Dollar'),
  idr('idr', 'Rp', 'Indonesian Rupiah'),
  php('php', '₱', 'Philippine Peso'),
  myr('myr', 'RM', 'Malaysian Ringgit'),
  aed('aed', 'د.إ', 'UAE Dirham'),
  sar('sar', '﷼', 'Saudi Riyal'),
  btc('btc', '₿', 'Bitcoin'),
  eth('eth', 'Ξ', 'Ethereum');

  const DisplayCurrency(this.code, this.symbol, this.name);

  /// The CoinGecko `vs_currency` code (e.g. 'usd', 'eur').
  final String code;

  /// A short symbol for display (e.g. '\$', '€').
  final String symbol;

  /// A human-readable name (e.g. 'US Dollar').
  final String name;

  /// Display label for the UI selector: "USD - US Dollar".
  String get label => '${code.toUpperCase()} - $name';

  /// Look up a [DisplayCurrency] by its CoinGecko code.
  /// Returns `null` if the code is not in the enum.
  static DisplayCurrency? fromCode(String? code) {
    if (code == null) return null;
    final lower = code.toLowerCase();
    for (final currency in values) {
      if (currency.code == lower) return currency;
    }
    return null;
  }
}
