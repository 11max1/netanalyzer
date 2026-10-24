import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final Set<String> found = {};
  bool busy = false;
  double progress = 0;
  String me = '';
  String gw = '';

  Future<bool> _alive(String ip) async {
    for (final port in [80, 443, 53, 22, 445, 8080]) {
      try {
        final sock = await Socket.connect(
          ip,
          port,
          timeout: const Duration(milliseconds: 350),
        );
        sock.destroy();
        return true;
      } on SocketException catch (e) {
        // connection refused (111) means the host is alive
        if (e.osError != null && e.osError!.errorCode == 111) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<void> _scan() async {
    final ni = NetworkInfo();
    me = (await ni.getWifiIP()) ?? '';
    gw = (await ni.getWifiGatewayIP()) ?? '';
    if (me.isEmpty) return;
    final base = me.substring(0, me.lastIndexOf('.') + 1);
    setState(() {
      busy = true;
      found.clear();
      progress = 0;
    });
    for (var start = 1; start <= 254; start += 32) {
      final List<Future<void>> jobs = [];
      for (var i = start; i < start + 32 && i <= 254; i++) {
        final ip = base + i.toString();
        jobs.add(_alive(ip).then((ok) {
          if (ok && mounted) setState(() => found.add(ip));
        }));
      }
      await Future.wait(jobs);
      if (mounted) setState(() => progress = min(start + 31, 254) / 254);
    }
    if (mounted) setState(() => busy = false);
  }

  int _last(String ip) => int.parse(ip.split('.').last);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = found.toList();
    list.sort((a, b) => _last(a).compareTo(_last(b)));
    final List<Widget> tiles = [];
    for (final ip in list) {
      IconData icon = Icons.computer;
      String label = '';
      if (ip == gw) {
        icon = Icons.router;
        label = s.t('router');
      } else if (ip == me) {
        icon = Icons.smartphone;
        label = s.t('me');
      }
      tiles.add(
        ListTile(
          leading: Icon(icon, color: kBlue),
          title: Text(ip, textDirection: TextDirection.ltr),
          subtitle: Text(label),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  list.length.toString() + ' ' + s.t('devices'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: busy ? null : _scan,
                icon: const Icon(Icons.radar),
                label: Text(s.t('scan')),
              ),
            ],
          ),
        ),
        if (busy) LinearProgressIndicator(value: progress),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text(s.t('none')))
              : ListView(children: tiles),
        ),
      ],
    );
  }
}
