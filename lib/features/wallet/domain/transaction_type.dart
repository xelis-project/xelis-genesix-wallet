enum TxType {
  coinbase,
  incoming,
  outgoing,
  burn;

  factory TxType.fromStr(String value) {
    switch (value) {
      case 'coinbase':
        return TxType.coinbase;
      case 'incoming':
        return TxType.incoming;
      case 'outgoing':
        return TxType.outgoing;
      case 'burn':
        return TxType.burn;
      default:
        throw Exception('Unknown Tx type: $value');
    }
  }
}
