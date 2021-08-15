# RxData for Flutter

RxData allows to delegate fetching and caching behavior for your data. Uses `flutter_bloc` on the
background.

## Install

```shell
flutter pub add rxdata
flutter pub add flutter_bloc
```

## Usage

First, define `DataDelagete` object and specify `Data` type and `Exception` type.

```dart

final dataDelegate = DataDelegate<ApiResponse, Exception>(
  fromNetwork: () async {
    return getRequest();
  },
  fromStorage: () async {
    return loadFromSqlite();
  },
  toStorage: (value) async {
    await saveToSqlite(value, 'my_key');
  },
);
```

Then, use `BlocBuilder` to build your UI.

```dart
class ExampleWidget extends StatelessWidget {
  const ExampleWidget({Key? key, required this.dataDelegate}) : super(key: key);

  final DataDelegate<ApiResponse, Exception> dataDelegate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataDelegate<ApiResponse, Exception>,
        Data<ApiResponse, Exception>>(
      bloc: dataDelegate,
      builder: (context, state) {
        return state.value.when(
              () => Text('No data'),
              (value) => Text(value.toString()),
        );
      },
    );
  }
}
```

You can then call `dataDelegate.reload()` to fetch data again. Delegate will handle caching by
itself, provided that you specified your callbacks.

See `example` project for full usage.