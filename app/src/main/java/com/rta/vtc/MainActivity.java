package com.rta.vtc;

import android.os.Bundle;
import android.view.View;
import android.widget.EditText;

import androidx.appcompat.app.AppCompatActivity;

import org.jitsi.meet.sdk.JitsiMeet;
import org.jitsi.meet.sdk.JitsiMeetActivity;
import org.jitsi.meet.sdk.JitsiMeetConferenceOptions;

import java.net.MalformedURLException;
import java.net.URL;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

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
    }

    public void onJoinClick(View v) {
        EditText editText = findViewById(R.id.roomName);
        String room = editText.getText().toString().trim();

        if (!room.isEmpty()) {
            JitsiMeetConferenceOptions options =
                    new JitsiMeetConferenceOptions.Builder()
                            .setRoom(room)
                            .setAudioMuted(false)
                            .setVideoMuted(false)
                            .setFeatureFlag("pip.enabled", true)
                            .setFeatureFlag("welcomepage.enabled", false)
                            .build();
            JitsiMeetActivity.launch(this, options);
        }
    }
}
