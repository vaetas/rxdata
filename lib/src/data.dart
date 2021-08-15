import 'package:rxdata/src/option.dart';

/// Wrapper around your data of type [E] (JSON, or your custom class).
///
/// [E] is a type for a possible exceptions. You can either provide your own
/// exception class/enum or use [Object].
class Data<V, E> {
  factory Data({
    bool isLoading = false,
    V? value,
    E? error,
  }) {
    return Data._(
      value: value == null ? Option<V>.nothing() : Option.value(value),
      error: error == null ? Option<E>.nothing() : Option.value(error),
      isLoading: isLoading,
    );
  }

  const Data._({
    required this.value,
    required this.error,
    this.isLoading = false,
  });

  /// Current value that can either be null [Nothing] or [Just] value.
  final Option<V> value;

  /// Current error
  final Option<E> error;

  /// Whether you can except the data to refresh soon. Remember that you can
  /// have [isLoading] set to true and still have some value and/or error at the
  /// same time.
  final bool isLoading;

  /// Create copy of this [Data] object with new params.
  Data<V, E> copyWith({
    bool? isLoading,
    V? value,
    E? error,
  }) {
    return Data._(
      value: value != null ? Option.value(value) : this.value,
      error: error != null ? Option.value(error) : this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() {
    return 'Data{value: $value, error: $error, isLoading: $isLoading}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Data &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          error == other.error &&
          isLoading == other.isLoading;

  @override
  int get hashCode => value.hashCode ^ error.hashCode ^ isLoading.hashCode;
}
