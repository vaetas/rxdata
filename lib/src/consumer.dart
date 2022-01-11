import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdata/src/builder.dart';
import 'package:rxdata/src/data.dart';
import 'package:rxdata/src/delegate.dart';
import 'package:rxdata/src/listener.dart';

/// Wrapper around [BlocConsumer] for shorter generics definition.
class DataConsumer<V> extends BlocConsumer<DataDelegate<V>, Data<V>> {
  const DataConsumer({
    Key? key,
    required DataWidgetListener<V> listener,
    required DataWidgetBuilder<V> builder,
    DataDelegate<V>? bloc,
    DataListenerCondition<V>? listenWhen,
    DataBuilderCondition<V>? buildWhen,
  }) : super(
          key: key,
          listener: listener,
          bloc: bloc,
          listenWhen: listenWhen,
          builder: builder,
          buildWhen: buildWhen,
        );
}
