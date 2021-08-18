import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdata/rxdata.dart';

/// Wrapper around [BlocBuilder] for shorter generics definition.
class DataBuilder<V, E> extends BlocBuilder<DataDelegate<V, E>, Data<V, E>> {
  const DataBuilder({
    Key? key,
    required BlocWidgetBuilder<Data<V, E>> builder,
    DataDelegate<V, E>? bloc,
    BlocBuilderCondition<Data<V, E>>? buildWhen,
  }) : super(key: key, bloc: bloc, buildWhen: buildWhen, builder: builder);
}

/// Wrapper around [BlocListener] for shorter generics definition.
class DataListener<V, E> extends BlocListener<DataDelegate<V, E>, Data<V, E>> {
  const DataListener({
    Key? key,
    required BlocWidgetListener<Data<V, E>> listener,
    DataDelegate<V, E>? bloc,
    BlocListenerCondition<Data<V, E>>? listenWhen,
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
class DataConsumer<V, E> extends BlocConsumer<DataDelegate<V, E>, Data<V, E>> {
  const DataConsumer({
    Key? key,
    required BlocWidgetListener<Data<V, E>> listener,
    required BlocWidgetBuilder<Data<V, E>> builder,
    DataDelegate<V, E>? bloc,
    BlocListenerCondition<Data<V, E>>? listenWhen,
    BlocBuilderCondition<Data<V, E>>? buildWhen,
  }) : super(
          key: key,
          listener: listener,
          bloc: bloc,
          listenWhen: listenWhen,
          builder: builder,
          buildWhen: buildWhen,
        );
}
