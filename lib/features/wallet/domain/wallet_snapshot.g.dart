// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_snapshot.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWalletSnapshotCollection on Isar {
  IsarCollection<WalletSnapshot> get walletSnapshots => this.collection();
}

const WalletSnapshotSchema = CollectionSchema(
  name: r'WalletSnapshot',
  id: -7886821384830548354,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'addressBook': PropertySchema(
      id: 1,
      name: r'addressBook',
      type: IsarType.objectList,
      target: r'AddressBookEntry',
    ),
    r'encryptedSeed': PropertySchema(
      id: 2,
      name: r'encryptedSeed',
      type: IsarType.longList,
    ),
    r'imported': PropertySchema(
      id: 3,
      name: r'imported',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'network': PropertySchema(
      id: 5,
      name: r'network',
      type: IsarType.string,
    ),
    r'nonce': PropertySchema(
      id: 6,
      name: r'nonce',
      type: IsarType.long,
    ),
    r'syncedTopoHeight': PropertySchema(
      id: 7,
      name: r'syncedTopoHeight',
      type: IsarType.long,
    )
  },
  estimateSize: _walletSnapshotEstimateSize,
  serialize: _walletSnapshotSerialize,
  deserialize: _walletSnapshotDeserialize,
  deserializeProp: _walletSnapshotDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'assets': LinkSchema(
      id: 3323469718844893203,
      name: r'assets',
      target: r'AssetEntry',
      single: false,
    ),
    r'history': LinkSchema(
      id: -6295447531051595037,
      name: r'history',
      target: r'TransactionEntry',
      single: false,
    )
  },
  embeddedSchemas: {r'AddressBookEntry': AddressBookEntrySchema},
  getId: _walletSnapshotGetId,
  getLinks: _walletSnapshotGetLinks,
  attach: _walletSnapshotAttach,
  version: '3.1.0+1',
);

int _walletSnapshotEstimateSize(
  WalletSnapshot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.address;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.addressBook.length * 3;
  {
    final offsets = allOffsets[AddressBookEntry]!;
    for (var i = 0; i < object.addressBook.length; i++) {
      final value = object.addressBook[i];
      bytesCount +=
          AddressBookEntrySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.encryptedSeed;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.network;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _walletSnapshotSerialize(
  WalletSnapshot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeObjectList<AddressBookEntry>(
    offsets[1],
    allOffsets,
    AddressBookEntrySchema.serialize,
    object.addressBook,
  );
  writer.writeLongList(offsets[2], object.encryptedSeed);
  writer.writeBool(offsets[3], object.imported);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.network);
  writer.writeLong(offsets[6], object.nonce);
  writer.writeLong(offsets[7], object.syncedTopoHeight);
}

WalletSnapshot _walletSnapshotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WalletSnapshot();
  object.address = reader.readStringOrNull(offsets[0]);
  object.addressBook = reader.readObjectList<AddressBookEntry>(
        offsets[1],
        AddressBookEntrySchema.deserialize,
        allOffsets,
        AddressBookEntry(),
      ) ??
      [];
  object.encryptedSeed = reader.readLongList(offsets[2]);
  object.id = id;
  object.imported = reader.readBool(offsets[3]);
  object.name = reader.readStringOrNull(offsets[4]);
  object.network = reader.readStringOrNull(offsets[5]);
  object.nonce = reader.readLongOrNull(offsets[6]);
  object.syncedTopoHeight = reader.readLongOrNull(offsets[7]);
  return object;
}

P _walletSnapshotDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readObjectList<AddressBookEntry>(
            offset,
            AddressBookEntrySchema.deserialize,
            allOffsets,
            AddressBookEntry(),
          ) ??
          []) as P;
    case 2:
      return (reader.readLongList(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _walletSnapshotGetId(WalletSnapshot object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _walletSnapshotGetLinks(WalletSnapshot object) {
  return [object.assets, object.history];
}

void _walletSnapshotAttach(
    IsarCollection<dynamic> col, Id id, WalletSnapshot object) {
  object.id = id;
  object.assets.attach(col, col.isar.collection<AssetEntry>(), r'assets', id);
  object.history
      .attach(col, col.isar.collection<TransactionEntry>(), r'history', id);
}

extension WalletSnapshotByIndex on IsarCollection<WalletSnapshot> {
  Future<WalletSnapshot?> getByName(String? name) {
    return getByIndex(r'name', [name]);
  }

  WalletSnapshot? getByNameSync(String? name) {
    return getByIndexSync(r'name', [name]);
  }

  Future<bool> deleteByName(String? name) {
    return deleteByIndex(r'name', [name]);
  }

  bool deleteByNameSync(String? name) {
    return deleteByIndexSync(r'name', [name]);
  }

  Future<List<WalletSnapshot?>> getAllByName(List<String?> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndex(r'name', values);
  }

  List<WalletSnapshot?> getAllByNameSync(List<String?> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'name', values);
  }

  Future<int> deleteAllByName(List<String?> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'name', values);
  }

  int deleteAllByNameSync(List<String?> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'name', values);
  }

  Future<Id> putByName(WalletSnapshot object) {
    return putByIndex(r'name', object);
  }

  Id putByNameSync(WalletSnapshot object, {bool saveLinks = true}) {
    return putByIndexSync(r'name', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByName(List<WalletSnapshot> objects) {
    return putAllByIndex(r'name', objects);
  }

  List<Id> putAllByNameSync(List<WalletSnapshot> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'name', objects, saveLinks: saveLinks);
  }
}

extension WalletSnapshotQueryWhereSort
    on QueryBuilder<WalletSnapshot, WalletSnapshot, QWhere> {
  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WalletSnapshotQueryWhere
    on QueryBuilder<WalletSnapshot, WalletSnapshot, QWhereClause> {
  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterWhereClause> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [null],
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterWhereClause>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'name',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterWhereClause> nameEqualTo(
      String? name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterWhereClause>
      nameNotEqualTo(String? name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }
}

extension WalletSnapshotQueryFilter
    on QueryBuilder<WalletSnapshot, WalletSnapshot, QFilterCondition> {
  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'address',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'address',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressBookLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addressBook',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressBookIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addressBook',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressBookIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addressBook',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressBookLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addressBook',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressBookLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addressBook',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressBookLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'addressBook',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'encryptedSeed',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'encryptedSeed',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'encryptedSeed',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'encryptedSeed',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'encryptedSeed',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'encryptedSeed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedSeed',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedSeed',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedSeed',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedSeed',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedSeed',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      encryptedSeedLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedSeed',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      importedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imported',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'network',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'network',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'network',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'network',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'network',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'network',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      networkIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'network',
        value: '',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nonceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nonce',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nonceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nonce',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nonceEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nonce',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nonceGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nonce',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nonceLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nonce',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      nonceBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nonce',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      syncedTopoHeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'syncedTopoHeight',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      syncedTopoHeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'syncedTopoHeight',
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      syncedTopoHeightEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedTopoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      syncedTopoHeightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncedTopoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      syncedTopoHeightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncedTopoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      syncedTopoHeightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncedTopoHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WalletSnapshotQueryObject
    on QueryBuilder<WalletSnapshot, WalletSnapshot, QFilterCondition> {
  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      addressBookElement(FilterQuery<AddressBookEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'addressBook');
    });
  }
}

extension WalletSnapshotQueryLinks
    on QueryBuilder<WalletSnapshot, WalletSnapshot, QFilterCondition> {
  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition> assets(
      FilterQuery<AssetEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'assets');
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      assetsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'assets', length, true, length, true);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      assetsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'assets', 0, true, 0, true);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      assetsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'assets', 0, false, 999999, true);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      assetsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'assets', 0, true, length, include);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      assetsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'assets', length, include, 999999, true);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      assetsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'assets', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition> history(
      FilterQuery<TransactionEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'history');
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      historyLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'history', length, true, length, true);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      historyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'history', 0, true, 0, true);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      historyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'history', 0, false, 999999, true);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      historyLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'history', 0, true, length, include);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      historyLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'history', length, include, 999999, true);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterFilterCondition>
      historyLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'history', lower, includeLower, upper, includeUpper);
    });
  }
}

extension WalletSnapshotQuerySortBy
    on QueryBuilder<WalletSnapshot, WalletSnapshot, QSortBy> {
  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy>
      sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> sortByImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imported', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy>
      sortByImportedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imported', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> sortByNetwork() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'network', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy>
      sortByNetworkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'network', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> sortByNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nonce', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> sortByNonceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nonce', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy>
      sortBySyncedTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedTopoHeight', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy>
      sortBySyncedTopoHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedTopoHeight', Sort.desc);
    });
  }
}

extension WalletSnapshotQuerySortThenBy
    on QueryBuilder<WalletSnapshot, WalletSnapshot, QSortThenBy> {
  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy>
      thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> thenByImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imported', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy>
      thenByImportedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imported', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> thenByNetwork() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'network', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy>
      thenByNetworkDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'network', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> thenByNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nonce', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy> thenByNonceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nonce', Sort.desc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy>
      thenBySyncedTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedTopoHeight', Sort.asc);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QAfterSortBy>
      thenBySyncedTopoHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedTopoHeight', Sort.desc);
    });
  }
}

extension WalletSnapshotQueryWhereDistinct
    on QueryBuilder<WalletSnapshot, WalletSnapshot, QDistinct> {
  QueryBuilder<WalletSnapshot, WalletSnapshot, QDistinct> distinctByAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QDistinct>
      distinctByEncryptedSeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'encryptedSeed');
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QDistinct> distinctByImported() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imported');
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QDistinct> distinctByNetwork(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'network', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QDistinct> distinctByNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nonce');
    });
  }

  QueryBuilder<WalletSnapshot, WalletSnapshot, QDistinct>
      distinctBySyncedTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedTopoHeight');
    });
  }
}

extension WalletSnapshotQueryProperty
    on QueryBuilder<WalletSnapshot, WalletSnapshot, QQueryProperty> {
  QueryBuilder<WalletSnapshot, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WalletSnapshot, String?, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<WalletSnapshot, List<AddressBookEntry>, QQueryOperations>
      addressBookProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addressBook');
    });
  }

  QueryBuilder<WalletSnapshot, List<int>?, QQueryOperations>
      encryptedSeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'encryptedSeed');
    });
  }

  QueryBuilder<WalletSnapshot, bool, QQueryOperations> importedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imported');
    });
  }

  QueryBuilder<WalletSnapshot, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<WalletSnapshot, String?, QQueryOperations> networkProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'network');
    });
  }

  QueryBuilder<WalletSnapshot, int?, QQueryOperations> nonceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nonce');
    });
  }

  QueryBuilder<WalletSnapshot, int?, QQueryOperations>
      syncedTopoHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedTopoHeight');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAssetEntryCollection on Isar {
  IsarCollection<AssetEntry> get assetEntrys => this.collection();
}

const AssetEntrySchema = CollectionSchema(
  name: r'AssetEntry',
  id: -7671908208671073793,
  properties: {
    r'firstBalanceTopoHeight': PropertySchema(
      id: 0,
      name: r'firstBalanceTopoHeight',
      type: IsarType.long,
    ),
    r'hash': PropertySchema(
      id: 1,
      name: r'hash',
      type: IsarType.string,
    ),
    r'lastBalanceTopoHeight': PropertySchema(
      id: 2,
      name: r'lastBalanceTopoHeight',
      type: IsarType.long,
    ),
    r'syncedSinceBeginning': PropertySchema(
      id: 3,
      name: r'syncedSinceBeginning',
      type: IsarType.bool,
    )
  },
  estimateSize: _assetEntryEstimateSize,
  serialize: _assetEntrySerialize,
  deserialize: _assetEntryDeserialize,
  deserializeProp: _assetEntryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'wallet': LinkSchema(
      id: 1918064206359389270,
      name: r'wallet',
      target: r'WalletSnapshot',
      single: true,
      linkName: r'assets',
    ),
    r'balance': LinkSchema(
      id: 922365573907450031,
      name: r'balance',
      target: r'VersionedBalance',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _assetEntryGetId,
  getLinks: _assetEntryGetLinks,
  attach: _assetEntryAttach,
  version: '3.1.0+1',
);

int _assetEntryEstimateSize(
  AssetEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.hash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _assetEntrySerialize(
  AssetEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.firstBalanceTopoHeight);
  writer.writeString(offsets[1], object.hash);
  writer.writeLong(offsets[2], object.lastBalanceTopoHeight);
  writer.writeBool(offsets[3], object.syncedSinceBeginning);
}

AssetEntry _assetEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AssetEntry();
  object.firstBalanceTopoHeight = reader.readLongOrNull(offsets[0]);
  object.hash = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.lastBalanceTopoHeight = reader.readLongOrNull(offsets[2]);
  object.syncedSinceBeginning = reader.readBool(offsets[3]);
  return object;
}

P _assetEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _assetEntryGetId(AssetEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _assetEntryGetLinks(AssetEntry object) {
  return [object.wallet, object.balance];
}

void _assetEntryAttach(IsarCollection<dynamic> col, Id id, AssetEntry object) {
  object.id = id;
  object.wallet
      .attach(col, col.isar.collection<WalletSnapshot>(), r'wallet', id);
  object.balance
      .attach(col, col.isar.collection<VersionedBalance>(), r'balance', id);
}

extension AssetEntryQueryWhereSort
    on QueryBuilder<AssetEntry, AssetEntry, QWhere> {
  QueryBuilder<AssetEntry, AssetEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AssetEntryQueryWhere
    on QueryBuilder<AssetEntry, AssetEntry, QWhereClause> {
  QueryBuilder<AssetEntry, AssetEntry, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AssetEntryQueryFilter
    on QueryBuilder<AssetEntry, AssetEntry, QFilterCondition> {
  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      firstBalanceTopoHeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'firstBalanceTopoHeight',
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      firstBalanceTopoHeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'firstBalanceTopoHeight',
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      firstBalanceTopoHeightEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firstBalanceTopoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      firstBalanceTopoHeightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firstBalanceTopoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      firstBalanceTopoHeightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firstBalanceTopoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      firstBalanceTopoHeightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firstBalanceTopoHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hash',
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hash',
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hash',
        value: '',
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> hashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hash',
        value: '',
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      lastBalanceTopoHeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastBalanceTopoHeight',
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      lastBalanceTopoHeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastBalanceTopoHeight',
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      lastBalanceTopoHeightEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastBalanceTopoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      lastBalanceTopoHeightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastBalanceTopoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      lastBalanceTopoHeightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastBalanceTopoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      lastBalanceTopoHeightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastBalanceTopoHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      syncedSinceBeginningEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncedSinceBeginning',
        value: value,
      ));
    });
  }
}

extension AssetEntryQueryObject
    on QueryBuilder<AssetEntry, AssetEntry, QFilterCondition> {}

extension AssetEntryQueryLinks
    on QueryBuilder<AssetEntry, AssetEntry, QFilterCondition> {
  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> wallet(
      FilterQuery<WalletSnapshot> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'wallet');
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> walletIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'wallet', 0, true, 0, true);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> balance(
      FilterQuery<VersionedBalance> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'balance');
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      balanceLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'balance', length, true, length, true);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition> balanceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'balance', 0, true, 0, true);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      balanceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'balance', 0, false, 999999, true);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      balanceLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'balance', 0, true, length, include);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      balanceLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'balance', length, include, 999999, true);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterFilterCondition>
      balanceLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'balance', lower, includeLower, upper, includeUpper);
    });
  }
}

extension AssetEntryQuerySortBy
    on QueryBuilder<AssetEntry, AssetEntry, QSortBy> {
  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      sortByFirstBalanceTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstBalanceTopoHeight', Sort.asc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      sortByFirstBalanceTopoHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstBalanceTopoHeight', Sort.desc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy> sortByHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.asc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy> sortByHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.desc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      sortByLastBalanceTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastBalanceTopoHeight', Sort.asc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      sortByLastBalanceTopoHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastBalanceTopoHeight', Sort.desc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      sortBySyncedSinceBeginning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedSinceBeginning', Sort.asc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      sortBySyncedSinceBeginningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedSinceBeginning', Sort.desc);
    });
  }
}

extension AssetEntryQuerySortThenBy
    on QueryBuilder<AssetEntry, AssetEntry, QSortThenBy> {
  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      thenByFirstBalanceTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstBalanceTopoHeight', Sort.asc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      thenByFirstBalanceTopoHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstBalanceTopoHeight', Sort.desc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy> thenByHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.asc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy> thenByHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.desc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      thenByLastBalanceTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastBalanceTopoHeight', Sort.asc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      thenByLastBalanceTopoHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastBalanceTopoHeight', Sort.desc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      thenBySyncedSinceBeginning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedSinceBeginning', Sort.asc);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QAfterSortBy>
      thenBySyncedSinceBeginningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedSinceBeginning', Sort.desc);
    });
  }
}

extension AssetEntryQueryWhereDistinct
    on QueryBuilder<AssetEntry, AssetEntry, QDistinct> {
  QueryBuilder<AssetEntry, AssetEntry, QDistinct>
      distinctByFirstBalanceTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstBalanceTopoHeight');
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QDistinct> distinctByHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QDistinct>
      distinctByLastBalanceTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastBalanceTopoHeight');
    });
  }

  QueryBuilder<AssetEntry, AssetEntry, QDistinct>
      distinctBySyncedSinceBeginning() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedSinceBeginning');
    });
  }
}

extension AssetEntryQueryProperty
    on QueryBuilder<AssetEntry, AssetEntry, QQueryProperty> {
  QueryBuilder<AssetEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AssetEntry, int?, QQueryOperations>
      firstBalanceTopoHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstBalanceTopoHeight');
    });
  }

  QueryBuilder<AssetEntry, String?, QQueryOperations> hashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hash');
    });
  }

  QueryBuilder<AssetEntry, int?, QQueryOperations>
      lastBalanceTopoHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastBalanceTopoHeight');
    });
  }

  QueryBuilder<AssetEntry, bool, QQueryOperations>
      syncedSinceBeginningProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedSinceBeginning');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVersionedBalanceCollection on Isar {
  IsarCollection<VersionedBalance> get versionedBalances => this.collection();
}

const VersionedBalanceSchema = CollectionSchema(
  name: r'VersionedBalance',
  id: -4069813487097541064,
  properties: {
    r'balance': PropertySchema(
      id: 0,
      name: r'balance',
      type: IsarType.long,
    ),
    r'topoHeight': PropertySchema(
      id: 1,
      name: r'topoHeight',
      type: IsarType.long,
    )
  },
  estimateSize: _versionedBalanceEstimateSize,
  serialize: _versionedBalanceSerialize,
  deserialize: _versionedBalanceDeserialize,
  deserializeProp: _versionedBalanceDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'asset': LinkSchema(
      id: 6459979686315884116,
      name: r'asset',
      target: r'AssetEntry',
      single: true,
      linkName: r'balance',
    )
  },
  embeddedSchemas: {},
  getId: _versionedBalanceGetId,
  getLinks: _versionedBalanceGetLinks,
  attach: _versionedBalanceAttach,
  version: '3.1.0+1',
);

int _versionedBalanceEstimateSize(
  VersionedBalance object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _versionedBalanceSerialize(
  VersionedBalance object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.balance);
  writer.writeLong(offsets[1], object.topoHeight);
}

VersionedBalance _versionedBalanceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = VersionedBalance();
  object.balance = reader.readLongOrNull(offsets[0]);
  object.id = id;
  object.topoHeight = reader.readLongOrNull(offsets[1]);
  return object;
}

P _versionedBalanceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _versionedBalanceGetId(VersionedBalance object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _versionedBalanceGetLinks(VersionedBalance object) {
  return [object.asset];
}

void _versionedBalanceAttach(
    IsarCollection<dynamic> col, Id id, VersionedBalance object) {
  object.id = id;
  object.asset.attach(col, col.isar.collection<AssetEntry>(), r'asset', id);
}

extension VersionedBalanceQueryWhereSort
    on QueryBuilder<VersionedBalance, VersionedBalance, QWhere> {
  QueryBuilder<VersionedBalance, VersionedBalance, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension VersionedBalanceQueryWhere
    on QueryBuilder<VersionedBalance, VersionedBalance, QWhereClause> {
  QueryBuilder<VersionedBalance, VersionedBalance, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VersionedBalanceQueryFilter
    on QueryBuilder<VersionedBalance, VersionedBalance, QFilterCondition> {
  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      balanceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'balance',
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      balanceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'balance',
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      balanceEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'balance',
        value: value,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      balanceGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'balance',
        value: value,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      balanceLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'balance',
        value: value,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      balanceBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'balance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      topoHeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'topoHeight',
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      topoHeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'topoHeight',
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      topoHeightEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      topoHeightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      topoHeightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      topoHeightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topoHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VersionedBalanceQueryObject
    on QueryBuilder<VersionedBalance, VersionedBalance, QFilterCondition> {}

extension VersionedBalanceQueryLinks
    on QueryBuilder<VersionedBalance, VersionedBalance, QFilterCondition> {
  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition> asset(
      FilterQuery<AssetEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'asset');
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterFilterCondition>
      assetIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'asset', 0, true, 0, true);
    });
  }
}

extension VersionedBalanceQuerySortBy
    on QueryBuilder<VersionedBalance, VersionedBalance, QSortBy> {
  QueryBuilder<VersionedBalance, VersionedBalance, QAfterSortBy>
      sortByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterSortBy>
      sortByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterSortBy>
      sortByTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topoHeight', Sort.asc);
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterSortBy>
      sortByTopoHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topoHeight', Sort.desc);
    });
  }
}

extension VersionedBalanceQuerySortThenBy
    on QueryBuilder<VersionedBalance, VersionedBalance, QSortThenBy> {
  QueryBuilder<VersionedBalance, VersionedBalance, QAfterSortBy>
      thenByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterSortBy>
      thenByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterSortBy>
      thenByTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topoHeight', Sort.asc);
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QAfterSortBy>
      thenByTopoHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topoHeight', Sort.desc);
    });
  }
}

extension VersionedBalanceQueryWhereDistinct
    on QueryBuilder<VersionedBalance, VersionedBalance, QDistinct> {
  QueryBuilder<VersionedBalance, VersionedBalance, QDistinct>
      distinctByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balance');
    });
  }

  QueryBuilder<VersionedBalance, VersionedBalance, QDistinct>
      distinctByTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topoHeight');
    });
  }
}

extension VersionedBalanceQueryProperty
    on QueryBuilder<VersionedBalance, VersionedBalance, QQueryProperty> {
  QueryBuilder<VersionedBalance, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<VersionedBalance, int?, QQueryOperations> balanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balance');
    });
  }

  QueryBuilder<VersionedBalance, int?, QQueryOperations> topoHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topoHeight');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTransactionEntryCollection on Isar {
  IsarCollection<TransactionEntry> get transactionEntrys => this.collection();
}

const TransactionEntrySchema = CollectionSchema(
  name: r'TransactionEntry',
  id: 3658412474511599670,
  properties: {
    r'entryData': PropertySchema(
      id: 0,
      name: r'entryData',
      type: IsarType.object,
      target: r'EntryData',
    ),
    r'executedInBlock': PropertySchema(
      id: 1,
      name: r'executedInBlock',
      type: IsarType.string,
    ),
    r'fees': PropertySchema(
      id: 2,
      name: r'fees',
      type: IsarType.long,
    ),
    r'hash': PropertySchema(
      id: 3,
      name: r'hash',
      type: IsarType.string,
    ),
    r'nonce': PropertySchema(
      id: 4,
      name: r'nonce',
      type: IsarType.long,
    ),
    r'owner': PropertySchema(
      id: 5,
      name: r'owner',
      type: IsarType.string,
    ),
    r'signature': PropertySchema(
      id: 6,
      name: r'signature',
      type: IsarType.string,
    ),
    r'topoHeight': PropertySchema(
      id: 7,
      name: r'topoHeight',
      type: IsarType.long,
    )
  },
  estimateSize: _transactionEntryEstimateSize,
  serialize: _transactionEntrySerialize,
  deserialize: _transactionEntryDeserialize,
  deserializeProp: _transactionEntryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'wallet': LinkSchema(
      id: 4534860936490885035,
      name: r'wallet',
      target: r'WalletSnapshot',
      single: true,
      linkName: r'history',
    )
  },
  embeddedSchemas: {
    r'EntryData': EntryDataSchema,
    r'BurnEntry': BurnEntrySchema,
    r'OutgoingEntry': OutgoingEntrySchema,
    r'TransferEntry': TransferEntrySchema,
    r'IncomingEntry': IncomingEntrySchema
  },
  getId: _transactionEntryGetId,
  getLinks: _transactionEntryGetLinks,
  attach: _transactionEntryAttach,
  version: '3.1.0+1',
);

int _transactionEntryEstimateSize(
  TransactionEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.entryData;
    if (value != null) {
      bytesCount += 3 +
          EntryDataSchema.estimateSize(
              value, allOffsets[EntryData]!, allOffsets);
    }
  }
  {
    final value = object.executedInBlock;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.hash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.owner;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.signature;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _transactionEntrySerialize(
  TransactionEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObject<EntryData>(
    offsets[0],
    allOffsets,
    EntryDataSchema.serialize,
    object.entryData,
  );
  writer.writeString(offsets[1], object.executedInBlock);
  writer.writeLong(offsets[2], object.fees);
  writer.writeString(offsets[3], object.hash);
  writer.writeLong(offsets[4], object.nonce);
  writer.writeString(offsets[5], object.owner);
  writer.writeString(offsets[6], object.signature);
  writer.writeLong(offsets[7], object.topoHeight);
}

TransactionEntry _transactionEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TransactionEntry();
  object.entryData = reader.readObjectOrNull<EntryData>(
    offsets[0],
    EntryDataSchema.deserialize,
    allOffsets,
  );
  object.executedInBlock = reader.readStringOrNull(offsets[1]);
  object.fees = reader.readLongOrNull(offsets[2]);
  object.hash = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.nonce = reader.readLongOrNull(offsets[4]);
  object.owner = reader.readStringOrNull(offsets[5]);
  object.signature = reader.readStringOrNull(offsets[6]);
  object.topoHeight = reader.readLongOrNull(offsets[7]);
  return object;
}

P _transactionEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectOrNull<EntryData>(
        offset,
        EntryDataSchema.deserialize,
        allOffsets,
      )) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _transactionEntryGetId(TransactionEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _transactionEntryGetLinks(TransactionEntry object) {
  return [object.wallet];
}

void _transactionEntryAttach(
    IsarCollection<dynamic> col, Id id, TransactionEntry object) {
  object.id = id;
  object.wallet
      .attach(col, col.isar.collection<WalletSnapshot>(), r'wallet', id);
}

extension TransactionEntryQueryWhereSort
    on QueryBuilder<TransactionEntry, TransactionEntry, QWhere> {
  QueryBuilder<TransactionEntry, TransactionEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TransactionEntryQueryWhere
    on QueryBuilder<TransactionEntry, TransactionEntry, QWhereClause> {
  QueryBuilder<TransactionEntry, TransactionEntry, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TransactionEntryQueryFilter
    on QueryBuilder<TransactionEntry, TransactionEntry, QFilterCondition> {
  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      entryDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'entryData',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      entryDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'entryData',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'executedInBlock',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'executedInBlock',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'executedInBlock',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'executedInBlock',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'executedInBlock',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'executedInBlock',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'executedInBlock',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'executedInBlock',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'executedInBlock',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'executedInBlock',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'executedInBlock',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      executedInBlockIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'executedInBlock',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      feesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fees',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      feesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fees',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      feesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fees',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      feesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fees',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      feesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fees',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      feesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fees',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'hash',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'hash',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hash',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      hashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hash',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      nonceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nonce',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      nonceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nonce',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      nonceEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nonce',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      nonceGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nonce',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      nonceLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nonce',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      nonceBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nonce',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'owner',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'owner',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'owner',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'owner',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'owner',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      ownerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'owner',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'signature',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'signature',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'signature',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'signature',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'signature',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'signature',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'signature',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'signature',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'signature',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'signature',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'signature',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      signatureIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'signature',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      topoHeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'topoHeight',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      topoHeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'topoHeight',
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      topoHeightEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      topoHeightGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      topoHeightLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topoHeight',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      topoHeightBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topoHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TransactionEntryQueryObject
    on QueryBuilder<TransactionEntry, TransactionEntry, QFilterCondition> {
  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      entryData(FilterQuery<EntryData> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'entryData');
    });
  }
}

extension TransactionEntryQueryLinks
    on QueryBuilder<TransactionEntry, TransactionEntry, QFilterCondition> {
  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      wallet(FilterQuery<WalletSnapshot> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'wallet');
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterFilterCondition>
      walletIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'wallet', 0, true, 0, true);
    });
  }
}

extension TransactionEntryQuerySortBy
    on QueryBuilder<TransactionEntry, TransactionEntry, QSortBy> {
  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      sortByExecutedInBlock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedInBlock', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      sortByExecutedInBlockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedInBlock', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy> sortByFees() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fees', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      sortByFeesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fees', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy> sortByHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      sortByHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy> sortByNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nonce', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      sortByNonceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nonce', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy> sortByOwner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'owner', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      sortByOwnerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'owner', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      sortBySignature() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      sortBySignatureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      sortByTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topoHeight', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      sortByTopoHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topoHeight', Sort.desc);
    });
  }
}

extension TransactionEntryQuerySortThenBy
    on QueryBuilder<TransactionEntry, TransactionEntry, QSortThenBy> {
  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenByExecutedInBlock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedInBlock', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenByExecutedInBlockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'executedInBlock', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy> thenByFees() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fees', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenByFeesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fees', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy> thenByHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenByHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hash', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy> thenByNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nonce', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenByNonceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nonce', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy> thenByOwner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'owner', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenByOwnerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'owner', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenBySignature() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenBySignatureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'signature', Sort.desc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenByTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topoHeight', Sort.asc);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QAfterSortBy>
      thenByTopoHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topoHeight', Sort.desc);
    });
  }
}

extension TransactionEntryQueryWhereDistinct
    on QueryBuilder<TransactionEntry, TransactionEntry, QDistinct> {
  QueryBuilder<TransactionEntry, TransactionEntry, QDistinct>
      distinctByExecutedInBlock({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'executedInBlock',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QDistinct> distinctByFees() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fees');
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QDistinct> distinctByHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QDistinct>
      distinctByNonce() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nonce');
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QDistinct> distinctByOwner(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'owner', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QDistinct>
      distinctBySignature({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'signature', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionEntry, TransactionEntry, QDistinct>
      distinctByTopoHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topoHeight');
    });
  }
}

extension TransactionEntryQueryProperty
    on QueryBuilder<TransactionEntry, TransactionEntry, QQueryProperty> {
  QueryBuilder<TransactionEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TransactionEntry, EntryData?, QQueryOperations>
      entryDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryData');
    });
  }

  QueryBuilder<TransactionEntry, String?, QQueryOperations>
      executedInBlockProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'executedInBlock');
    });
  }

  QueryBuilder<TransactionEntry, int?, QQueryOperations> feesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fees');
    });
  }

  QueryBuilder<TransactionEntry, String?, QQueryOperations> hashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hash');
    });
  }

  QueryBuilder<TransactionEntry, int?, QQueryOperations> nonceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nonce');
    });
  }

  QueryBuilder<TransactionEntry, String?, QQueryOperations> ownerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'owner');
    });
  }

  QueryBuilder<TransactionEntry, String?, QQueryOperations>
      signatureProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'signature');
    });
  }

  QueryBuilder<TransactionEntry, int?, QQueryOperations> topoHeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topoHeight');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const EntryDataSchema = Schema(
  name: r'EntryData',
  id: -26512338089413282,
  properties: {
    r'burn': PropertySchema(
      id: 0,
      name: r'burn',
      type: IsarType.object,
      target: r'BurnEntry',
    ),
    r'coinbase': PropertySchema(
      id: 1,
      name: r'coinbase',
      type: IsarType.long,
    ),
    r'incoming': PropertySchema(
      id: 2,
      name: r'incoming',
      type: IsarType.object,
      target: r'IncomingEntry',
    ),
    r'outgoing': PropertySchema(
      id: 3,
      name: r'outgoing',
      type: IsarType.object,
      target: r'OutgoingEntry',
    )
  },
  estimateSize: _entryDataEstimateSize,
  serialize: _entryDataSerialize,
  deserialize: _entryDataDeserialize,
  deserializeProp: _entryDataDeserializeProp,
);

int _entryDataEstimateSize(
  EntryData object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.burn;
    if (value != null) {
      bytesCount += 3 +
          BurnEntrySchema.estimateSize(
              value, allOffsets[BurnEntry]!, allOffsets);
    }
  }
  {
    final value = object.incoming;
    if (value != null) {
      bytesCount += 3 +
          IncomingEntrySchema.estimateSize(
              value, allOffsets[IncomingEntry]!, allOffsets);
    }
  }
  {
    final value = object.outgoing;
    if (value != null) {
      bytesCount += 3 +
          OutgoingEntrySchema.estimateSize(
              value, allOffsets[OutgoingEntry]!, allOffsets);
    }
  }
  return bytesCount;
}

void _entryDataSerialize(
  EntryData object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObject<BurnEntry>(
    offsets[0],
    allOffsets,
    BurnEntrySchema.serialize,
    object.burn,
  );
  writer.writeLong(offsets[1], object.coinbase);
  writer.writeObject<IncomingEntry>(
    offsets[2],
    allOffsets,
    IncomingEntrySchema.serialize,
    object.incoming,
  );
  writer.writeObject<OutgoingEntry>(
    offsets[3],
    allOffsets,
    OutgoingEntrySchema.serialize,
    object.outgoing,
  );
}

EntryData _entryDataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EntryData();
  object.burn = reader.readObjectOrNull<BurnEntry>(
    offsets[0],
    BurnEntrySchema.deserialize,
    allOffsets,
  );
  object.coinbase = reader.readLongOrNull(offsets[1]);
  object.incoming = reader.readObjectOrNull<IncomingEntry>(
    offsets[2],
    IncomingEntrySchema.deserialize,
    allOffsets,
  );
  object.outgoing = reader.readObjectOrNull<OutgoingEntry>(
    offsets[3],
    OutgoingEntrySchema.deserialize,
    allOffsets,
  );
  return object;
}

P _entryDataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectOrNull<BurnEntry>(
        offset,
        BurnEntrySchema.deserialize,
        allOffsets,
      )) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readObjectOrNull<IncomingEntry>(
        offset,
        IncomingEntrySchema.deserialize,
        allOffsets,
      )) as P;
    case 3:
      return (reader.readObjectOrNull<OutgoingEntry>(
        offset,
        OutgoingEntrySchema.deserialize,
        allOffsets,
      )) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension EntryDataQueryFilter
    on QueryBuilder<EntryData, EntryData, QFilterCondition> {
  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> burnIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'burn',
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> burnIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'burn',
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> coinbaseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'coinbase',
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition>
      coinbaseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'coinbase',
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> coinbaseEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coinbase',
        value: value,
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> coinbaseGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'coinbase',
        value: value,
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> coinbaseLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'coinbase',
        value: value,
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> coinbaseBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'coinbase',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> incomingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'incoming',
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition>
      incomingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'incoming',
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> outgoingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'outgoing',
      ));
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition>
      outgoingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'outgoing',
      ));
    });
  }
}

extension EntryDataQueryObject
    on QueryBuilder<EntryData, EntryData, QFilterCondition> {
  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> burn(
      FilterQuery<BurnEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'burn');
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> incoming(
      FilterQuery<IncomingEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'incoming');
    });
  }

  QueryBuilder<EntryData, EntryData, QAfterFilterCondition> outgoing(
      FilterQuery<OutgoingEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'outgoing');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const BurnEntrySchema = Schema(
  name: r'BurnEntry',
  id: 4340283472929785394,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.long,
    ),
    r'asset': PropertySchema(
      id: 1,
      name: r'asset',
      type: IsarType.string,
    )
  },
  estimateSize: _burnEntryEstimateSize,
  serialize: _burnEntrySerialize,
  deserialize: _burnEntryDeserialize,
  deserializeProp: _burnEntryDeserializeProp,
);

int _burnEntryEstimateSize(
  BurnEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.asset;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _burnEntrySerialize(
  BurnEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.amount);
  writer.writeString(offsets[1], object.asset);
}

BurnEntry _burnEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BurnEntry();
  object.amount = reader.readLongOrNull(offsets[0]);
  object.asset = reader.readStringOrNull(offsets[1]);
  return object;
}

P _burnEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension BurnEntryQueryFilter
    on QueryBuilder<BurnEntry, BurnEntry, QFilterCondition> {
  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> amountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amount',
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> amountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amount',
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> amountEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> amountGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> amountLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> amountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'asset',
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'asset',
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'asset',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'asset',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'asset',
        value: '',
      ));
    });
  }

  QueryBuilder<BurnEntry, BurnEntry, QAfterFilterCondition> assetIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'asset',
        value: '',
      ));
    });
  }
}

extension BurnEntryQueryObject
    on QueryBuilder<BurnEntry, BurnEntry, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const IncomingEntrySchema = Schema(
  name: r'IncomingEntry',
  id: -4234348439191796294,
  properties: {
    r'owner': PropertySchema(
      id: 0,
      name: r'owner',
      type: IsarType.string,
    ),
    r'transfers': PropertySchema(
      id: 1,
      name: r'transfers',
      type: IsarType.objectList,
      target: r'TransferEntry',
    )
  },
  estimateSize: _incomingEntryEstimateSize,
  serialize: _incomingEntrySerialize,
  deserialize: _incomingEntryDeserialize,
  deserializeProp: _incomingEntryDeserializeProp,
);

int _incomingEntryEstimateSize(
  IncomingEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.owner;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.transfers.length * 3;
  {
    final offsets = allOffsets[TransferEntry]!;
    for (var i = 0; i < object.transfers.length; i++) {
      final value = object.transfers[i];
      bytesCount +=
          TransferEntrySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _incomingEntrySerialize(
  IncomingEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.owner);
  writer.writeObjectList<TransferEntry>(
    offsets[1],
    allOffsets,
    TransferEntrySchema.serialize,
    object.transfers,
  );
}

IncomingEntry _incomingEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IncomingEntry();
  object.owner = reader.readStringOrNull(offsets[0]);
  object.transfers = reader.readObjectList<TransferEntry>(
        offsets[1],
        TransferEntrySchema.deserialize,
        allOffsets,
        TransferEntry(),
      ) ??
      [];
  return object;
}

P _incomingEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readObjectList<TransferEntry>(
            offset,
            TransferEntrySchema.deserialize,
            allOffsets,
            TransferEntry(),
          ) ??
          []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension IncomingEntryQueryFilter
    on QueryBuilder<IncomingEntry, IncomingEntry, QFilterCondition> {
  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'owner',
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'owner',
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'owner',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'owner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'owner',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'owner',
        value: '',
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      ownerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'owner',
        value: '',
      ));
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      transfersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      transfersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      transfersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      transfersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      transfersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      transfersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension IncomingEntryQueryObject
    on QueryBuilder<IncomingEntry, IncomingEntry, QFilterCondition> {
  QueryBuilder<IncomingEntry, IncomingEntry, QAfterFilterCondition>
      transfersElement(FilterQuery<TransferEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'transfers');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const OutgoingEntrySchema = Schema(
  name: r'OutgoingEntry',
  id: 3615397774418416034,
  properties: {
    r'transfers': PropertySchema(
      id: 0,
      name: r'transfers',
      type: IsarType.objectList,
      target: r'TransferEntry',
    )
  },
  estimateSize: _outgoingEntryEstimateSize,
  serialize: _outgoingEntrySerialize,
  deserialize: _outgoingEntryDeserialize,
  deserializeProp: _outgoingEntryDeserializeProp,
);

int _outgoingEntryEstimateSize(
  OutgoingEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.transfers.length * 3;
  {
    final offsets = allOffsets[TransferEntry]!;
    for (var i = 0; i < object.transfers.length; i++) {
      final value = object.transfers[i];
      bytesCount +=
          TransferEntrySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _outgoingEntrySerialize(
  OutgoingEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<TransferEntry>(
    offsets[0],
    allOffsets,
    TransferEntrySchema.serialize,
    object.transfers,
  );
}

OutgoingEntry _outgoingEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OutgoingEntry();
  object.transfers = reader.readObjectList<TransferEntry>(
        offsets[0],
        TransferEntrySchema.deserialize,
        allOffsets,
        TransferEntry(),
      ) ??
      [];
  return object;
}

P _outgoingEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<TransferEntry>(
            offset,
            TransferEntrySchema.deserialize,
            allOffsets,
            TransferEntry(),
          ) ??
          []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension OutgoingEntryQueryFilter
    on QueryBuilder<OutgoingEntry, OutgoingEntry, QFilterCondition> {
  QueryBuilder<OutgoingEntry, OutgoingEntry, QAfterFilterCondition>
      transfersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OutgoingEntry, OutgoingEntry, QAfterFilterCondition>
      transfersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OutgoingEntry, OutgoingEntry, QAfterFilterCondition>
      transfersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutgoingEntry, OutgoingEntry, QAfterFilterCondition>
      transfersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OutgoingEntry, OutgoingEntry, QAfterFilterCondition>
      transfersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OutgoingEntry, OutgoingEntry, QAfterFilterCondition>
      transfersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transfers',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension OutgoingEntryQueryObject
    on QueryBuilder<OutgoingEntry, OutgoingEntry, QFilterCondition> {
  QueryBuilder<OutgoingEntry, OutgoingEntry, QAfterFilterCondition>
      transfersElement(FilterQuery<TransferEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'transfers');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const TransferEntrySchema = Schema(
  name: r'TransferEntry',
  id: -2509977995643997427,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.long,
    ),
    r'asset': PropertySchema(
      id: 1,
      name: r'asset',
      type: IsarType.string,
    ),
    r'extraData': PropertySchema(
      id: 2,
      name: r'extraData',
      type: IsarType.string,
    ),
    r'to': PropertySchema(
      id: 3,
      name: r'to',
      type: IsarType.string,
    )
  },
  estimateSize: _transferEntryEstimateSize,
  serialize: _transferEntrySerialize,
  deserialize: _transferEntryDeserialize,
  deserializeProp: _transferEntryDeserializeProp,
);

int _transferEntryEstimateSize(
  TransferEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.asset;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.extraData;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.to;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _transferEntrySerialize(
  TransferEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.amount);
  writer.writeString(offsets[1], object.asset);
  writer.writeString(offsets[2], object.extraData);
  writer.writeString(offsets[3], object.to);
}

TransferEntry _transferEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TransferEntry();
  object.amount = reader.readLongOrNull(offsets[0]);
  object.asset = reader.readStringOrNull(offsets[1]);
  object.extraData = reader.readStringOrNull(offsets[2]);
  object.to = reader.readStringOrNull(offsets[3]);
  return object;
}

P _transferEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension TransferEntryQueryFilter
    on QueryBuilder<TransferEntry, TransferEntry, QFilterCondition> {
  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      amountIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'amount',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      amountIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'amount',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      amountEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      amountGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      amountLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      amountBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'asset',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'asset',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'asset',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'asset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'asset',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'asset',
        value: '',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      assetIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'asset',
        value: '',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'extraData',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'extraData',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'extraData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'extraData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'extraData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'extraData',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'extraData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'extraData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'extraData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'extraData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'extraData',
        value: '',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      extraDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'extraData',
        value: '',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition> toIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'to',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      toIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'to',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition> toEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      toGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition> toLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition> toBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'to',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      toStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition> toEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition> toContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'to',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition> toMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'to',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      toIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'to',
        value: '',
      ));
    });
  }

  QueryBuilder<TransferEntry, TransferEntry, QAfterFilterCondition>
      toIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'to',
        value: '',
      ));
    });
  }
}

extension TransferEntryQueryObject
    on QueryBuilder<TransferEntry, TransferEntry, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const AddressBookEntrySchema = Schema(
  name: r'AddressBookEntry',
  id: -3413531389459964672,
  properties: {
    r'address': PropertySchema(
      id: 0,
      name: r'address',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    )
  },
  estimateSize: _addressBookEntryEstimateSize,
  serialize: _addressBookEntrySerialize,
  deserialize: _addressBookEntryDeserialize,
  deserializeProp: _addressBookEntryDeserializeProp,
);

int _addressBookEntryEstimateSize(
  AddressBookEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.address;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _addressBookEntrySerialize(
  AddressBookEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeString(offsets[1], object.name);
}

AddressBookEntry _addressBookEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AddressBookEntry();
  object.address = reader.readStringOrNull(offsets[0]);
  object.name = reader.readStringOrNull(offsets[1]);
  return object;
}

P _addressBookEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension AddressBookEntryQueryFilter
    on QueryBuilder<AddressBookEntry, AddressBookEntry, QFilterCondition> {
  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'address',
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'address',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'address',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'address',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'address',
        value: '',
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<AddressBookEntry, AddressBookEntry, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }
}

extension AddressBookEntryQueryObject
    on QueryBuilder<AddressBookEntry, AddressBookEntry, QFilterCondition> {}
