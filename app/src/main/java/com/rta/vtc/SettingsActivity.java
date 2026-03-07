package com.rta.vtc;

import android.os.Bundle;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.material.appbar.MaterialToolbar;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.switchmaterial.SwitchMaterial;
import com.google.android.material.textfield.TextInputEditText;

public class SettingsActivity extends AppCompatActivity {

    private TextInputEditText editDisplayName;
    private SwitchMaterial switchAudioMuted;
    private SwitchMaterial switchVideoMuted;
    private PrefsManager prefsManager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);

        prefsManager = new PrefsManager(this);

        MaterialToolbar toolbar = findViewById(R.id.toolbar);
        toolbar.setNavigationOnClickListener(v -> finish());

        editDisplayName = findViewById(R.id.editDisplayName);
        switchAudioMuted = findViewById(R.id.switchAudioMuted);
        switchVideoMuted = findViewById(R.id.switchVideoMuted);

        // Load saved values
        editDisplayName.setText(prefsManager.getDisplayName());
        switchAudioMuted.setChecked(prefsManager.isAudioMuted());
        switchVideoMuted.setChecked(prefsManager.isVideoMuted());

        MaterialButton btnSave = findViewById(R.id.btnSave);
        btnSave.setOnClickListener(v -> saveSettings());

        MaterialButton btnClearHistory = findViewById(R.id.btnClearHistory);
        btnClearHistory.setOnClickListener(v -> {
            prefsManager.clearHistory();
            Toast.makeText(this, R.string.history_cleared, Toast.LENGTH_SHORT).show();
        });
    }

    private void saveSettings() {
        String name = editDisplayName.getText() != null ? editDisplayName.getText().toString().trim() : "";
        prefsManager.setDisplayName(name);
        prefsManager.setAudioMuted(switchAudioMuted.isChecked());
        prefsManager.setVideoMuted(switchVideoMuted.isChecked());
        Toast.makeText(this, R.string.settings_saved, Toast.LENGTH_SHORT).show();
        finish();
    }
}
