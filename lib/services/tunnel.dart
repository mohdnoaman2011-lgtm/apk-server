import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

import '../core/i18n.dart';
import '../models/tunnel_config.dart';
import 'tunnel_key.dart';

/// نفق عكسي عبر SSH يمرّر الطلبات القادمة من الإنترنت إلى السيرفر المحلي.
class TunnelService {
  TunnelService(this.localPort);

  final int localPort;
  SSHClient? _client;

  static final _urlRe = RegExp(r'https://[a-z0-9-]+\.(?:lhr\.life|localhost\.run)');

  /// يفتح النفق ويعيد الرابط العام، و[closed] يكتمل عند انقطاع النفق.
  Future<({String url, Future<void> closed})> start(TunnelConfig c) async {
    await stop();
    final p = c.provider;
    final anonymous = p == TunnelProvider.localhostRun;

    final host = switch (p) {
      TunnelProvider.localhostRun => 'localhost.run',
      TunnelProvider.ngrok => 'connect.ngrok-agent.com',
      TunnelProvider.custom => c.host.trim(),
    };
    final port = p == TunnelProvider.custom ? c.port : 22;
    final user = switch (p) {
      TunnelProvider.localhostRun => 'nokey',
      TunnelProvider.ngrok => 'v2',
      TunnelProvider.custom => c.user.trim(),
    };
    final secret = p == TunnelProvider.ngrok ? c.ngrokToken.trim() : c.password;

    final socket = await SSHSocket.connect(host, port, timeout: const Duration(seconds: 15));
    final client = SSHClient(
      socket,
      username: user,
      identities: anonymous ? SSHKeyPair.fromPem(kTunnelKey) : null,
      onPasswordRequest: anonymous ? null : () => secret,
      keepAliveInterval: const Duration(seconds: 20),
    );
    _client = client;
    await client.authenticated;

    final String? bindHost = switch (p) {
      TunnelProvider.localhostRun => null,
      TunnelProvider.ngrok => c.ngrokHost,
      TunnelProvider.custom => 'localhost',
    };
    final bindPort = switch (p) {
      TunnelProvider.localhostRun => 80,
      TunnelProvider.ngrok => 443,
      TunnelProvider.custom => c.remotePort,
    };
    final forward = await client.forwardRemote(host: bindHost, port: bindPort);
    if (forward == null) throw tr0('رفض الخادم فتح النفق');
    forward.connections.listen(_bridge);

    final String url;
    switch (p) {
      case TunnelProvider.ngrok:
        url = 'https://${c.ngrokHost}';
        await _confirm(await client.execute('http'));
      case TunnelProvider.custom:
        url = c.publicUrl.trim();
        await _confirm(await client.shell());
      case TunnelProvider.localhostRun:
        url = await _readUrl(await client.shell());
    }
    return (url: url, closed: client.done.catchError((_) {}));
  }

  Future<void> stop() async {
    final c = _client;
    _client = null;
    c?.close();
  }

  /// يقرأ الرابط العام الذي يطبعه الخادم (localhost.run).
  Future<String> _readUrl(SSHSession s) {
    final found = Completer<String>();
    final buf = StringBuffer();
    s.stderr.listen((_) {});
    s.stdout.cast<List<int>>().transform(utf8.decoder).listen((chunk) {
      buf.write(chunk);
      final m = _urlRe.firstMatch(buf.toString());
      if (m != null && !found.isCompleted) found.complete(m.group(0)!);
    });
    return found.future.timeout(
      const Duration(seconds: 25),
      onTimeout: () => throw tr0('لم يصل رابط النفق من الخادم'),
    );
  }

  /// يتأكد أن الخادم لم يُغلق الجلسة فوراً (يحدث عند خطأ الرمز أو النطاق).
  Future<void> _confirm(SSHSession s) async {
    final out = StringBuffer();
    s.stdout.cast<List<int>>().transform(utf8.decoder).listen(out.write);
    s.stderr.cast<List<int>>().transform(utf8.decoder).listen(out.write);
    final closed = s.done.then<bool>((_) => true).catchError((_) => true);
    final early = await Future.any<bool>([
      closed,
      Future<bool>.delayed(const Duration(seconds: 3), () => false),
    ]);
    if (early) {
      final msg = out.toString().trim();
      throw msg.isEmpty ? tr0('أغلق الخادم الجلسة (تحقق من البيانات)') : msg;
    }
  }

  Future<void> _bridge(SSHForwardChannel channel) async {
    try {
      final local = await Socket.connect('127.0.0.1', localPort);
      channel.stream.cast<List<int>>().pipe(local).catchError((_) {});
      local.cast<List<int>>().pipe(channel.sink).catchError((_) {});
    } catch (_) {
      channel.close();
    }
  }
}
