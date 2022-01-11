import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdata/src/data.dart';
import 'package:rxdata/src/delegate.dart';

/// Signature for the `listener` function which takes the `BuildContext` along
/// with the `state` and is responsible for executing in response to
/// `state` changes.
typedef DataWidgetListener<S> = void Function(
    BuildContext context, Data<S> data);

/// Signature for the `listenWhen` function which takes the previous `state`
/// and the current `state` and is responsible for returning a [bool] which
/// determines whether or not to call [DataWidgetListener] of [DataListener]
/// with the current `state`.
typedef DataListenerCondition<S> = bool Function(
    Data<S> previous, Data<S> current);

/// Wrapper around [BlocListener] for shorter generics definition.
class DataListener<V> extends BlocListener<DataDelegate<V>, Data<V>> {
  const DataListener({
    Key? key,
    required DataWidgetListener<V> listener,
    DataDelegate<V>? bloc,
    DataListenerCondition<V>? listenWhen,
    Widget? child,
  }) : super(
          key: key,
          child: child,
          listener: listener,
          bloc: bloc,
          listenWhen: listenWhen,
        );
}
