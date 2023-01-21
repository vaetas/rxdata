# RxData for Flutter (Riverpod)

RxData allows to delegate fetching and caching behavior for your data. Uses `riverpod` on the
background. Inspired by [Revolut's RxData library](https://github.com/revolut-mobile/RxData).

## Install

```shell
flutter pub add rxdata
```

## Usage

First, define `DataDelegate` object and specify `Data` type.

```dart

final delegateProvider = StateNotifierProvider<DataDelegate<ApiResponse>, Data<ApiResponse>>((ref) {
  return DataDelegate<ApiResponse>(
    fromNetwork: () async* {
      // [fromNetwork] can yield multiple values before closing. You can sequentially fetch data and 
      // and yield them step by step. You should however prevent infinite streams.
      final response = await getRequest();
      yield response;
    },
    fromStorage: () async {
      return loadFromSqlite('my_key');
    },
    toStorage: (value) async {
      await saveToSqlite(value, 'my_key');
    },
  );
});

```

Then use standard Riverpod methods to watch/read the data.

```dart
class ExampleWidget extends HookConsumerWidget {
  const ExampleWidget({Key? key}) : super(key: key);

  final DataDelegate<ApiResponse> dataDelegate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(delegateProvider);

    return Scaffold(
      body: Column(
        children: [
          if (state.isLoading) const CircularProgressIndicator(),
          if (state.hasError) Text(state.error!.toString()),
          if (state.hasValue) Text(state.value!.toString()),
        ],
      ),
    );
  }
}
```

`Data` class has 3 fields:

* `value`: e.g. `ApiResponse` or whatever data you need;
* `error`: optional error, you might have `error` and `value` at the same time because `value` is
  not deleted when error is thrown;
* `isLoading`: if you can expect `value` or `error` to change soon.

You can then call `dataDelegate.reload()` to fetch data again. Delegate will handle caching by
itself, provided that you specified your callbacks.

See [example project](https://github.com/vaetas/rxdata/blob/main/example/lib/main.dart) for full
usage.
