// lib/features/settings/data_management_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/database_service.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  Future<void> _exportData() async {
    try {
      final jsonString = await DatabaseService().exportDataAsJson();
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/gymini_logs.json';
      final file = File(path);
      await file.writeAsString(jsonString);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(path)],
          text: 'My Gymini Workout Logs',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : const Rect.fromLTWH(0, 0, 100, 100),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Export Failed: $e")));
      }
    }
  }

  Future<void> _clearAllData() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ Delete Everything?"),
        content: const Text(
            "This will permanently delete ALL your workout logs. This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("All records deleted.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Management")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Manage your workout history.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.blue),
            title: const Text("Export Logs"),
            subtitle: const Text("Save & Share JSON file"),
            onTap: _exportData,
            tileColor: Colors.grey[100],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            trailing: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 15),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Clear All Records",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: _clearAllData,
            tileColor: Colors.red[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }
}
