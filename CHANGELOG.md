## 1.0.0

* BREAKING: Migrated to Riverpod.
    * `flutter_bloc` is not supported anymore.

## 0.8.0

* fix: prevent emit after closing delegate

## 0.7.0

* feat: clear cache after memory/storage error
* feat: ensure `onClearCache` callback is provided when using `toMemory` or `toStorage`.

## 0.6.0

* feat: save last update datetime

## 0.5.0

* feat: use equatable for data
* feat: use BlocObserver for events
* fix: await `DataDelegate.reload` method
* refactor: builder widgets

## 0.4.0

* feat: print StackTrace on error

## 0.3.0

* BREAKING: feat: remove Error generic type
    * Error is now type `Object?` by default. Users must remove their own error type from code.
* chore: update dependencies

## 0.2.1

* fix: remove prints

## 0.2.0

* feat: use streams
* feat: add DataBuilder, DateListener, and DataConsumer
* feat: remove Option type from Data

## 0.1.0

* chore: setup project
