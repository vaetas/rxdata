// ignore_for_file: only_throw_errors

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdata/rxdata.dart';

void main() {
  blocTest<DataDelegate<int>, Data<int>>(
    'delegate yields value',
    build: () => OneEmitDelegate(),
    wait: const Duration(milliseconds: 100),
    expect: () => <Data<int>>[
      const Data(value: null, isLoading: true),
      const Data(value: 0, isLoading: false),
    ],
    verify: (bloc) {
      expect(bloc.isLocked, false, reason: 'Delegate should release lock');
    },
  );

  blocTest<DataDelegate<int>, Data<int>>(
    'delegate reloads',
    build: () => OneEmitDelegate(),
    act: (bloc) async {
      await _wait(5);
      unawaited(bloc.reload());
    },
    wait: const Duration(milliseconds: 100),
    expect: () => <Data<int>>[
      const Data(value: null, isLoading: true),
      const Data(value: 0, isLoading: false),
      const Data(value: 0, isLoading: true),
      const Data(value: 0, isLoading: false),
    ],
    verify: (bloc) {
      expect(bloc.isLocked, false, reason: 'Delegate should release lock');
    },
  );

  blocTest<DataDelegate<int>, Data<int>>(
    'delegate force reloads',
    build: () => OneEmitDelegate(),
    act: (bloc) async {
      await _wait(5);
      unawaited(bloc.reload(force: true));
    },
    wait: const Duration(milliseconds: 100),
    expect: () => <Data<int>>[
      const Data(value: null, isLoading: true),
      const Data(value: 0, isLoading: false),
      const Data(value: null, isLoading: true),
      const Data(value: 0, isLoading: false),
    ],
    verify: (bloc) {
      expect(bloc.isLocked, false, reason: 'Delegate should release lock');
    },
  );

  blocTest<DataDelegate<int>, Data<int>>(
    'delegate closes',
    build: () => DataDelegate<int>(
      fromNetwork: () async* {
        yield 0;
        await _wait(100);
        yield 1;
      },
    ),
    act: (bloc) async {
      await _wait(5);
      unawaited(bloc.close());
    },
    wait: const Duration(milliseconds: 50),
    expect: () => <Data<int>>[
      const Data(value: null, isLoading: true),
      const Data(value: 0, isLoading: false),
    ],
    verify: (bloc) {
      expect(bloc.isClosed, true, reason: 'Delegate should close');
    },
  );

  blocTest<DataDelegate<int>, Data<int>>(
    'delegate shows error',
    build: () => FailingDelegate(),
    expect: () => <Data<int>>[
      const Data(value: null, isLoading: true),
      const Data(
        error: 'Some problem',
        isLoading: false,
      ),
    ],
    verify: (bloc) {
      expect(bloc.isLocked, false, reason: 'Delegate should release lock');
    },
  );
}

class MockDelegate extends MockCubit<Data<int>> implements DataDelegate<int> {}

class OneEmitDelegate extends DataDelegate<int> {
  OneEmitDelegate()
      : super(fromNetwork: () async* {
          yield 0;
        });
}

class FailingDelegate extends DataDelegate<int> {
  FailingDelegate()
      : super(fromNetwork: () async* {
          throw 'Some problem';
        });
}

Future<void> _wait(int milliseconds) async {
  await Future<void>.delayed(Duration(milliseconds: milliseconds));
}
