import 'package:flutter/material.dart';

const Color kBlue = Color(0xFF1565C0);
const Color kCyan = Color(0xFF00B0FF);

const Map<String, List<String>> kStrings = {
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
  'router': ['الراوتر', 'Router'],
  'none': ['لا توجد نتائج', 'No results'],
};

class AppState extends ChangeNotifier {
  bool ar = true;
  bool dark = false;
  String host = '8.8.8.8';

  String t(String k) {
    final v = kStrings[k];
    if (v == null) return k;
    return ar ? v[0] : v[1];
  }

  void update({bool? ar, bool? dark, String? host}) {
    if (ar != null) this.ar = ar;
    if (dark != null) this.dark = dark;
    if (host != null) this.host = host;
    notifyListeners();
  }
}
