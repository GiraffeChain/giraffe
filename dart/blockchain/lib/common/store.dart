import 'dart:io';
import 'dart:typed_data';

import 'package:blockchain/common/resource.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:hive/hive.dart';

abstract class Store<Key, T> {
  Future<T?> get(Key id);
  Future<bool> contains(Key id);
  Future<void> put(Key id, T value);
  Future<void> remove(Key id);

  Future<T> getOrRaise(Key id) async {
    final maybeValue = await get(id);
    ArgumentError.checkNotNull(maybeValue, "id=$id");
    return maybeValue!;
  }
}

class InMemoryStore<Key, Value> extends Store<Key, Value> {
  Map<Key, Value> _entries = {};

  @override
  Future<bool> contains(Key id) => Future.sync(() => _entries.containsKey(id));

  @override
  Future<Value?> get(Key id) => Future.sync(() => _entries[id]);

  @override
  Future<void> put(Key id, Value value) =>
      Future.sync(() => _entries[id] = value);

  @override
  Future<void> remove(Key id) => Future.sync(() => _entries.remove(id));
}

typedef ByteEncoder<T> = Uint8List Function(T);
typedef ByteDecoder<T> = T Function(Uint8List);

class HiveStore<Key, Value> extends Store<Key, Value> {
  final Box<Uint8List> hiveBox;
  final ByteEncoder<Key> encodeKey;
  final ByteEncoder<Value> encodeValue;
  final ByteDecoder<Key> decodeKey;
  final ByteDecoder<Value> decodeValue;

  HiveStore(
      {required this.hiveBox,
      required this.encodeKey,
      required this.encodeValue,
      required this.decodeKey,
      required this.decodeValue});

  static Resource<HiveInterface> makeHive(Directory directory) =>
      Resource.make(() async => Hive..init(directory.path), (h) => h.close());

  static Resource<HiveStore<Key, Value>> make<Key, Value>(
    String name,
    HiveInterface hive,
    ByteEncoder<Key> encodeKey,
    ByteEncoder<Value> encodeValue,
    ByteDecoder<Key> decodeKey,
    ByteDecoder<Value> decodeValue,
  ) =>
      Resource.make(() => hive.openBox<Uint8List>(name), (_) async {}).map(
          (box) => HiveStore(
              hiveBox: box,
              encodeKey: encodeKey,
              encodeValue: encodeValue,
              decodeKey: decodeKey,
              decodeValue: decodeValue));

  @override
  Future<bool> contains(Key id) async =>
      hiveBox.containsKey(_encodeStringKey(id));

  @override
  Future<Value?> get(Key id) async {
    final bytes = hiveBox.get(_encodeStringKey(id));
    if (bytes != null) return decodeValue(bytes);
    return null;
  }

  @override
  Future<void> put(Key id, Value value) async {
    await hiveBox.put(_encodeStringKey(id), encodeValue(value));
  }

  @override
  Future<void> remove(Key id) async {
    await hiveBox.delete(_encodeStringKey(id));
  }

  _encodeStringKey(Key id) => Base58Encode(encodeKey(id));
}
