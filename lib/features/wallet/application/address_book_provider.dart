import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'address_book_provider.g.dart';

@riverpod
class AddressBook extends _$AddressBook {
  static const int pageSize = 50;
  int _currentPage = 0;
  Map<String, ContactDetails> _allContacts = {};
  bool _hasMore = true;

  @override
  Future<Map<String, ContactDetails>> build() async {
    _currentPage = 0;
    _allContacts = {};
    _hasMore = true;
    return loadMore();
  }

  Future<Map<String, ContactDetails>> loadMore() async {
    if (!_hasMore) return _allContacts;

    final nativeWallet = ref.read(walletStateProvider).nativeWalletRepository;
    if (nativeWallet != null) {
      final searchText = ref.read(searchQueryProvider);
      final skip = _currentPage * pageSize;

      AddressBookData addressBook;
      if (searchText.isNotEmpty) {
        addressBook = await nativeWallet.findContactsByName(
          searchText,
          skip: skip,
          take: pageSize,
        );
      } else {
        addressBook = await nativeWallet.retrieveContacts(
          skip: skip,
          take: pageSize,
        );
      }

      if (addressBook.contacts.length < pageSize) {
        _hasMore = false;
      }

      _allContacts.addAll(addressBook.contacts);
      _currentPage++;
      state = AsyncData(_allContacts);
      return _allContacts;
    }
    return {};
  }

  bool get hasMore => _hasMore;

  void reset() {
    _currentPage = 0;
    _allContacts = {};
    _hasMore = true;
    ref.invalidateSelf();
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
      reset();
    }
  }

  Future<void> remove(String address) async {
    final nativeWallet = ref.read(walletStateProvider).nativeWalletRepository;
    if (nativeWallet != null) {
      await nativeWallet.removeContact(address);
      reset();
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
