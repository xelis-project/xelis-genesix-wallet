import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/storage/secure_storage/secure_storage_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_provider.g.dart';

@riverpod
SecureStorageRepository secureStorage(Ref ref) {
  return SecureStorageRepository();
}
