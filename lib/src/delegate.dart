import 'package:bloc/bloc.dart';
import 'package:rxdata/src/data.dart';

/// Delegates fetching and caching behavior of specified [Data] object.
class DataDelegate<V, E extends Exception> extends Cubit<Data<V, E>> {
  DataDelegate({
    required this.fromNetwork,
    this.fromMemory,
    this.toMemory,
    this.fromStorage,
    this.toStorage,
    this.onClearCache,
  }) : super(Data<V, E>(isLoading: true)) {
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
    final memoryValue = fromMemory?.call();
    if (memoryValue != null) {
      emit(Data(value: memoryValue));
    } else {
      await _loadFromStorage();
    }

    await _fetch();
  }

  Future<void> _loadFromStorage() async {
    final value = await fromStorage?.call();

    if (value != null) {
      emit(state.copyWith(value: value));
      toMemory?.call(value);
    }
  }

  Future<void> _fetch() async {
    if (_locked) {
      return;
    }

    _locked = true;
    emit(state.copyWith(isLoading: true));

    try {
      final response = await fromNetwork();
      emit(Data(value: response));

      toMemory?.call(response);
      await toStorage?.call(response);
    } on E catch (e) {
      emit(state.copyWith(error: e, isLoading: false));
    }
    _locked = false;
  }

  /// Fetch data using [fromNetwork] again. If you set `clearCache` to true,
  /// cache will be first cleared using [onClearCache].
  Future<void> reload({bool clearCache = false}) async {
    if (clearCache) {
      await this.clearCache();
    }

    await _fetch();
  }

  /// Clear cache using [onClearCache].
  Future<void> clearCache() async {
    await onClearCache?.call();
  }
}

typedef _FromNetwork<V> = Future<V> Function();

typedef _FromMemory<V> = V? Function();
typedef _ToMemory<V> = void Function(V value);

typedef _FromStorage<V> = Future<V?> Function();
typedef _ToStorage<V> = Future<void> Function(V value);

typedef _ClearCache = Future<void> Function();
