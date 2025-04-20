import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_book_provider.g.dart';

@riverpod
class AddressBook extends _$AddressBook {
  @override
  Future<Map<String, ContactDetails>> build() async {
    final nativeWallet = ref.read(walletStateProvider).nativeWalletRepository;
    if (nativeWallet != null) {
      AddressBookData addressBook;
      final searchText = ref.watch(searchQueryProvider);
      if (searchText.isNotEmpty) {
        addressBook = await nativeWallet.findContactsByName(searchText);
      } else {
        addressBook = await nativeWallet.retrieveAllContacts();
      }
      return addressBook.contacts;
    }
    return {};
  }

  Future<ContactDetails?> get(String address) async {
    final nativeWallet = ref.read(walletStateProvider).nativeWalletRepository;
    if (nativeWallet != null) {
      final contact = await nativeWallet.getContact(address);
      return contact;
    }
    return null;
  }

  Future<void> upsert(String address, String name, String? note) async {
    final nativeWallet = ref.read(walletStateProvider).nativeWalletRepository;
    if (nativeWallet != null) {
      await nativeWallet.upsertContact(name: name, address: address);
      ref.invalidateSelf();
    }
  }

  Future<void> remove(String address) async {
    final nativeWallet = ref.read(walletStateProvider).nativeWalletRepository;
    if (nativeWallet != null) {
      await nativeWallet.removeContact(address);
      ref.invalidateSelf();
    }
  }

  Future<bool> exists(String address) async {
    final nativeWallet = ref.read(walletStateProvider).nativeWalletRepository;
    if (nativeWallet != null) {
      return await nativeWallet.isContactPresent(address);
    }
    return false;
  }
}
