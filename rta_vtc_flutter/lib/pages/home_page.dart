import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../services/prefs_manager.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _roomController = TextEditingController();
  final _jitsiMeet = JitsiMeet();
  final _prefsManager = PrefsManager();
  List<MeetingItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _prefsManager.init();
    _refreshHistory();
    setState(() => _isLoading = false);
  }

  void _refreshHistory() {
    setState(() {
      _history = _prefsManager.getMeetingHistory();
    });
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  void _onJoinTap() {
    final room = _roomController.text.trim();
    if (room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาใส่ชื่อห้องประชุม')),
      );
      return;
    }
    _showPreJoinDialog(room);
  }

  void _showPreJoinDialog(String room) {
    bool micOn = !_prefsManager.isAudioMuted;
    bool cameraOn = !_prefsManager.isVideoMuted;
    bool audioOnly = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('ตั้งค่าก่อนเข้าห้อง'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(room,
                    style: const TextStyle(
                        color: Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Row(children: [
                  Icon(Icons.mic, size: 20),
                  SizedBox(width: 8),
                  Text('เปิดไมค์'),
                ]),
                value: micOn,
                onChanged: (v) => setDialogState(() => micOn = v),
              ),
              SwitchListTile(
                title: const Row(children: [
                  Icon(Icons.videocam, size: 20),
                  SizedBox(width: 8),
                  Text('เปิดกล้อง'),
                ]),
                value: cameraOn,
                onChanged: audioOnly
                    ? null
                    : (v) => setDialogState(() => cameraOn = v),
              ),
              SwitchListTile(
                title: const Row(children: [
                  Icon(Icons.headphones, size: 20),
                  SizedBox(width: 8),
                  Text('เสียงอย่างเดียว'),
                ]),
                value: audioOnly,
                onChanged: (v) => setDialogState(() {
                  audioOnly = v;
                  if (v) cameraOn = false;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _launchConference(room, !micOn, !cameraOn, audioOnly);
              },
              icon: const Icon(Icons.login),
              label: const Text('เข้าร่วม'),
            ),
          ],
        ),
      ),
    );
  }

  void _launchConference(
      String room, bool audioMuted, bool videoMuted, bool audioOnly) {
    _prefsManager.addMeetingToHistory(room);
    _refreshHistory();

    final displayName = _prefsManager.displayName;

    final options = JitsiMeetConferenceOptions(
      serverURL: 'https://telemeet.rta.mi.th',
      room: room,
      configOverrides: {
        'startWithAudioMuted': audioMuted,
        'startWithVideoMuted': videoMuted || audioOnly,
        'startAudioOnly': audioOnly,
        'prejoinPageEnabled': false,
      },
      featureFlags: {
        'pip.enabled': true,
        'welcomepage.enabled': false,
        'unsaferoomwarning.enabled': false,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: displayName.isNotEmpty ? displayName : 'Guest',
      ),
    );

    _jitsiMeet.join(options, _buildListeners());
  }

  JitsiMeetEventListener _buildListeners() {
    return JitsiMeetEventListener(
      conferenceJoined: (url) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เข้าห้องประชุมแล้ว')),
          );
        }
      },
      conferenceTerminated: (url, error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ออกจากห้องประชุมแล้ว')),
          );
          _refreshHistory();
        }
      },
      participantJoined: (email, name, role, participantId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${name ?? "ผู้เข้าร่วม"} เข้าห้องแล้ว')),
          );
        }
      },
    );
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
        title: Row(
          children: [
            ClipOval(
              child: Image.asset('assets/rta_logo.png',
                  width: 36, height: 36, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RTA VTC',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text('ระบบประชุมทางไกล กองทัพบก',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()));
              await _prefsManager.init();
              _refreshHistory();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Join card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.videocam, color: Color(0xFF1B5E20), size: 20),
                        SizedBox(width: 8),
                        Text('เข้าร่วมประชุม',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B5E20))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _roomController,
                      decoration: InputDecoration(
                        hintText: 'ใส่ชื่อห้องประชุม',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onSubmitted: (_) => _onJoinTap(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _onJoinTap,
                        icon: const Icon(Icons.login),
                        label: const Text('เข้าร่วมประชุม'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // History card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history, color: Color(0xFF1B5E20), size: 20),
                        SizedBox(width: 8),
                        Text('ประวัติห้องประชุม',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B5E20))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('ยังไม่มีประวัติ',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        itemBuilder: (_, i) {
                          final item = _history[i];
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              item.timestamp);
                          final formatted =
                              DateFormat('dd/MM/yyyy HH:mm').format(date);
                          return ListTile(
                            leading: const Icon(Icons.meeting_room,
                                color: Color(0xFF2E7D32)),
                            title: Text(item.roomName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            subtitle: Text(formatted,
                                style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.grey),
                            onTap: () {
                              _roomController.text = item.roomName;
                              _showPreJoinDialog(item.roomName);
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Warning
            const Text(
              'This meeting is conducted over the internet.\n'
              'Discussion of classified or sensitive information is strictly prohibited.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Text(
              'RTA VTC v2.0.0 - wiwat_kh@rta.mi.th',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
