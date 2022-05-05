import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdata/src/data.dart';

/// Delegates fetching and caching behavior of specified [Data] object.
///
/// If you provide [toStorage] or [toMemory] then you must also
/// provide [onClearCache].
///
/// If [toStorage] or [toMemory] throws then [onClearCache] is called.
class DataDelegate<V> extends Cubit<Data<V>> {
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
  final _FromNetwork<V> fromNetwork;

  /// Load cached data from memory. This cannot be async.
  final _FromMemory<V>? fromMemory;

  /// Save data into memory cache.
  final _ToMemory<V>? toMemory;

  /// Load data from storage. This could be SQLite, shared_preferences etc.
  final _FromStorage<V>? fromStorage;

  /// Persist data into storage.
  final _ToStorage<V>? toStorage;

  /// Define how to clear memory & storage cache.
  final _ClearCache? onClearCache;

  /// Whether there already is ongoing network request. Only one request is
  /// allowed at the time.
  bool isLocked = false;

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
        emit(Data(value: memoryValue));
      } else {
        await _loadFromStorage();
      }
    } catch (e, s) {
      onError(e, s);
      await clearCache();
    }

    await fetch();
  }

  Future<void> _loadFromStorage() async {
    final value = await fromStorage?.call();
    if (value != null) {
      emit(state.copyWith(value: value));
      toMemory?.call(value);
    }
  }

  void _setLocked(bool enabled) {
    isLocked = enabled;
  }

  // TODO: Cancel stream listener on [close].
  /// Fetch data [fromNetwork].
  Future<void> fetch() async {
    if (isLocked) return;
    _setLocked(true);

    emit(state.copyWith(isLoading: true));

    try {
      await _fetchSubscription?.cancel();
      _fetchSubscription = fromNetwork().listen(_fetchListener);
    } catch (e, s) {
      _updateLastUpdated();
      onError(e, s);
    } finally {
      emit(state.copyWith(isLoading: false));
    }

    _setLocked(false);
  }

  Future<void> _fetchListener(V event) async {
    _updateLastUpdated();
    emit(Data(value: event));
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
    if (isClosed) {
      throw StateError('Delegate is already closed');
    }

    if (isLocked) {
      return;
    }

    if (force) {
      await clearCache();
      emit(const Data(isLoading: true));
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

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    emit(state.copyWith(error: error));
  }

  @override
  Future<void> close() {
    _fetchSubscription?.cancel();
    return super.close();
  }
}

typedef _FromNetwork<V> = Stream<V> Function();

typedef _FromMemory<V> = V? Function();
typedef _ToMemory<V> = void Function(V value);

typedef _FromStorage<V> = Future<V?> Function();
typedef _ToStorage<V> = Future<void> Function(V value);

typedef _ClearCache = Future<void> Function();
