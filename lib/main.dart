import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wifi_scan/wifi_scan.dart';

const kBlue = Color(0xFF1565C0);
const kCyan = Color(0xFF00B0FF);
const _ch = MethodChannel('traffic');

const _s = <String, List<String>>{
  'home': ['الرئيسية', 'Home'],
  'tools': ['الأدوات', 'Tools'],
  'devices': ['الأجهزة', 'Devices'],
  'wifi': ['الواي فاي', 'Wi-Fi'],
  'settings': ['الإعدادات', 'Settings'],
  'conn': ['نوع الاتصال', 'Connection'],
  'net': ['اسم الشبكة', 'Network'],
  'ip': ['عنوان IP', 'IP address'],
  'gw': ['البوابة', 'Gateway'],
  'ping': ['زمن الاستجابة (ms)', 'Latency (ms)'],
  'dl': ['سرعة التنزيل (KB/s)', 'Download rate (KB/s)'],
  'ul': ['الرفع', 'Upload'],
  'host': ['العنوان / الدومين', 'Host / domain'],
  'speed': ['اختبار السرعة', 'Speed test'],
  'trace': ['Traceroute', 'Traceroute'],
  'ports': ['فحص المنافذ', 'Port scan'],
  'scan': ['فحص', 'Scan'],
  'stop': ['إيقاف', 'Stop'],
  'dark': ['الوضع الداكن', 'Dark mode'],
  'lang': ['العربية', 'Arabic'],
  'target': ['هدف الـ Ping', 'Ping target'],
  'dev': ['مطوّر التطبيق', 'Developer'],
  'me': ['هذا الجهاز', 'This device'],
  'router': ['الراتب/الراوتر', 'Router'],
  'none': ['لا توجد نتائج', 'No results'],
};

class AppState extends ChangeNotifier {
  bool ar = true, dark = false;
  String host = '8.8.8.8';
  String t(String k) => _s[k]![ar ? 0 : 1];
  void set({bool? ar, bool? dark, String? host}) {
    this.ar = ar ?? this.ar;
    this.dark = dark ?? this.dark;
    this.host = host ?? this.host;
    notifyListeners();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    ThemeData theme(Brightness b) => ThemeData(
          useMaterial3: true,
          brightness: b,
          colorScheme: ColorScheme.fromSeed(seedColor: kBlue, brightness: b),
          textTheme: GoogleFonts.cairoTextTheme(
              ThemeData(brightness: b).textTheme),
        );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Abbas Abod Net',
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: s.dark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(s.ar ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Shell(),
    );
  }
}

// ---------------- الشعار ----------------
class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .28),
          gradient: const LinearGradient(
              colors: [kBlue, kCyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: kCyan.withOpacity(.4), blurRadius: 10)],
        ),
        child: CustomPaint(painter: _LogoPainter()),
      );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s.width * .08;
    final center = Offset(s.width / 2, s.height * .72);
    for (final r in [.18, .32, .46]) {
      c.drawArc(Rect.fromCircle(center: center, radius: s.width * r),
          -pi * .85, pi * .7, false, p);
    }
    c.drawCircle(center, s.width * .06, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const Logo(size: 36),
        const SizedBox(width: 10),
        Text('Abbas Abod',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20)),
      ]);
}

// ---------------- الهيكل ----------------
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  void initState() {
    super.initState();
    [Permission.locationWhenInUse, Permission.nearbyWifiDevices].request();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pages = [const Dash(), const Tools(), const Devices(), const WifiPage(), const SettingsPage()];
    return Directionality(
      textDirection: s.ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Brand(), centerTitle: false),
        body: IndexedStack(index: i, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: i,
          onDestinationSelected: (v) => setState(() => i = v),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.dashboard_rounded), label: s.t('home')),
            NavigationDestination(icon: const Icon(Icons.build_rounded), label: s.t('tools')),
            NavigationDestination(icon: const Icon(Icons.devices_rounded), label: s.t('devices')),
            NavigationDestination(icon: const Icon(Icons.wifi_rounded), label: s.t('wifi')),
            NavigationDestination(icon: const Icon(Icons.settings_rounded), label: s.t('settings')),
          ],
        ),
      ),
    );
  }
}

// ---------------- الرئيسية ----------------
class Dash extends StatefulWidget {
  const Dash({super.key});
  @override
  State<Dash> createState() => _DashState();
}

class _DashState extends State<Dash> {
  final ping = <double>[], down = <double>[];
  Ping? _p;
  Timer? _t;
  int _lr = 0, _lt = 0;
  double upRate = 0;
  String ssid = '-', ip = '-', gw = '-', type = '-';

  @override
  void initState() {
    super.initState();
    _info();
    _start();
  }

  Future<void> _info() async {
    final c = await Connectivity().checkConnectivity();
    final ni = NetworkInfo();
    final n = (await ni.getWifiName())?.replaceAll('"', '') ?? '-';
    final i = await ni.getWifiIP() ?? '-';
    final g = await ni.getWifiGatewayIP() ?? '-';
    if (!mounted) return;
    setState(() {
      type = c.map((e) => e.name).join(', ');
      ssid = n;
      ip = i;
      gw = g;
    });
  }

  void _add(List<double> l, double v) {
    l.add(v);
    if (l.length > 30) l.removeAt(0);
  }

  void _start() {
    _p = Ping(context.read<AppState>().host, interval: 1);
    _p!.stream.listen((e) {
      final t = e.response?.time;
      if (t != null && mounted) {
        setState(() => _add(ping, t.inMicroseconds / 1000));
      }
    });
    _t = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final l = await _ch.invokeMethod<List>('get');
        final r = (l![0] as num).toInt(), t = (l[1] as num).toInt();
        if (_lr != 0 && mounted) {
          setState(() {
            _add(down, (r - _lr) / 1024);
            upRate = (t - _lt) / 1024;
          });
        }
        _lr = r;
        _lt = t;
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _p?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return RefreshIndicator(
      onRefresh: _info,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          color: kBlue,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _row(Icons.network_check, s.t('conn'), type),
              _row(Icons.wifi, s.t('net'), ssid),
              _row(Icons.language, s.t('ip'), ip),
              _row(Icons.router, s.t('gw'), gw),
            ]),
          ),
        ),
        _chartCard(s.t('ping'), ping, kCyan),
        _chartCard('${s.t('dl')}   •   ${s.t('ul')}: ${upRate.toStringAsFixed(0)} KB/s', down, kBlue),
      ]),
    );
  }

  Widget _row(IconData i, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(i, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Text('$k: ', style: const TextStyle(color: Colors.white70)),
          Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ]),
      );

  Widget _chartCard(String title, List<double> d, Color c) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: LineChart(LineChartData(
                minY: 0,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: d.isEmpty
                        ? [const FlSpot(0, 0)]
                        : [for (var i = 0; i < d.length; i++) FlSpot(i.toDouble(), d[i])],
                    isCurved: true,
                    color: c,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: c.withOpacity(.15)),
                  )
                ],
              )),
            ),
          ]),
        ),
      );
}

// ---------------- الأدوات ----------------
class Tools extends StatefulWidget {
  const Tools({super.key});
  @override
  State<Tools> createState() => _ToolsState();
}

class _ToolsState extends State<Tools> {
  final host = TextEditingController(text: 'google.com');
  final log = <String>[];
  bool busy = false, cancel = false;

  void _l(String m) {
    if (mounted) setState(() => log.insert(0, m));
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      busy = true;
      cancel = false;
      log.clear();
    });
    try {
      await f();
    } catch (e) {
      _l('خطأ / Error: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _ping() => _run(() async {
        final p = Ping(host.text.trim(), count: 5);
        await for (final e in p.stream) {
          if (e.response != null) {
            _l('${e.response!.ip}  ${(e.response!.time!.inMicroseconds / 1000).toStringAsFixed(1)} ms');
          } else if (e.summary != null) {
            _l('Sent ${e.summary!.transmitted} / Received ${e.summary!.received}');
          } else if (e.error != null) {
            _l(e.error!.toString());
          }
        }
      });

  Future<void> _trace() => _run(() async {
        final h = host.text.trim();
        final target = (await InternetAddress.lookup(h)).first.address;
        for (var ttl = 1; ttl <= 20 && !cancel; ttl++) {
          final p = Ping(target, count: 1, ttl: ttl, timeout: 2);
          String hop = '*';
          await for (final e in p.stream) {
            if (e.response != null) {
              hop = '${e.response!.ip ?? '*'}  ${(e.response!.time!.inMicroseconds / 1000).toStringAsFixed(1)} ms';
              break;
            }
          }
          _l('$ttl   $hop');
          if (hop.startsWith(target)) break;
        }
      });

  Future<void> _ports() => _run(() async {
        const ps = [21, 22, 23, 25, 53, 80, 110, 143, 443, 445, 3306, 3389, 8080];
        final h = host.text.trim();
        for (final p in ps) {
          if (cancel) break;
          try {
            final s = await Socket.connect(h, p, timeout: const Duration(milliseconds: 800));
            s.destroy();
            _l('✅ $p  open');
          } catch (_) {}
        }
        _l('— done —');
      });

  Future<void> _speed() => _run(() async {
        _l('Download...');
        final c = HttpClient();
        var sw = Stopwatch()..start();
        var n = 0;
        final r = await (await c.getUrl(Uri.parse('https://speed.cloudflare.com/__down?bytes=25000000'))).close();
        await for (final d in r) {
          n += d.length;
        }
        sw.stop();
        _l('⬇ ${(n * 8 / sw.elapsedMicroseconds).toStringAsFixed(1)} Mbps');
        _l('Upload...');
        final data = Uint8List(5 * 1024 * 1024);
        final rq = await c.postUrl(Uri.parse('https://speed.cloudflare.com/__up'));
        rq.contentLength = data.length;
        sw = Stopwatch()..start();
        rq.add(data);
        await (await rq.close()).drain();
        sw.stop();
        _l('⬆ ${(data.length * 8 / sw.elapsedMicroseconds).toStringAsFixed(1)} Mbps');
        c.close();
      });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(
          controller: host,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: s.t('host'), border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: busy ? null : _speed, icon: const Icon(Icons.speed), label: Text(s.t('speed'))),
          FilledButton.tonalIcon(onPressed: busy ? null : _ping, icon: const Icon(Icons.network_ping), label: const Text('Ping')),
          FilledButton.tonalIcon(onPressed: busy ? null : _trace, icon: const Icon(Icons.timeline), label: Text(s.t('trace'))),
          FilledButton.tonalIcon(onPressed: busy ? null : _ports, icon: const Icon(Icons.lock_open), label: Text(s.t('ports'))),
          if (busy) OutlinedButton(onPressed: () => cancel = true, child: Text(s.t('stop'))),
        ]),
        if (busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        const SizedBox(height: 8),
        Expanded(
          child: Card(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: log.length,
              itemBuilder: (_, i) => Text(log[i], textDirection: TextDirection.ltr, style: GoogleFonts.robotoMono(fontSize: 13)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------------- الأجهزة ----------------
class Devices extends StatefulWidget {
  const Devices({super.key});
  @override
  State<Devices> createState() => _DevicesState();
}

class _DevicesState extends State<Devices> {
  final found = <String>{};
  bool busy = false;
  double prog = 0;
  String me = '', gw = '';

  Future<bool> _alive(String ip) async {
    for (final p in [80, 443, 53, 22, 445, 8080]) {
      try {
        final s = await Socket.connect(ip, p, timeout: const Duration(milliseconds: 350));
        s.destroy();
        return true;
      } on SocketException catch (e) {
        if (e.osError?.errorCode == 111) return true; // رفض الاتصال = الجهاز موجود
      } catch (_) {}
    }
    return false;
  }

  Future<void> _scan() async {
    final ni = NetworkInfo();
    me = await ni.getWifiIP() ?? '';
    gw = await ni.getWifiGatewayIP() ?? '';
    if (me.isEmpty) return;
    final base = me.substring(0, me.lastIndexOf('.') + 1);
    setState(() {
      busy = true;
      found.clear();
      prog = 0;
    });
    for (var start = 1; start <= 254; start += 32) {
      await Future.wait([
        for (var i = start; i < start + 32 && i <= 254; i++)
          _alive('$base$i').then((ok) {
            if (ok && mounted) setState(() => found.add('$base$i'));
          })
      ]);
      if (mounted) setState(() => prog = min(start + 31, 254) / 254);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = found.toList()..sort((a, b) => int.parse(a.split('.').last).compareTo(int.parse(b.split('.').last)));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: Text('${list.length} ${s.t('devices')}', style: Theme.of(context).textTheme.titleMedium)),
          FilledButton.icon(onPressed: busy ? null : _scan, icon: const Icon(Icons.radar), label: Text(s.t('scan'))),
        ]),
      ),
      if (busy) LinearProgressIndicator(value: prog),
      Expanded(
        child: list.isEmpty
            ? Center(child: Text(s.t('none')))
            : ListView(children: [
                for (final ip in list)
                  ListTile(
                    leading: Icon(ip == gw ? Icons.router : ip == me ? Icons.smartphone : Icons.computer, color: kBlue),
                    title: Text(ip, textDirection: TextDirection.ltr, textAlign: s.ar ? TextAlign.right : TextAlign.left),
                    subtitle: Text(ip == gw ? s.t('router') : ip == me ? s.t('me') : ''),
                  )
              ]),
      ),
    ]);
  }
}

// ---------------- الواي فاي ----------------
class WifiPage extends StatefulWidget {
  const WifiPage({super.key});

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  List<WiFiAccessPoint> aps = [];
  bool busy = false;

  int _channel(int f) =>
      f >= 5000 ? (f - 5000) ~/ 5 : (f == 2484 ? 14 : (f - 2407) ~/ 5);

  Future<void> _scan() async {
    setState(() => busy = true);

    try {
      await WiFiScan.instance.startScan();

      if (await WiFiScan.instance.canGetScannedResults() ==
          CanGetScannedResults.yes) {
        final results = await WiFiScan.instance.getScannedResults();

        results.sort((a, b) => b.level.compareTo(a.level));

        if (mounted) {
          setState(() {
            aps = results;
          });
        }
      }
    } catch (e) {
      debugPrint('Wi-Fi scan error: $e');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${aps.length} ${s.t('wifi')}',
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
                  itemBuilder: (_, i) {
                    final a = aps[i];

                    final c = a.level > -60
                        ? Colors.green
                        : a.level > -75
                            ? Colors.orange
                            : Colors.red;

                    return ListTile(
                      leading: Icon(Icons.wifi, color: c),
                      title: Text(
                        a.ssid.isEmpty ? '(hidden)' : a.ssid,
                      ),
                      subtitle: Text(
                        'CH ${_channel(a.frequency)} • '
                        '${a.frequency >= 5000 ? '5' : '2.4'} GHz',
                      ),
                      trailing: Text(
                        '${a.level} dBm',
                        textDirection: TextDirection.ltr,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
   