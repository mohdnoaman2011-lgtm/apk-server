import 'dart:io';

const kPort = 8080;

class NetState {
  NetState(this.online, this.ip);
  final bool online;
  final String ip;
}

/// يقرأ حالة الشبكة بدون إضافات (تعمل داخل خدمة الخلفية أيضاً).
Future<NetState> readNet(String lastIp) async {
  try {
    final ifs = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    String? any, preferred;
    for (final i in ifs) {
      if (i.addresses.isEmpty) continue;
      final n = i.name.toLowerCase();
      any ??= i.addresses.first.address;
      if (n.contains('wlan') || n.contains('wifi') || n.startsWith('en') || n.startsWith('eth')) {
        preferred ??= i.addresses.first.address;
      }
    }
    final ip = preferred ?? any;
    return ip == null ? NetState(false, lastIp) : NetState(true, ip);
  } catch (_) {
    return NetState(true, lastIp);
  }
}
