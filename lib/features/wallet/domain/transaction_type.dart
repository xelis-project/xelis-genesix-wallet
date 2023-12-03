enum TxType {
  coinbase,
  incoming,
  outgoing,
  unknown,
}

TxType toTxType(String type) {
  switch (type) {
    case 'coinbase':
      return TxType.coinbase;
    case 'incoming':
      return TxType.incoming;
    case 'outgoing':
      return TxType.outgoing;
    default:
      return TxType.unknown;
  }
}
