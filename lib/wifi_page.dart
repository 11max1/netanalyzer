import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_scan/wifi_scan.dart';

import 'app_state.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({super.key});

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  List<WiFiAccessPoint> aps = [];
  bool busy = false;

  int _channel(int f) {
    if (f >= 5000) return (f - 5000) ~/ 5;
    if (f == 2484) return 14;
    return (f - 2407) ~/ 5;
  }

  String _band(int f) {
    if (f >= 5000) return '5 GHz';
    return '2.4 GHz';
  }

  Color _color(int level) {
    if (level > -60) return Colors.green;
    if (level > -75) return Colors.orange;
    return Colors.red;
  }

  Future<void> _scan() async {
    setState(() => busy = true);
    try {
      await WiFiScan.instance.startScan();
      final can = await WiFiScan.instance.canGetScannedResults();
      if (can == CanGetScannedResults.yes) {
        final r = await WiFiScan.instance.getScannedResults();
        r.sort((a, b) => b.level.compareTo(a.level));
        aps = r;
      }
    } catch (e) {
      debugPrint('Wi-Fi scan error: ' + e.toString());
    }
    if (mounted) setState(() => busy = false);
  }

  Widget _item(WiFiAccessPoint a) {
    final name = a.ssid.isEmpty ? 'hidden' : a.ssid;
    final info =
        'CH ' + _channel(a.frequency).toString() + ' - ' + _band(a.frequency);
    return ListTile(
      leading: Icon(Icons.wifi, color: _color(a.level)),
      title: Text(name),
      subtitle: Text(info),
      trailing: Text(
        a.level.toString() + ' dBm',
        textDirection: TextDirection.ltr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final title = aps.length.toString() + ' ' + s.t('wifi');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: busy ? null : _scan,
                icon: const Icon(Icons.wifi_find),
                label: Text(s.t('scan')),
              ),
            ],
          ),
        ),
        if (busy) const LinearProgressIndicator(),
        Expanded(
          child: aps.isEmpty
              ? Center(child: Text(s.t('none')))
              : ListView.builder(
                  itemCount: aps.length,
                  itemBuilder: (context, i) => _item(aps[i]),
                ),
        ),
      ],
    );
  }
}
