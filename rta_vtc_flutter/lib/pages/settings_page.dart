import 'package:flutter/material.dart';
import '../services/prefs_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _prefsManager = PrefsManager();
  bool _audioMuted = false;
  bool _videoMuted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _prefsManager.init();
    _nameController.text = _prefsManager.displayName;
    _audioMuted = _prefsManager.isAudioMuted;
    _videoMuted = _prefsManager.isVideoMuted;
    setState(() => _isLoading = false);
  }

  void _save() {
    _prefsManager.displayName = _nameController.text.trim();
    _prefsManager.isAudioMuted = _audioMuted;
    _prefsManager.isVideoMuted = _videoMuted;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกแล้ว')),
    );
    Navigator.pop(context);
  }

  void _clearHistory() {
    _prefsManager.clearHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ล้างประวัติแล้ว')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('ตั้งค่า'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person, color: Color(0xFF1B5E20), size: 20),
                        SizedBox(width: 8),
                        Text('ข้อมูลผู้ใช้',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B5E20))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อที่แสดง',
                        hintText: 'ใส่ชื่อ-นามสกุล',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Defaults card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune, color: Color(0xFF1B5E20), size: 20),
                        SizedBox(width: 8),
                        Text('ค่าเริ่มต้นเข้าห้องประชุม',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B5E20))),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('ปิดไมค์เมื่อเข้าห้อง'),
                      value: _audioMuted,
                      onChanged: (v) => setState(() => _audioMuted = v),
                    ),
                    SwitchListTile(
                      title: const Text('ปิดกล้องเมื่อเข้าห้อง'),
                      value: _videoMuted,
                      onChanged: (v) => setState(() => _videoMuted = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Data card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: Color(0xFF1B5E20), size: 20),
                        SizedBox(width: 8),
                        Text('ข้อมูล',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B5E20))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _clearHistory,
                        icon: const Icon(Icons.delete),
                        label: const Text('ล้างประวัติห้องประชุม'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('บันทึก'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
