import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MeetingItem {
  final String roomName;
  final int timestamp;

  MeetingItem({required this.roomName, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'roomName': roomName,
        'timestamp': timestamp,
      };

  factory MeetingItem.fromJson(Map<String, dynamic> json) => MeetingItem(
        roomName: json['roomName'] as String,
        timestamp: json['timestamp'] as int,
      );
}

class PrefsManager {
  static const _keyDisplayName = 'display_name';
  static const _keyAudioMuted = 'audio_muted';
  static const _keyVideoMuted = 'video_muted';
  static const _keyHistory = 'meeting_history';
  static const _maxHistory = 10;

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get displayName => _prefs.getString(_keyDisplayName) ?? '';
  set displayName(String value) => _prefs.setString(_keyDisplayName, value);

  bool get isAudioMuted => _prefs.getBool(_keyAudioMuted) ?? false;
  set isAudioMuted(bool value) => _prefs.setBool(_keyAudioMuted, value);

  bool get isVideoMuted => _prefs.getBool(_keyVideoMuted) ?? false;
  set isVideoMuted(bool value) => _prefs.setBool(_keyVideoMuted, value);

  List<MeetingItem> getMeetingHistory() {
    final json = _prefs.getString(_keyHistory) ?? '[]';
    final list = jsonDecode(json) as List;
    return list.map((e) => MeetingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  void addMeetingToHistory(String roomName) {
    final history = getMeetingHistory();
    history.removeWhere((item) => item.roomName == roomName);
    history.insert(0, MeetingItem(
      roomName: roomName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    final trimmed = history.take(_maxHistory).toList();
    _prefs.setString(_keyHistory, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  void clearHistory() {
    _prefs.remove(_keyHistory);
  }
}
