import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

const MethodChannel kTrafficChannel = MethodChannel('traffic');

class DashPage extends StatefulWidget {
  const DashPage({super.key});

  @override
  State<DashPage> createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  final List<double> pingData = [];
  final List<double> downData = [];
  Ping? _ping;
  Timer? _timer;
  int _lastRx = 0;
  int _lastTx = 0;
  double upRate = 0;
  String ssid = '-';
  String ip = '-';
  String gw = '-';
  String type = '-';

  @override
  void initState() {
    super.initState();
    _loadInfo();
    _startMonitoring();
  }

  Future<void> _loadInfo() async {
    try {
      final c = await Connectivity().checkConnectivity();
      final ni = NetworkInfo();
      final name = await ni.getWifiName();
      final wip = await ni.getWifiIP();
      final wgw = await ni.getWifiGatewayIP();
      if (!mounted) return;
      setState(() {
        type = c.map((e) => e.name).join(', ');
        ssid = name == null ? '-' : name.replaceAll('"', '');
        ip = wip ?? '-';
        gw = wgw ?? '-';
      });
    } catch (_) {}
  }

  void _add(List<double> list, double v) {
    list.add(v);
    if (list.length > 30) list.removeAt(0);
  }

  void _startMonitoring() {
    final host = context.read<AppState>().host;
    _ping = Ping(host, interval: 1);
    _ping!.stream.listen((event) {
      final r = event.response;
      if (r != null && r.time != null && mounted) {
        setState(() => _add(pingData, r.time!.inMicroseconds / 1000));
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final l = await kTrafficChannel.invokeMethod<List<dynamic>>('get');
        if (l == null) return;
        final rx = (l[0] as num).toInt();
        final tx = (l[1] as num).toInt();
        if (_lastRx != 0 && mounted) {
          setState(() {
            _add(downData, (rx - _lastRx) / 1024);
            upRate = (tx - _lastTx) / 1024;
          });
        }
        _lastRx = rx;
        _lastTx = tx;
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ping?.stop();
    super.dispose();
  }

  Widget _infoRow(IconData icon, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Text(k + ': ', style: const TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(String title, List<double> data, Color color) {
    final List<FlSpot> spots = [];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }
    if (spots.isEmpty) spots.add(const FlSpot(0, 0));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final dlTitle =
        s.t('dl') + '   |   ' + s.t('ul') + ': ' + upRate.toStringAsFixed(0) + ' KB/s';
    return RefreshIndicator(
      onRefresh: _loadInfo,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: kBlue,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.network_check, s.t('conn'), type),
                  _infoRow(Icons.wifi, s.t('net'), ssid),
                  _infoRow(Icons.language, s.t('ip'), ip),
                  _infoRow(Icons.router, s.t('gw'), gw),
                ],
              ),
            ),
          ),
          _chartCard(s.t('ping'), pingData, kCyan),
          _chartCard(dlTitle, downData, kBlue),
        ],
      ),
    );
  }
}
