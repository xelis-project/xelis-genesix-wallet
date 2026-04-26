import 'package:flutter/material.dart';

class TransactionDialog extends StatelessWidget {
  const TransactionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Text('Transaction is pending signature review.'),
    );
  }
}
