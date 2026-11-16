// android/app/src/main/kotlin/<مسار-الحزمة-الخاصة-بك>/MainActivity.kt
// غيّر السطر الأول إلى اسم حزمة مشروعك
package com.example.apk_server

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "apk_reader")
            .setMethodCallHandler { call, result ->
                if (call.method != "read") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")!!
                val iconOut = call.argument<String>("iconOut")!!
                Thread {
                    try {
                        val pm = packageManager
                        val info = pm.getPackageArchiveInfo(path, 0)
                        val ai = info?.applicationInfo
                        if (info == null || ai == null) {
                            runOnUiThread { result.error("BAD_APK", "ملف APK غير صالح", null) }
                            return@Thread
                        }
                        ai.sourceDir = path
                        ai.publicSourceDir = path
                        val label = ai.loadLabel(pm).toString()
                        val bmp = toBitmap(ai.loadIcon(pm))
                        FileOutputStream(iconOut).use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
                        val code = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode
                                   else info.versionCode.toLong()
                        val map = hashMapOf<String, Any>(
                            "name" to label,
                            "package" to info.packageName,
                            "versionName" to (info.versionName ?: code.toString()),
                            "versionCode" to code
                        )
                        runOnUiThread { result.success(map) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("READ_FAILED", e.message, null) }
                    }
                }.start()
            }
    }

    private fun toBitmap(d: Drawable): Bitmap {
        if (d is BitmapDrawable && d.bitmap != null) return d.bitmap
        val w = if (d.intrinsicWidth > 0) d.intrinsicWidth else 192
        val h = if (d.intrinsicHeight > 0) d.intrinsicHeight else 192
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        d.setBounds(0, 0, c.width, c.height)
        d.draw(c)
        return bmp
    }
}
