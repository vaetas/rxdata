import 'dart:convert';
import 'dart:developer' as dev;

import 'package:animated_list/implicitly_animated_reorderable_list.dart';
import 'package:animated_list/transitions.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:rxdata/rxdata.dart';

final priceFormat = NumberFormat.currency(name: 'USD', symbol: r'$');

ApiResponse? _cache;

void _log(String name, String message) {
  dev.log(message, name: name);
}

final delegateProvider =
    StateNotifierProvider<DataDelegate<ApiResponse>, Data<ApiResponse>>((ref) {
  final dataDelegate = DataDelegate<ApiResponse>(
    fromNetwork: () async* {
      // throw Exception('Failed to fetch data');

      final now = DateTime.now();

      // https://api.coincap.io/v2/assets/bitcoin/history?interval=m1&start=1629051861939&end=1629052461939
      final uri = Uri(
        host: 'api.coincap.io',
        path: 'v2/assets/bitcoin/history',
        scheme: 'https',
        queryParameters: <String, dynamic>{
          'interval': 'm1',
          'start': now
              .subtract(const Duration(minutes: 10))
              .millisecondsSinceEpoch
              .toString(),
          'end': now.millisecondsSinceEpoch.toString(),
        },
      );

      // await Future<void>.delayed(const Duration(seconds: 1));
      // throw Exception('Example error. Try pressing reload icon.');

      await Future<void>.delayed(const Duration(seconds: 1));

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final data = ApiResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      // Using yield allows us to return multiple data values before exiting.
      // You can utilize this to load data progressively.
      yield data;
    },
    fromStorage: () async {
      // Uncomment line below to simulate storage IO failure.
      // throw Exception('Failed to load from storage');

      _log('fromStorage', 'looking in storage');
      final box = await Hive.openBox<String>('storage');
      final data = box.get('data');
      if (data == null) {
        return null;
      }
      final json = jsonDecode(data) as Map<String, dynamic>;
      final result = ApiResponse.fromJson(json);
      _log('fromStorage', 'found data in storage: $result');
      return result;
    },
    toStorage: (value) async {
      _log('toStorage', 'saving to storage...');
      final box = await Hive.openBox<String>('storage');
      try {
        await box.put('data', value.toJsonString());
        _log('toStorage', 'saved to storage');
      } catch (e, s) {
        _log('toStorage', 'ERROR: $e');
        debugPrintStack(stackTrace: s);
      }
    },
    fromMemory: () {
      _log('fromMemory', 'data in cache: $_cache');
      return _cache;
    },
    toMemory: (value) {
      _log('toMemory', 'saving data to cache $value');
      _cache = value;
    },
    onClearCache: () async {
      _log('onClearCache', 'clearing cache');
      await Hive.deleteBoxFromDisk('storage');
    },
  );
  return dataDelegate;
});

Future<void> main() async {
  await Hive.initFlutter();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(delegateProvider);
    final dataDelegate = ref.watch(delegateProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Example'),
            pinned: true,
            actions: [
              InkWell(
                onTap: dataDelegate.reload,
                onLongPress: () => dataDelegate.reload(force: true),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.refresh),
                ),
              ),
            ],
          ),
          CupertinoSliverRefreshControl(
            onRefresh: dataDelegate.reload,
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text('Last updated: ${dataDelegate.lastUpdated}'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Tooltip(
                    message:
                        'Watch that memory cache is used and new load is instant.',
                    child: ElevatedButton(
                      onPressed: () {
                        ref.invalidate(delegateProvider);
                      },
                      child: const Text('Invalidate provider'),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Fetch BTC price history in the past 10 minutes.',
                  ),
                ),
              ),
            ),
          ),
          if (data.isLoading)
            SliverToBoxAdapter(
              child: Row(
                children: const [
                  CircularProgressIndicator(),
                  Text('Loading...')
                ],
              ),
            ),
          if (data.hasError)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.orangeAccent,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(10),
                child: Text(data.error.toString()),
              ),
            ),
          if (data.hasValue)
            SliverImplicitlyAnimatedList(
              items: data.value!.data,
              itemBuilder: (context, animation, item, i) {
                return SizeFadeTransition(
                  sizeFraction: 0.7,
                  curve: Curves.easeInOut,
                  animation: animation,
                  child: ListTile(
                    title: Text(
                      priceFormat.format(num.parse(item.priceUsd)),
                    ),
                    subtitle: Text(item.date.toLocal().toIso8601String()),
                  ),
                );
              },
              areItemsTheSame: (oldItem, newItem) {
                return oldItem.date == newItem.date;
              },
            )
          else
            const SliverToBoxAdapter(
              child: Text('No data'),
            ),
        ],
      ),
    );
  }
}

class ApiResponse {
  const ApiResponse({required this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    final values = json['data'] as List<dynamic>;
    return ApiResponse(
      data: values
          .map((dynamic e) => PricePoint.fromJson(e as Map<String, dynamic>))
          .sortedBy((element) => element.date)
          .reversed
          .toList(),
    );
  }

  final List<PricePoint> data;

  Map<String, Object?> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  @override
  String toString() => 'ApiResponse{data: [...]}';
}

class PricePoint {
  const PricePoint({
    required this.priceUsd,
    required this.date,
  });

  factory PricePoint.fromJson(Map<String, Object?> json) {
    return PricePoint(
      priceUsd: json['priceUsd'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  final String priceUsd;
  final DateTime date;

  Map<String, Object?> toJson() {
    return {
      'priceUsd': priceUsd,
      'date': date.toIso8601String(),
    };
  }

  @override
  String toString() => 'PricePoint{priceUsd: $priceUsd, date: $date}';
}
