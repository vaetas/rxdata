# RxData for Flutter

RxData allows to delegate fetching and caching behavior for your data. Uses `flutter_bloc` on the
background. Inspired by [Revolut's RxData library](https://github.com/revolut-mobile/RxData).

## Install

```shell
flutter pub add rxdata
```

## Usage

First, define `DataDelagete` object and specify `Data` type.

```dart

final dataDelegate = DataDelegate<ApiResponse>(
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
```

Then, use `DataBuilder` to build your UI. `DataBuilder` is only a wrapper around the `BlocBuilder`.
You can also use `DataListener` and `DataConsumer`.

```dart
class ExampleWidget extends StatelessWidget {
  const ExampleWidget({Key? key, required this.dataDelegate}) : super(key: key);

  final DataDelegate<ApiResponse> dataDelegate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DataBuilder<ApiResponse>(
        bloc: dataDelegate,
        builder: (context, state) {
          return Column(
            children: [
              if (state.isLoading) const CircularProgressIndicator(),
              if (state.hasError) Text(state.error!.toString()),
              if (state.hasValue) Text(state.value!.toString()),
            ],
          );
        },
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

## Logging

If you want to capture events and errors from `DataDelegate`s use BLoC's `BlocObserver`. You can
find more info in their [documentation](https://bloclibrary.dev/#/coreconcepts?id=blocobserver).

Simple `BlocObserver` is also implemented
in [example project here](https://github.com/vaetas/rxdata/blob/main/example/lib/main.dart).