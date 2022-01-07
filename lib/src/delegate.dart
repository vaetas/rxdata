import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdata/src/data.dart';

/// Delegates fetching and caching behavior of specified [Data] object.
class DataDelegate<V> extends Cubit<Data<V>> {
  DataDelegate({
    required this.fromNetwork,
    this.fromMemory,
    this.toMemory,
    this.fromStorage,
    this.toStorage,
    this.onClearCache,
  }) : super(Data<V>(isLoading: true)) {
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
  bool _locked = false;

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
    }

    await fetch();
  }

  Future<void> _loadFromStorage() async {
    try {
      final value = await fromStorage?.call();
      if (value != null) {
        emit(state.copyWith(value: value));
        toMemory?.call(value);
      }
    } catch (e, s) {
      onError(e, s);
    }
  }

  void _setLocked(bool enabled) {
    _locked = enabled;
  }

  /// Fetch data [fromNetwork].
  Future<void> fetch() async {
    if (_locked) {
      return;
    }

    _setLocked(true);
    emit(state.copyWith(isLoading: true));

    try {
      await for (final event in fromNetwork()) {
        emit(Data(value: event));
        toMemory?.call(event);
        await toStorage?.call(event);
      }
    } catch (e, s) {
      onError(e, s);
    } finally {
      emit(state.copyWith(isLoading: false));
    }
    _setLocked(false);
  }

  /// Fetch data using [fromNetwork] again. Returns `false` if delegate
  /// is locked and could not be reloaded.
  ///
  /// If you set `force` to true then value, error, and cache is cleared.
  Future<bool> reload({bool force = false}) async {
    if (_locked) {
      return false;
    }

    if (force) {
      await clearCache();
      emit(const Data(isLoading: true));
    }

    // ignore: unawaited_futures
    fetch();
    return true;
  }

  /// Clear cache using [onClearCache].
  Future<void> clearCache() async {
    await onClearCache?.call();
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print('[$runtimeType.onError] $error');
    debugPrintStack(stackTrace: stackTrace);
    emit(state.copyWith(error: error));
    super.onError(error, stackTrace);
  }
}

typedef _FromNetwork<V> = Stream<V> Function();

typedef _FromMemory<V> = V? Function();
typedef _ToMemory<V> = void Function(V value);

typedef _FromStorage<V> = Future<V?> Function();
typedef _ToStorage<V> = Future<void> Function(V value);

typedef _ClearCache = Future<void> Function();
