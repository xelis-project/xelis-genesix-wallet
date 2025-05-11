import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';

class ContactDropdownMenuItem {
  static DropdownMenuItem<String> fromMapEntry(
    BuildContext context,
    MapEntry<String, ContactDetails> contact,
  ) {
    return DropdownMenuItem<String>(
      value: contact.key,
      child: ListTile(
        leading: HashiconWidget(hash: contact.key, size: Size.square(25)),
        title: Text(contact.value.name, style: context.bodyMedium),
        subtitle: Text(
          truncateText(contact.key, maxLength: 20),
          style: context.labelMedium?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
      ),
    );
  }
}
