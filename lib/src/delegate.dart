import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdata/src/data.dart';

/// Delegates fetching and caching behavior of specified [Data] object.
class DataDelegate<V, E> extends Cubit<Data<V, E>> {
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

  void _setLocked(bool enabled) {
    print('[DataDelegate._setLocked] $enabled');
    _locked = enabled;
  }

  Future<void> _fetch() async {
    if (_locked) {
      return;
    }

    _setLocked(true);
    emit(state.copyWith(isLoading: true));

    try {
      await for (final event in fromNetwork()) {
        print('[DataDelegate._fetch] EVENT');
        emit(Data(value: event));
        toMemory?.call(event);
        await toStorage?.call(event);
      }
    } catch (e) {
      if (e is E) {
        // .copyWith throws a type error once in a time:
        // type '_Exception' is not a subtype of type 'Null' of 'error'

        // emit(state.copyWith(error: e as E));
        emit(
          Data(
            value: state.value,
            error: e as E,
          ),
        );
      } else {
        throw ArgumentError(
          'Exception ${e.runtimeType} is not subtype of E in Data<V, E>.'
          'Ensure you only throw exceptions of type E.',
        );
      }
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
      print('[DataDelegate.reload] WARNING: Cannot reload locked delegate.');
      return false;
    }

    if (force) {
      await clearCache();
      emit(const Data(isLoading: true));
    }

    // ignore: unawaited_futures
    try {
      _fetch();
    } catch (e, s) {
      print(e);
    }
    return true;
  }

  /// Clear cache using [onClearCache].
  Future<void> clearCache() async {
    await onClearCache?.call();
  }
}

typedef _FromNetwork<V> = Stream<V> Function();

typedef _FromMemory<V> = V? Function();
typedef _ToMemory<V> = void Function(V value);

typedef _FromStorage<V> = Future<V?> Function();
typedef _ToStorage<V> = Future<void> Function(V value);

typedef _ClearCache = Future<void> Function();
