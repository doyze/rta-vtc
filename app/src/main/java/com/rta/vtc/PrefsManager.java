package com.rta.vtc;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;

public class PrefsManager {
    private static final String PREFS_NAME = "rta_vtc_prefs";
    private static final String KEY_DISPLAY_NAME = "display_name";
    private static final String KEY_MEETING_HISTORY = "meeting_history";
    private static final String KEY_AUDIO_MUTED = "audio_muted";
    private static final String KEY_VIDEO_MUTED = "video_muted";
    private static final int MAX_HISTORY = 10;

    private final SharedPreferences prefs;
    private final Gson gson;

    public PrefsManager(Context context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        gson = new Gson();
    }

    public void setDisplayName(String name) {
        prefs.edit().putString(KEY_DISPLAY_NAME, name).apply();
    }

    public String getDisplayName() {
        return prefs.getString(KEY_DISPLAY_NAME, "");
    }

    public void setAudioMuted(boolean muted) {
        prefs.edit().putBoolean(KEY_AUDIO_MUTED, muted).apply();
    }

    public boolean isAudioMuted() {
        return prefs.getBoolean(KEY_AUDIO_MUTED, false);
    }

    public void setVideoMuted(boolean muted) {
        prefs.edit().putBoolean(KEY_VIDEO_MUTED, muted).apply();
    }

    public boolean isVideoMuted() {
        return prefs.getBoolean(KEY_VIDEO_MUTED, false);
    }

    public void addMeetingToHistory(String roomName) {
        List<MeetingItem> history = getMeetingHistory();
        // Remove if already exists
        history.removeIf(item -> item.roomName.equals(roomName));
        // Add to top
        history.add(0, new MeetingItem(roomName, System.currentTimeMillis()));
        // Limit size
        if (history.size() > MAX_HISTORY) {
            history = new ArrayList<>(history.subList(0, MAX_HISTORY));
        }
        prefs.edit().putString(KEY_MEETING_HISTORY, gson.toJson(history)).apply();
    }

    public List<MeetingItem> getMeetingHistory() {
        String json = prefs.getString(KEY_MEETING_HISTORY, "[]");
        Type type = new TypeToken<ArrayList<MeetingItem>>() {}.getType();
        List<MeetingItem> list = gson.fromJson(json, type);
        return list != null ? new ArrayList<>(list) : new ArrayList<>();
    }

    public void clearHistory() {
        prefs.edit().remove(KEY_MEETING_HISTORY).apply();
    }

    public static class MeetingItem {
        public String roomName;
        public long timestamp;

        public MeetingItem(String roomName, long timestamp) {
            this.roomName = roomName;
            this.timestamp = timestamp;
        }
    }
}
