import 'dart:io';
import 'dart:typed_data';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final TextEditingController host = TextEditingController(text: 'google.com');
  final List<String> logLines = [];
  bool busy = false;
  bool cancel = false;

  void _log(String m) {
    if (mounted) setState(() => logLines.insert(0, m));
  }

  String _ms(Duration? d) {
    if (d == null) return '-';
    return (d.inMicroseconds / 1000).toStringAsFixed(1);
  }

  Future<void> _run(Future<void> Function() job) async {
    setState(() {
      busy = true;
      cancel = false;
      logLines.clear();
    });
    try {
      await job();
    } catch (e) {
      _log('Error: ' + e.toString());
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _doPing() {
    return _run(() async {
      final p = Ping(host.text.trim(), count: 5);
      await for (final e in p.stream) {
        final r = e.response;
        if (r != null) {
          _log((r.ip ?? '') + '   ' + _ms(r.time) + ' ms');
        } else if (e.summary != null) {
          _log('Sent ' +
              e.summary!.transmitted.toString() +
              ' / Received ' +
              e.summary!.received.toString());
        } else if (e.error != null) {
          _log(e.error.toString());
        }
      }
    });
  }

  Future<void> _doTrace() {
    return _run(() async {
      final h = host.text.trim();
      final list = await InternetAddress.lookup(h);
      final target = list.first.address;
      for (var ttl = 1; ttl <= 20 && !cancel; ttl++) {
        final p = Ping(target, count: 1, ttl: ttl, timeout: 2);
        String hop = '*';
        await for (final e in p.stream) {
          final r = e.response;
          if (r != null) {
            hop = (r.ip ?? '*') + '   ' + _ms(r.time) + ' ms';
            break;
          }
        }
        _log(ttl.toString() + '   ' + hop);
        if (hop.startsWith(target)) break;
      }
    });
  }

  Future<void> _doPorts() {
    return _run(() async {
      const ports = [21, 22, 23, 25, 53, 80, 110, 143, 443, 445, 3306, 3389, 8080];
      final h = host.text.trim();
      for (final p in ports) {
        if (cancel) break;
        try {
          final sock = await Socket.connect(
            h,
            p,
            timeout: const Duration(milliseconds: 800),
          );
          sock.destroy();
          _log('OPEN  ' + p.toString());
        } catch (_) {}
      }
      _log('--- done ---');
    });
  }

  Future<void> _doSpeed() {
    return _run(() async {
      _log('Download...');
      final c = HttpClient();
      var sw = Stopwatch()..start();
      var n = 0;
      final req = await c.getUrl(
        Uri.parse('https://speed.cloudflare.com/__down?bytes=25000000'),
      );
      final res = await req.close();
      await for (final d in res) {
        n += d.length;
      }
      sw.stop();
      final dl = n * 8 / sw.elapsedMicroseconds;
      _log('Download: ' + dl.toStringAsFixed(1) + ' Mbps');

      _log('Upload...');
      final data = Uint8List(5 * 1024 * 1024);
      final up = await c.postUrl(Uri.parse('https://speed.cloudflare.com/__up'));
      up.contentLength = data.length;
      sw = Stopwatch()..start();
      up.add(data);
      final upRes = await up.close();
      await upRes.drain<void>();
      sw.stop();
      final ul = data.length * 8 / sw.elapsedMicroseconds;
      _log('Upload: ' + ul.toStringAsFixed(1) + ' Mbps');
      c.close();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: host,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: s.t('host'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: busy ? null : _doSpeed,
                icon: const Icon(Icons.speed),
                label: Text(s.t('speed')),
              ),
              FilledButton.tonalIcon(
                onPressed: busy ? null : _doPing,
                icon: const Icon(Icons.network_ping),
                label: const Text('Ping'),
              ),
              FilledButton.tonalIcon(
                onPressed: busy ? null : _doTrace,
                icon: const Icon(Icons.timeline),
                label: Text(s.t('trace')),
              ),
              FilledButton.tonalIcon(
                onPressed: busy ? null : _doPorts,
                icon: const Icon(Icons.lock_open),
                label: Text(s.t('ports')),
              ),
              if (busy)
                OutlinedButton(
                  onPressed: () => cancel = true,
                  child: Text(s.t('stop')),
                ),
            ],
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: logLines.length,
                itemBuilder: (context, i) => Text(
                  logLines[i],
                  textDirection: TextDirection.ltr,
                  style: GoogleFonts.robotoMono(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
