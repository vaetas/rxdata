import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

import '/src/data.dart';

/// Delegates fetching and caching behavior of specified [Data] object.
///
/// If you provide [toStorage] or [toMemory] then you must also
/// provide [onClearCache].
///
/// If [toStorage] or [toMemory] throws then [onClearCache] is called.
class DataDelegate<V> extends StateNotifier<Data<V>> {
  DataDelegate({
    required this.fromNetwork,
    this.fromMemory,
    this.toMemory,
    this.fromStorage,
    this.toStorage,
    this.onClearCache,
  })  : assert(
          (toStorage == null && toMemory == null) ||
              (toStorage != null || toMemory != null) && onClearCache != null,
          'You must provide `onClearCache` callback when using `toStorage` and/or `toMemory`.',
        ),
        super(Data<V>(isLoading: true)) {
    _init();
  }

  /// HTTP request to obtain data from your API
  @protected
  final FromNetworkCallback<V> fromNetwork;

  /// Load cached data from memory. This cannot be async.
  @protected
  final FromMemoryCallback<V>? fromMemory;

  /// Save data into memory cache.
  @protected
  final ToMemoryCallback<V>? toMemory;

  /// Load data from storage. This could be SQLite, shared_preferences etc.
  @protected
  final FromStorageCallback<V>? fromStorage;

  /// Persist data into storage.
  @protected
  final ToStorageCallback<V>? toStorage;

  /// Define how to clear memory & storage cache.
  @protected
  final ClearCacheCallback? onClearCache;

  bool _isLocked = false;

  /// Whether there already is ongoing network request. Only one request is
  /// allowed at the time.
  bool get isLocked => _isLocked;

  /// [DateTime] of last [fromNetwork] call. This will be updated when
  /// [fromNetwork] call either succeeds or fails. You can use this value to
  /// decide if you need to refresh your data.
  ///
  /// [lastUpdated] is NOT updated after [fromStorage] or [fromMemory].
  ///
  /// Null [lastUpdated] means there was not a successful [fromNetwork] call
  /// already.
  DateTime? get lastUpdated => _lastUpdated;

  DateTime? _lastUpdated;

  StreamSubscription<V>? _fetchSubscription;

  Future<void> _init() async {
    try {
      final memoryValue = fromMemory?.call();
      if (memoryValue != null) {
        state = Data(value: memoryValue);
      } else {
        await _loadFromStorage();
      }
    } catch (e, s) {
      _handleError(e, s);
      await clearCache();
    }

    await fetch();
  }

  Future<void> _loadFromStorage() async {
    final value = await fromStorage?.call();
    if (value != null) {
      state = state.copyWith(value: value);
      toMemory?.call(value);
    }
  }

  void _setLocked(bool enabled) {
    _isLocked = enabled;
  }

  /// Fetch data [fromNetwork].
  ///
  /// Only one concurrent [fetch] can be run. Lock mechanism is automatically
  /// used for this. Calling [fetch] while [isLocked] is still true will result
  /// in immediate return, however no error is thrown.
  @protected
  Future<void> fetch() async {
    if (isLocked) return;
    _setLocked(true);

    state = state.copyWith(isLoading: true);

    await _fetchSubscription?.cancel();
    _fetchSubscription = fromNetwork().listen(_fetchListener)
      ..onError((Object e, StackTrace s) {
        _updateLastUpdated();
        _handleError(e, s);
      })
      ..onDone(() {
        _setLocked(false);
      });
  }

  Future<void> _fetchListener(V event) async {
    _updateLastUpdated();
    state = Data(value: event);
    toMemory?.call(event);
    await toStorage?.call(event);
  }

  /// Fetch data using [fromNetwork] again. Immediately returns is [isLocked]
  /// is `true`.
  ///
  /// If you set `force` to true then [Data.value], [Data.error] is set
  /// to `null` and [clearCache] is called before calling [fetch].
  ///
  /// If your [fromNetwork] methods never ends (i.e. infinite stream), [reload]
  /// will also never finish. In that case do not await [reload], or ensure
  /// your [fromNetwork] method finished (timeouts etc.).
  Future<void> reload({bool force = false}) async {
    if (!mounted) {
      throw StateError('Delegate is already disposed');
    }

    if (isLocked) {
      return;
    }

    if (force) {
      await clearCache();
      state = Data<V>(isLoading: true);
    }

    await fetch();
  }

  /// Clear cache using [onClearCache].
  Future<void> clearCache() async {
    await onClearCache?.call();
  }

  void _updateLastUpdated() {
    _lastUpdated = DateTime.now();
  }

  void _handleError(Object e, StackTrace s) {
    state = state.copyWith(error: e, isLoading: false);
  }

  @override
  void dispose() {
    _fetchSubscription?.cancel();
    super.dispose();
  }
}

typedef FromNetworkCallback<V> = Stream<V> Function();

typedef FromMemoryCallback<V> = V? Function();
typedef ToMemoryCallback<V> = void Function(V value);

typedef FromStorageCallback<V> = Future<V?> Function();
typedef ToStorageCallback<V> = Future<void> Function(V value);

typedef ClearCacheCallback = Future<void> Function();
