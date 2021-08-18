/// Wrapper around your data of type [V].
///
/// [E] is a type for a possible exceptions. You can either provide your own
/// exception class/enum or use [Object].
class Data<V, E> {
  const Data({
    this.value,
    this.error,
    this.isLoading = false,
  });

  /// Current value
  final V? value;

  /// Current error
  final E? error;

  /// Whether you can except the data to refresh soon. Remember that you can
  /// have [isLoading] set to true and still have some value and/or error at the
  /// same time.
  final bool isLoading;

  /// If [value] is not null
  bool get hasValue => value != null;

  /// If [error] is not null
  bool get hasError => error != null;

  /// Create copy of this [Data] object with new params.
  Data<V, E> copyWith({
    bool? isLoading,
    V? value,
    E? error,
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
          value == other.value &&
          error == other.error &&
          isLoading == other.isLoading;

  @override
  int get hashCode => value.hashCode ^ error.hashCode ^ isLoading.hashCode;
}
