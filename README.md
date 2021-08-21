# RxData for Flutter

RxData allows to delegate fetching and caching behavior for your data. Uses `flutter_bloc` on the
background. Inspired by [Revolut's RxData library](https://github.com/revolut-mobile/RxData).

## Install

```shell
flutter pub add rxdata
flutter pub add flutter_bloc
```

## Usage

First, define `DataDelagete` object and specify `Data` type and `Exception` type.

```dart

final dataDelegate = DataDelegate<ApiResponse, Exception>(
  fromNetwork: () async* {
    final response = await getRequest();

    yield response;
  },
  fromStorage: () async {
    return loadFromSqlite();
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

  final DataDelegate<ApiResponse, Exception> dataDelegate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DataBuilder<ApiResponse, Object>(
        bloc: dataDelegate,
        builder: (context, state) {
          if (state.hasValue) {
            return Text(state.value!.toString());
          } else {
            return Text('No data');
          }
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

See `example` project for full usage.