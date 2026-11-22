import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

import '../core/i18n.dart';
import '../models/tunnel_config.dart';
import 'tunnel_key.dart';

/// نفق عكسي عبر SSH يمرّر الطلبات القادمة من الإنترنت إلى السيرفر المحلي.
/// كل مرحلة لها مهلة وسجل، فيظهر سبب الفشل بدقة (اتصال / مصادقة / فتح المنفذ / انتظار الرابط).
class TunnelService {
  TunnelService(this.localPort, {this.onLog});

  final int localPort;
  final void Function(String)? onLog;
  SSHClient? _client;

  static final _anyUrl = RegExp(r"https?://[^\s'<>)\]]+");
  // روابط تظهر في رسائل الخادم لكنها ليست رابط النفق
  static const _ignoreHosts = {
    'admin.localhost.run',
    'localhost.run',
    'www.localhost.run',
    'dashboard.pinggy.io',
    'pinggy.io',
    'www.pinggy.io',
  };
  static const _okSuffix = ['lhr.life', 'pinggy.link', 'pinggy.online', 'pinggy.io', 'localhost.run'];

  /// يختار رابط النفق الحقيقي (https) من نص الخادم.
  String? _pickUrl(String text) {
    for (final m in _anyUrl.allMatches(text)) {
      final u = m.group(0)!.replaceAll(RegExp(r'[.,;:]+$'), '');
      final uri = Uri.tryParse(u);
      if (uri == null || uri.host.isEmpty || uri.scheme != 'https') continue;
      final h = uri.host.toLowerCase();
      if (_ignoreHosts.contains(h)) continue;
      if (!_okSuffix.any((x) => h == x || h.endsWith('.$x'))) continue;
      return 'https://$h';
    }
    return null;
  }

  void _log(String m) => onLog?.call(m);

  Future<T> _stage<T>(String name, Future<T> f, int seconds) async {
    _log('> $name');
    try {
      final v = await f.timeout(Duration(seconds: seconds));
      _log('OK $name');
      return v;
    } on TimeoutException {
      _log('FAIL $name: timeout ${seconds}s');
      throw '${tr0('انتهت المهلة في خطوة')}: $name';
    } catch (e) {
      _log('FAIL $name: $e');
      throw '$name: $e';
    }
  }

  /// يفتح النفق ويعيد الرابط العام، و[closed] يكتمل عند انقطاع النفق.
  Future<({String url, Future<void> closed})> start(TunnelConfig c) async {
    await stop();
    final p = c.provider;
    final anonymous = p == TunnelProvider.localhostRun || p == TunnelProvider.pinggy;

    final host = switch (p) {
      TunnelProvider.localhostRun => 'localhost.run',
      TunnelProvider.pinggy => 'a.pinggy.io',
      TunnelProvider.ngrok => 'connect.ngrok-agent.com',
      TunnelProvider.custom => c.host.trim(),
    };
    final port = switch (p) {
      TunnelProvider.pinggy => 443,
      TunnelProvider.custom => c.port,
      _ => 22,
    };
    final user = switch (p) {
      TunnelProvider.localhostRun => 'nokey',
      TunnelProvider.pinggy => 'a',
      TunnelProvider.ngrok => 'v2',
      TunnelProvider.custom => c.user.trim(),
    };
    final secret = p == TunnelProvider.ngrok ? c.ngrokToken.trim() : c.password;
    _log('provider=${p.name} $user@$host:$port');

    final socket = await _stage(
      'TCP connect $host:$port',
      SSHSocket.connect(host, port, timeout: const Duration(seconds: 10)),
      12,
    );
    final client = SSHClient(
      socket,
      username: user,
      identities: anonymous ? SSHKeyPair.fromPem(kTunnelKey) : null,
      onPasswordRequest: p == TunnelProvider.localhostRun ? null : () => secret,
      keepAliveInterval: const Duration(seconds: 20),
    );
    _client = client;
    await _stage('SSH authenticate', client.authenticated, 15);

    final String? bindHost = switch (p) {
      TunnelProvider.localhostRun => null,
      TunnelProvider.pinggy => 'localhost',
      TunnelProvider.ngrok => c.ngrokHost,
      TunnelProvider.custom => 'localhost',
    };
    final bindPort = switch (p) {
      TunnelProvider.localhostRun => 80,
      TunnelProvider.pinggy => 0,
      TunnelProvider.ngrok => 443,
      TunnelProvider.custom => c.remotePort,
    };
    final forward = await _stage(
      'remote forward ${bindHost ?? ''}:$bindPort',
      client.forwardRemote(host: bindHost, port: bindPort),
      10,
    );
    if (forward == null) {
      _log('FAIL server refused forward');
      throw tr0('رفض الخادم فتح النفق');
    }
    forward.connections.listen(_bridge);

    final String url;
    switch (p) {
      case TunnelProvider.ngrok:
        url = 'https://${c.ngrokHost}';
        await _confirm(await _stage('open exec http', client.execute('http'), 10));
      case TunnelProvider.custom:
        url = c.publicUrl.trim();
        await _confirm(await _stage('open shell', client.shell(), 10));
      case TunnelProvider.localhostRun || TunnelProvider.pinggy:
        final shell = await _stage('open shell', client.shell(), 10);
        url = await _stage('wait for public URL', _readUrl(shell), 20);
    }
    _log('URL $url');
    return (
      url: url,
      closed: client.done.catchError((_) {}).whenComplete(() => _log('connection closed')),
    );
  }

  Future<void> stop() async {
    final c = _client;
    _client = null;
    c?.close();
  }

  String _short(String s) {
    final t = s.replaceAll(RegExp(r'\x1B\[[0-9;]*[A-Za-z]'), '').trim();
    return t.length > 220 ? '${t.substring(0, 220)}…' : t;
  }

  /// يقرأ الرابط العام الذي يطبعه الخادم في الجلسة.
  Future<String> _readUrl(SSHSession s) {
    final found = Completer<String>();
    final buf = StringBuffer();
    s.stderr.listen((_) {});
    s.stdout.cast<List<int>>().transform(utf8.decoder).listen((chunk) {
      _log('server: ${_short(chunk)}');
      buf.write(chunk);
      final u = _pickUrl(buf.toString());
      if (u != null && !found.isCompleted) found.complete(u);
    });
    return found.future;
  }

  /// يتأكد أن الخادم لم يُغلق الجلسة فوراً (يحدث عند خطأ الرمز أو النطاق).
  Future<void> _confirm(SSHSession s) async {
    final out = StringBuffer();
    s.stdout.cast<List<int>>().transform(utf8.decoder).listen((t) {
      out.write(t);
      _log('server: ${_short(t)}');
    });
    s.stderr.cast<List<int>>().transform(utf8.decoder).listen((t) {
      out.write(t);
      _log('server(err): ${_short(t)}');
    });
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
    _log('incoming connection -> local:$localPort');
    try {
      final local = await Socket.connect('127.0.0.1', localPort);
      channel.stream.cast<List<int>>().pipe(local).catchError((_) {});
      local.cast<List<int>>().pipe(channel.sink).catchError((_) {});
    } catch (e) {
      _log('bridge error: $e');
      channel.close();
    }
  }
}
