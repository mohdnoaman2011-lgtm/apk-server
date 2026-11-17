import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../state/app_store.dart';

Future<void> uploadApk(BuildContext context) async {
  store.setPicking(true);
  FilePickerResult? r;
  try {
    r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['apk']);
  } finally {
    store.setPicking(false);
  }
  final path = r?.files.single.path;
  if (path == null || !context.mounted) return;

  final notes = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('ما الجديد في هذا الإصدار؟'),
      content: TextField(controller: notes, decoration: const InputDecoration(hintText: 'اختياري')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('رفع')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  String msg;
  try {
    final a = await store.addApk(path, notes: notes.text.trim());
    msg = 'تم رفع ${a.name} (v${a.current.versionName})';
  } catch (e) {
    msg = 'تعذّر الرفع: $e';
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  messenger.showSnackBar(SnackBar(content: Text(msg)));
  await FilePicker.platform.clearTemporaryFiles();
}
