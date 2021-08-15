abstract class Option<A> {
  const Option();

  const factory Option.value(A value) = Just;

  const factory Option.nothing() = Nothing;

  A get value;

  R when<R>(R Function() isNothing, R Function(A value) isValue);

  bool get isValue;

  bool get isNothing => !isValue;
}

class Just<A> extends Option<A> {
  const Just(this.value);

  @override
  final A value;

  @override
  R when<R>(R Function() isNothing, R Function(A value) isValue) {
    return isValue(value);
  }

  @override
  bool get isValue => true;

  @override
  String toString() => 'Just{value: $value}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Just && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class Nothing<A> extends Option<A> {
  const Nothing();

  @override
  A get value {
    throw OptionAccessError('Cannot access [value] for Nothing instance.');
  }

  @override
  R when<R>(R Function() isNothing, R Function(A value) isValue) {
    return isNothing();
  }

  @override
  bool get isValue => false;

  @override
  String toString() => 'Nothing{}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nothing && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;
}

class OptionAccessError extends Error {
  OptionAccessError(this.message);

  final String message;

  @override
  String toString() => 'OptionError: $message';
}
