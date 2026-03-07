package com.rta.vtc;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.material.button.MaterialButton;
import com.google.android.material.switchmaterial.SwitchMaterial;
import com.google.android.material.textfield.TextInputEditText;

import org.jitsi.meet.sdk.BroadcastEvent;
import org.jitsi.meet.sdk.JitsiMeet;
import org.jitsi.meet.sdk.JitsiMeetActivity;
import org.jitsi.meet.sdk.JitsiMeetConferenceOptions;
import org.jitsi.meet.sdk.JitsiMeetUserInfo;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.List;

public class MainActivity extends AppCompatActivity {

    private TextInputEditText editRoomName;
    private RecyclerView recyclerHistory;
    private TextView txtHistoryEmpty;
    private MeetingHistoryAdapter historyAdapter;
    private PrefsManager prefsManager;
    private BroadcastReceiver broadcastReceiver;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        prefsManager = new PrefsManager(this);

        // Setup server URL
        URL serverURL;
        try {
            serverURL = new URL("https://telemeet.rta.mi.th");
        } catch (MalformedURLException e) {
            e.printStackTrace();
            throw new RuntimeException("Invalid server URL!");
        }

        JitsiMeetConferenceOptions defaultOptions =
                new JitsiMeetConferenceOptions.Builder()
                        .setServerURL(serverURL)
                        .build();
        JitsiMeet.setDefaultConferenceOptions(defaultOptions);

        // UI references
        editRoomName = findViewById(R.id.roomName);
        recyclerHistory = findViewById(R.id.recyclerHistory);
        txtHistoryEmpty = findViewById(R.id.txtHistoryEmpty);

        // Settings button
        findViewById(R.id.btnSettings).setOnClickListener(v ->
                startActivity(new Intent(this, SettingsActivity.class)));

        // Join button
        MaterialButton btnJoin = findViewById(R.id.btnJoin);
        btnJoin.setOnClickListener(v -> onJoinClick());

        // Setup history RecyclerView
        recyclerHistory.setLayoutManager(new LinearLayoutManager(this));
        historyAdapter = new MeetingHistoryAdapter(prefsManager.getMeetingHistory(),
                roomName -> {
                    editRoomName.setText(roomName);
                    onJoinClick();
                });
        recyclerHistory.setAdapter(historyAdapter);

        // Register broadcast receiver for conference events
        registerBroadcastReceiver();
    }

    @Override
    protected void onResume() {
        super.onResume();
        refreshHistory();
    }

    @Override
    protected void onDestroy() {
        if (broadcastReceiver != null) {
            LocalBroadcastManager.getInstance(this).unregisterReceiver(broadcastReceiver);
        }
        super.onDestroy();
    }

    private void onJoinClick() {
        String room = editRoomName.getText() != null
                ? editRoomName.getText().toString().trim() : "";

        if (room.isEmpty()) {
            Toast.makeText(this, R.string.error_empty_room, Toast.LENGTH_SHORT).show();
            return;
        }

        showPreJoinDialog(room);
    }

    private void showPreJoinDialog(String room) {
        View dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_prejoin, null);
        SwitchMaterial switchMic = dialogView.findViewById(R.id.switchMic);
        SwitchMaterial switchCamera = dialogView.findViewById(R.id.switchCamera);
        SwitchMaterial switchAudioOnly = dialogView.findViewById(R.id.switchAudioOnly);

        // Load defaults from settings
        switchMic.setChecked(!prefsManager.isAudioMuted());
        switchCamera.setChecked(!prefsManager.isVideoMuted());

        // Audio only disables camera
        switchAudioOnly.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked) {
                switchCamera.setChecked(false);
                switchCamera.setEnabled(false);
            } else {
                switchCamera.setEnabled(true);
            }
        });

        new AlertDialog.Builder(this)
                .setView(dialogView)
                .setPositiveButton(R.string.prejoin_join, (dialog, which) -> {
                    boolean micOn = switchMic.isChecked();
                    boolean cameraOn = switchCamera.isChecked();
                    boolean audioOnly = switchAudioOnly.isChecked();
                    launchConference(room, !micOn, !cameraOn, audioOnly);
                })
                .setNegativeButton(R.string.prejoin_cancel, null)
                .show();
    }

    private void launchConference(String room, boolean audioMuted, boolean videoMuted, boolean audioOnly) {
        // Save to history
        prefsManager.addMeetingToHistory(room);

        // Build user info
        JitsiMeetUserInfo userInfo = new JitsiMeetUserInfo();
        String displayName = prefsManager.getDisplayName();
        if (!displayName.isEmpty()) {
            userInfo.setDisplayName(displayName);
        }

        // Build conference options
        JitsiMeetConferenceOptions.Builder builder = new JitsiMeetConferenceOptions.Builder()
                .setRoom(room)
                .setAudioMuted(audioMuted)
                .setVideoMuted(videoMuted)
                .setFeatureFlag("pip.enabled", true)
                .setFeatureFlag("welcomepage.enabled", false)
                .setUserInfo(userInfo);

        if (audioOnly) {
            builder.setAudioOnly(true);
        }

        JitsiMeetActivity.launch(this, builder.build());
    }

    private void refreshHistory() {
        List<PrefsManager.MeetingItem> history = prefsManager.getMeetingHistory();
        historyAdapter.updateItems(history);

        if (history.isEmpty()) {
            txtHistoryEmpty.setVisibility(View.VISIBLE);
            recyclerHistory.setVisibility(View.GONE);
        } else {
            txtHistoryEmpty.setVisibility(View.GONE);
            recyclerHistory.setVisibility(View.VISIBLE);
        }
    }

    private void registerBroadcastReceiver() {
        broadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                onBroadcastReceived(intent);
            }
        };

        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(BroadcastEvent.Type.CONFERENCE_JOINED.getAction());
        intentFilter.addAction(BroadcastEvent.Type.CONFERENCE_TERMINATED.getAction());

        LocalBroadcastManager.getInstance(this)
                .registerReceiver(broadcastReceiver, intentFilter);
    }

    private void onBroadcastReceived(Intent intent) {
        if (intent.getAction() == null) return;

        BroadcastEvent event = new BroadcastEvent(intent);
        switch (event.getType()) {
            case CONFERENCE_JOINED:
                runOnUiThread(() ->
                        Toast.makeText(this, R.string.event_joined, Toast.LENGTH_SHORT).show());
                break;
            case CONFERENCE_TERMINATED:
                runOnUiThread(() -> {
                    Toast.makeText(this, R.string.event_terminated, Toast.LENGTH_SHORT).show();
                    refreshHistory();
                });
                break;
        }
    }
}
