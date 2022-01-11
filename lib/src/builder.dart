import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdata/rxdata.dart';

/// Signature for the `builder` function which takes the `BuildContext` and
/// [data] and is responsible for returning a widget which is to be rendered.
typedef DataWidgetBuilder<S> = Widget Function(
    BuildContext context, Data<S> data);

/// Signature for the `buildWhen` function which takes the previous `state`
/// and the current `state` and is responsible for returning a [bool] which
/// determines whether to rebuild [DataBuilder] with the current `state`.
typedef DataBuilderCondition<S> = bool Function(
    Data<S> previous, Data<S> current);

/// Wrapper around [BlocBuilder] for shorter generics definition.
class DataBuilder<V> extends BlocBuilder<DataDelegate<V>, Data<V>> {
  const DataBuilder({
    Key? key,
    required DataWidgetBuilder<V> builder,
    DataDelegate<V>? bloc,
    DataBuilderCondition<V>? buildWhen,
  }) : super(key: key, bloc: bloc, buildWhen: buildWhen, builder: builder);
}
