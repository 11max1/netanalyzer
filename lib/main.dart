import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'dash_page.dart';
import 'devices_page.dart';
import 'logo.dart';
import 'settings_page.dart';
import 'tools_page.dart';
import 'wifi_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const App(),
    ),
  );
}

ThemeData buildTheme(Brightness b) {
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: ColorScheme.fromSeed(seedColor: kBlue, brightness: b),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData(brightness: b).textTheme),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Abbas Abod Net',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
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

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    [Permission.locationWhenInUse, Permission.nearbyWifiDevices].request();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final List<Widget> pages = [
      DashPage(),
      ToolsPage(),
      DevicesPage(),
      WifiPage(),
      SettingsPage(),
    ];
    return Directionality(
      textDirection: s.ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Brand(), centerTitle: false),
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (v) => setState(() => index = v),
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.dashboard_rounded), label: s.t('home')),
            NavigationDestination(
                icon: const Icon(Icons.build_rounded), label: s.t('tools')),
            NavigationDestination(
                icon: const Icon(Icons.devices_rounded), label: s.t('devices')),
            NavigationDestination(
                icon: const Icon(Icons.wifi_rounded), label: s.t('wifi')),
            NavigationDestination(
                icon: const Icon(Icons.settings_rounded), label: s.t('settings')),
          ],
        ),
      ),
    );
  }
}
