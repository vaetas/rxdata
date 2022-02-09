import 'dart:convert';
import 'dart:developer' as dev;

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:rxdata/rxdata.dart';

final priceFormat = NumberFormat.currency(name: 'USD', symbol: r'$');

Future<void> main() async {
  await BlocOverrides.runZoned(
    () async {
      await Hive.initFlutter();
      runApp(ExampleApp());
    },
    blocObserver: SimpleBlocObserver(),
  );
}

class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // ignore: prefer_const_constructors
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DataDelegate<ApiResponse> dataDelegate;

  bool wasErrorThrown = false;

  @override
  void initState() {
    super.initState();
    dataDelegate = DataDelegate(
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

        if (!wasErrorThrown) {
          wasErrorThrown = true;
          throw Exception('Example error. Try pressing reload icon.');
        }

        await Future<void>.delayed(const Duration(seconds: 1));

        final response = await http.get(uri);

        if (response.statusCode != 200) {
          throw Exception(response.body);
        }

        yield ApiResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      },
      fromStorage: () async {
        // Uncomment line below to simulate storage IO failure.
        // throw Exception('Failed to load from storage');

        print('[_HomeScreenState.initState] fromStorage');
        final box = await Hive.openBox<String>('storage');
        final data = box.get('data');
        if (data == null) {
          return null;
        }
        final json = jsonDecode(data) as Map<String, dynamic>;
        return ApiResponse.fromJson(json);
      },
      toStorage: (value) async {
        print('[_HomeScreenState.initState] toStorage');
        final box = await Hive.openBox<String>('storage');
        try {
          await box.put('data', value.toJsonString());
        } catch (e) {
          print('ERROR: $e');
        }
      },
      fromMemory: () {
        print('[_HomeScreenState.initState] fromMemory');
      },
      toMemory: (value) {
        print('[_HomeScreenState.initState] toMemory');
      },
      onClearCache: () async {
        await Hive.deleteBoxFromDisk('storage');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DataBuilder<ApiResponse>(
        bloc: dataDelegate,
        builder: (context, state) {
          return CustomScrollView(
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
                child: Text('Last updated: ${dataDelegate.lastUpdated}'),
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
              if (state.isLoading)
                SliverToBoxAdapter(
                  child: Row(
                    children: const [
                      CircularProgressIndicator(),
                      Text('Loading...')
                    ],
                  ),
                ),
              if (state.hasError)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.orangeAccent,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(10),
                    child: Text(state.error.toString()),
                  ),
                ),
              if (state.hasValue)
                SliverList(
                  delegate: SliverChildListDelegate(
                    state.value!.data.map((e) {
                      return ListTile(
                        title: Text(
                          priceFormat.format(num.parse(e.priceUsd)),
                        ),
                        subtitle: Text(e.date.toLocal().toIso8601String()),
                      );
                    }).toList(),
                  ),
                )
              else
                const SliverToBoxAdapter(
                  child: Text('No data'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class SimpleBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    dev.log(
      'Error',
      error: error,
      stackTrace: stackTrace,
      name: '${bloc.runtimeType}',
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (bloc is DataDelegate<ApiResponse>) {
      final state = change.nextState as Data<ApiResponse>;
      print('[SimpleBlocObserver.onChange] Next state $state');
    }
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
