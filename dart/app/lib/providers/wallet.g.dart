// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$podWalletHash() => r'f6ba1174a633ed8b161fbcec4620a62bc0543df8';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$PodWallet extends BuildlessAutoDisposeStreamNotifier<Wallet> {
  late final BlockchainView view;

  Stream<Wallet> build(
    BlockchainView view,
  );
}

/// See also [PodWallet].
@ProviderFor(PodWallet)
const podWalletProvider = PodWalletFamily();

/// See also [PodWallet].
class PodWalletFamily extends Family<AsyncValue<Wallet>> {
  /// See also [PodWallet].
  const PodWalletFamily();

  /// See also [PodWallet].
  PodWalletProvider call(
    BlockchainView view,
  ) {
    return PodWalletProvider(
      view,
    );
  }

  @override
  PodWalletProvider getProviderOverride(
    covariant PodWalletProvider provider,
  ) {
    return call(
      provider.view,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'podWalletProvider';
}

/// See also [PodWallet].
class PodWalletProvider
    extends AutoDisposeStreamNotifierProviderImpl<PodWallet, Wallet> {
  /// See also [PodWallet].
  PodWalletProvider(
    BlockchainView view,
  ) : this._internal(
          () => PodWallet()..view = view,
          from: podWalletProvider,
          name: r'podWalletProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$podWalletHash,
          dependencies: PodWalletFamily._dependencies,
          allTransitiveDependencies: PodWalletFamily._allTransitiveDependencies,
          view: view,
        );

  PodWalletProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.view,
  }) : super.internal();

  final BlockchainView view;

  @override
  Stream<Wallet> runNotifierBuild(
    covariant PodWallet notifier,
  ) {
    return notifier.build(
      view,
    );
  }

  @override
  Override overrideWith(PodWallet Function() create) {
    return ProviderOverride(
      origin: this,
      override: PodWalletProvider._internal(
        () => create()..view = view,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        view: view,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<PodWallet, Wallet> createElement() {
    return _PodWalletProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PodWalletProvider && other.view == view;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, view.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PodWalletRef on AutoDisposeStreamNotifierProviderRef<Wallet> {
  /// The parameter `view` of this provider.
  BlockchainView get view;
}

class _PodWalletProviderElement
    extends AutoDisposeStreamNotifierProviderElement<PodWallet, Wallet>
    with PodWalletRef {
  _PodWalletProviderElement(super.provider);

  @override
  BlockchainView get view => (origin as PodWalletProvider).view;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
