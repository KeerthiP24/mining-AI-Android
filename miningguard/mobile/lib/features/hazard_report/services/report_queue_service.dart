import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/hazard_report_model.dart';
import 'hazard_report_repository.dart';

class ReportQueueService {
  ReportQueueService(this._repository);

  final HazardReportRepository _repository;

  static const _boxName = 'offline_reports';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Box<String> get _box => Hive.box<String>(_boxName);

  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  int get pendingCount => _box.length;

  Future<void> enqueue(HazardReportModel report) async {
    final marked = report.copyWith(isOfflineCreated: true);
    final json = jsonEncode(marked.toJson());
    await _box.add(json);
  }

  Future<void> flush() async {
    if (_box.isEmpty) return;

    final keys = _box.keys.toList();
    for (final key in keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final report = HazardReportModel.fromJson(json);
        await _repository.submitReport(report);
        await _box.delete(key);
      } catch (_) {
        // Leave in queue; will retry on next flush
      }
    }
  }

  void startConnectivityListener() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      if (results.any((r) => r != ConnectivityResult.none)) {
        await flush();
      }
    });
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
  }
}
