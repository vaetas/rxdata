import 'package:collection/collection.dart';

/// Wrapper around your data of type [V].
class Data<V> {
  const Data({
    this.value,
    this.error,
    this.isLoading = false,
  });

  /// Current value
  final V? value;

  /// Current error
  final Object? error;

  /// Whether you can except the data to refresh soon. Remember that you can
  /// have [isLoading] set to true and still have value and/or error at the
  /// same time.
  final bool isLoading;

  /// If [value] is not null
  bool get hasValue => value != null;

  /// If [error] is not null
  bool get hasError => error != null;

  /// Create copy of this [Data] object with new params.
  Data<V> copyWith({
    V? value,
    Object? error,
    bool? isLoading,
  }) {
    return Data(
      value: value ?? this.value,
      error: error ?? this.error,
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
          const DeepCollectionEquality().equals(value, other.value) &&
          error == other.error &&
          isLoading == other.isLoading;

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(value) ^
      error.hashCode ^
      isLoading.hashCode;
}
