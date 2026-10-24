import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'logo.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final List<PopupMenuEntry<String>> hosts = [];
    for (final h in ['8.8.8.8', '1.1.1.1', '9.9.9.9']) {
      hosts.add(PopupMenuItem<String>(value: h, child: Text(h)));
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        SwitchListTile(
          title: Text(s.t('lang')),
          secondary: const Icon(Icons.translate),
          value: s.ar,
          onChanged: (v) => s.update(ar: v),
        ),
        SwitchListTile(
          title: Text(s.t('dark')),
          secondary: const Icon(Icons.dark_mode),
          value: s.dark,
          onChanged: (v) => s.update(dark: v),
        ),
        ListTile(
          leading: const Icon(Icons.flag),
          title: Text(s.t('target')),
          subtitle: Text(s.host, textDirection: TextDirection.ltr),
          trailing: PopupMenuButton<String>(
            onSelected: (v) => s.update(host: v),
            itemBuilder: (context) => hosts,
          ),
        ),
        const Divider(height: 40),
        const Center(child: Logo(size: 90)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Abbas Abod',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kBlue,
            ),
          ),
        ),
        Center(child: Text(s.t('dev'))),
      ],
    );
  }
}
