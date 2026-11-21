import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import '../core/format.dart';
import '../core/i18n.dart';
import '../models/apk_app.dart';

/// السيرفر الشخصي:
///   GET /<token>               صفحة التحميل للزائر
///   GET /a/<id>/icon.png       أيقونة التطبيق
///   GET /a/<id>/download       ملف APK (?v=<index> لإصدار سابق)
class WebServer {
  WebServer({required this.getApps, required this.onDownload});

  final List<ApkApp> Function() getApps;
  final void Function(ApkApp) onDownload;
  HttpServer? _server;

  bool get running => _server != null;

  Future<void> start(int port) async {
    if (_server != null) return;
    _server = await io.serve(_handle, InternetAddress.anyIPv4, port, shared: true);
  }

  Future<void> stop() async {
    final s = _server;
    _server = null;
    await s?.close(force: true);
  }

  Future<Response> _handle(Request req) async {
    var s = req.url.pathSegments.where((x) => x.isNotEmpty).toList();
    if (s.isNotEmpty && s[0] == 'a') s = s.sublist(1); // دعم الروابط القديمة /a/<token>
    if (s.isEmpty) return Response.notFound('Not found');
    final app = getApps().where((a) => a.token == s[0] && a.enabled).firstOrNull;
    if (app == null) return Response.notFound(tr0('الرابط غير متاح'));

    if (s.length == 1) {
      return Response.ok(_page(app), headers: {'content-type': 'text/html; charset=utf-8'});
    }
    if (s[1] == 'icon.png') {
      final f = File(app.current.iconPath);
      if (!f.existsSync()) return Response.notFound('');
      return Response.ok(f.openRead(), headers: {
        'content-type': 'image/png',
        'cache-control': 'public, max-age=300',
      });
    }
    if (s[1] == 'download') {
      final i = int.tryParse(req.url.queryParameters['v'] ?? '0') ?? 0;
      final v = app.versions[i.clamp(0, app.versions.length - 1)];
      final f = File(v.apkPath);
      if (!f.existsSync()) return Response.notFound(tr0('الملف غير موجود'));
      onDownload(app);
      return Response.ok(f.openRead(), headers: {
        'content-type': 'application/vnd.android.package-archive',
        'content-length': '${f.lengthSync()}',
        'content-disposition': 'attachment; filename="${app.id}-${v.versionName}.apk"',
      });
    }
    return Response.notFound('Not found');
  }

  String _page(ApkApp a) {
    const e = HtmlEscape();
    final isAr = currentLang == AppLang.ar;
    final v = a.current;
    final old = [
      for (var i = 1; i < a.versions.length; i++)
        '<li><a href="/${a.token}/download?v=$i">v${e.convert(a.versions[i].versionName)}</a>'
            ' · ${fmtSize(a.versions[i].size)} · ${fmtDate(a.versions[i].date)}</li>'
    ].join();
    final notes = v.notes.isEmpty
        ? ''
        : '<div class="card"><b>${tr0('ما الجديد')}</b><br>${e.convert(v.notes)}</div>';
    final olds = old.isEmpty ? '' : '<div class="card"><b>${tr0('الإصدارات السابقة')}</b><ul>$old</ul></div>';
    return '''<!doctype html><html lang="${isAr ? 'ar' : 'en'}" dir="${isAr ? 'rtl' : 'ltr'}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;600;700&display=swap"><title>${e.convert(a.name)}</title>
<style>body{margin:0;background:#0A1830;color:#E8EEF7;font-family:'IBM Plex Sans Arabic',system-ui,sans-serif}
main{max-width:640px;margin:0 auto;padding:40px 20px;display:flex;flex-direction:column;gap:20px}
.ic{width:96px;height:96px;border-radius:26px}
.chip{background:#11223F;border:1px solid #1D3358;border-radius:99px;padding:6px 12px;font-size:14px}
.btn{background:#22E5C0;color:#04201B;border-radius:14px;padding:16px;text-align:center;font-weight:700;font-size:18px;text-decoration:none}
.card{background:#11223F;border:1px solid #1D3358;border-radius:16px;padding:16px;line-height:1.8}
.muted{color:#8CA2C2;font-size:14px;direction:ltr;text-align:${isAr ? 'right' : 'left'};margin:0}
a{color:#7CC4FF}</style></head><body><main>
<img class="ic" src="/${a.token}/icon.png" alt="">
<div><h1 style="margin:0 0 4px">${e.convert(a.name)}</h1><p class="muted">${e.convert(a.id)}</p></div>
<div style="display:flex;gap:8px;flex-wrap:wrap"><span class="chip">${tr0('الإصدار')} ${e.convert(v.versionName)}</span>
<span class="chip">${fmtSize(v.size)}</span><span class="chip">${fmtDate(v.date)}</span></div>
<a class="btn" href="/${a.token}/download">${tr0('تحميل APK')}</a>
$notes$olds
<div class="card" style="color:#FFD38A;font-size:14px">${tr0('للتثبيت، اسمح بالتثبيت من هذا المصدر عند ظهور التنبيه في الجهاز.')}</div>
</main></body></html>''';
  }
}
