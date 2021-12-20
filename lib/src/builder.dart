import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdata/rxdata.dart';

/// Wrapper around [BlocBuilder] for shorter generics definition.
class DataBuilder<V> extends BlocBuilder<DataDelegate<V>, Data<V>> {
  const DataBuilder({
    Key? key,
    required BlocWidgetBuilder<Data<V>> builder,
    DataDelegate<V>? bloc,
    BlocBuilderCondition<Data<V>>? buildWhen,
  }) : super(key: key, bloc: bloc, buildWhen: buildWhen, builder: builder);
}

/// Wrapper around [BlocListener] for shorter generics definition.
class DataListener<V> extends BlocListener<DataDelegate<V>, Data<V>> {
  const DataListener({
    Key? key,
    required BlocWidgetListener<Data<V>> listener,
    DataDelegate<V>? bloc,
    BlocListenerCondition<Data<V>>? listenWhen,
    Widget? child,
  }) : super(
          key: key,
          child: child,
          listener: listener,
          bloc: bloc,
          listenWhen: listenWhen,
        );
}

/// Wrapper around [BlocConsumer] for shorter generics definition.
class DataConsumer<V> extends BlocConsumer<DataDelegate<V>, Data<V>> {
  const DataConsumer({
    Key? key,
    required BlocWidgetListener<Data<V>> listener,
    required BlocWidgetBuilder<Data<V>> builder,
    DataDelegate<V>? bloc,
    BlocListenerCondition<Data<V>>? listenWhen,
    BlocBuilderCondition<Data<V>>? buildWhen,
  }) : super(
          key: key,
          listener: listener,
          bloc: bloc,
          listenWhen: listenWhen,
          builder: builder,
          buildWhen: buildWhen,
        );
}
