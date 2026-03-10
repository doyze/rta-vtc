// RTA VTC PWA - app.js
const JITSI_SERVER = 'telemeet.rta.mi.th';
const STORAGE_KEYS = {
    displayName: 'rtavtc_displayName',
    startMuted: 'rtavtc_startMuted',
    startCameraOff: 'rtavtc_startCameraOff',
    history: 'rtavtc_history'
};
const MAX_HISTORY = 20;

let jitsiApi = null;
let deferredPrompt = window.__pwaInstallPrompt || null;

// --- DOM Elements ---
const $ = id => document.getElementById(id);

const els = {
    pageMain: $('pageMain'),
    pageSettings: $('pageSettings'),
    roomName: $('roomName'),
    btnJoin: $('btnJoin'),
    btnSettings: $('btnSettings'),
    btnBack: $('btnBack'),
    btnSave: $('btnSave'),
    btnClearHistory: $('btnClearHistory'),
    displayName: $('displayName'),
    startMuted: $('startMuted'),
    startCameraOff: $('startCameraOff'),
    historyList: $('historyList'),
    prejoinOverlay: $('prejoinOverlay'),
    prejoinRoom: $('prejoinRoom'),
    prejoinMic: $('prejoinMic'),
    prejoinCamera: $('prejoinCamera'),
    prejoinAudioOnly: $('prejoinAudioOnly'),
    prejoinCancel: $('prejoinCancel'),
    prejoinJoin: $('prejoinJoin'),
    conferenceContainer: $('conferenceContainer'),
    toast: $('toast')
};

// --- Storage ---
function loadSetting(key, defaultVal = '') {
    return localStorage.getItem(key) ?? defaultVal;
}

function saveSetting(key, val) {
    localStorage.setItem(key, val);
}

function loadHistory() {
    try {
        return JSON.parse(localStorage.getItem(STORAGE_KEYS.history)) || [];
    } catch {
        return [];
    }
}

function saveHistory(history) {
    localStorage.setItem(STORAGE_KEYS.history, JSON.stringify(history));
}

function addToHistory(roomName) {
    let history = loadHistory();
    // Remove duplicate
    history = history.filter(h => h.room !== roomName);
    // Add to front
    history.unshift({
        room: roomName,
        date: new Date().toISOString()
    });
    // Limit
    if (history.length > MAX_HISTORY) {
        history = history.slice(0, MAX_HISTORY);
    }
    saveHistory(history);
    renderHistory();
}

// --- UI ---
function showPage(page) {
    els.pageMain.classList.remove('active');
    els.pageSettings.classList.remove('active');
    page.classList.add('active');
}

function showToast(msg) {
    els.toast.textContent = msg;
    els.toast.classList.remove('hidden');
    setTimeout(() => els.toast.classList.add('hidden'), 2500);
}

function formatDate(isoStr) {
    const d = new Date(isoStr);
    const day = d.toLocaleDateString('th-TH', { day: 'numeric', month: 'short', year: '2-digit' });
    const time = d.toLocaleTimeString('th-TH', { hour: '2-digit', minute: '2-digit' });
    return `${day} ${time}`;
}

function renderHistory() {
    const history = loadHistory();
    if (history.length === 0) {
        els.historyList.innerHTML = '<div class="empty-state">ยังไม่มีประวัติ</div>';
        return;
    }
    els.historyList.innerHTML = history.map(h => `
        <div class="history-item" data-room="${h.room}">
            <span class="material-icons">meeting_room</span>
            <div class="history-item-info">
                <div class="history-item-name">${escapeHtml(h.room)}</div>
                <div class="history-item-date">${formatDate(h.date)}</div>
            </div>
            <span class="material-icons" style="color:var(--text-secondary)">chevron_right</span>
        </div>
    `).join('');

    // Click handlers
    els.historyList.querySelectorAll('.history-item').forEach(item => {
        item.addEventListener('click', () => {
            els.roomName.value = item.dataset.room;
            showPrejoin(item.dataset.room);
        });
    });
}

function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// --- Settings ---
function loadSettingsUI() {
    els.displayName.value = loadSetting(STORAGE_KEYS.displayName);
    els.startMuted.checked = loadSetting(STORAGE_KEYS.startMuted) === 'true';
    els.startCameraOff.checked = loadSetting(STORAGE_KEYS.startCameraOff) === 'true';
}

function saveSettings() {
    saveSetting(STORAGE_KEYS.displayName, els.displayName.value.trim());
    saveSetting(STORAGE_KEYS.startMuted, els.startMuted.checked);
    saveSetting(STORAGE_KEYS.startCameraOff, els.startCameraOff.checked);
    showToast('บันทึกแล้ว');
    showPage(els.pageMain);
}

// --- Pre-join Dialog ---
function showPrejoin(roomName) {
    els.prejoinRoom.textContent = roomName;
    // Apply saved defaults
    els.prejoinMic.checked = loadSetting(STORAGE_KEYS.startMuted) !== 'true';
    els.prejoinCamera.checked = loadSetting(STORAGE_KEYS.startCameraOff) !== 'true';
    els.prejoinAudioOnly.checked = false;
    els.prejoinOverlay.classList.remove('hidden');
}

function hidePrejoin() {
    els.prejoinOverlay.classList.add('hidden');
}

// --- Jitsi Conference ---
function startConference(roomName) {
    const displayName = loadSetting(STORAGE_KEYS.displayName) || 'Guest';
    const micOn = els.prejoinMic.checked;
    const cameraOn = els.prejoinCamera.checked;
    const audioOnly = els.prejoinAudioOnly.checked;

    els.conferenceContainer.classList.remove('hidden');
    els.conferenceContainer.innerHTML = '';

    const options = {
        roomName: roomName,
        parentNode: els.conferenceContainer,
        width: '100%',
        height: '100%',
        userInfo: {
            displayName: displayName
        },
        configOverwrite: {
            startWithAudioMuted: !micOn,
            startWithVideoMuted: !cameraOn || audioOnly,
            startAudioOnly: audioOnly,
            prejoinPageEnabled: false,
            disableDeepLinking: true
        },
        interfaceConfigOverwrite: {
            MOBILE_APP_PROMO: false,
            SHOW_JITSI_WATERMARK: false
        }
    };

    try {
        jitsiApi = new JitsiMeetExternalAPI(JITSI_SERVER, options);

        // Event listeners
        jitsiApi.addListener('readyToClose', () => {
            endConference();
            showToast('ออกจากห้องประชุมแล้ว');
        });

        jitsiApi.addListener('videoConferenceJoined', () => {
            showToast('เข้าห้องประชุมแล้ว');
        });

        jitsiApi.addListener('participantJoined', (participant) => {
            showToast(`${participant.displayName || 'ผู้เข้าร่วม'} เข้าห้องแล้ว`);
        });

        // Save to history
        addToHistory(roomName);
    } catch (err) {
        console.error('Failed to start conference:', err);
        els.conferenceContainer.classList.add('hidden');
        showToast('ไม่สามารถเชื่อมต่อได้');
    }
}

function endConference() {
    if (jitsiApi) {
        jitsiApi.dispose();
        jitsiApi = null;
    }
    els.conferenceContainer.classList.add('hidden');
    els.conferenceContainer.innerHTML = '';
}

// --- PWA Install ---
window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    updateInstallBanner();
});

window.addEventListener('appinstalled', () => {
    deferredPrompt = null;
    const banner = document.querySelector('.install-banner');
    if (banner) banner.remove();
    showToast('ติดตั้งแล้ว');
});

function isStandalone() {
    return window.matchMedia('(display-mode: standalone)').matches
        || window.navigator.standalone === true;
}

function showInstallBanner() {
    // Don't show if already installed as PWA
    if (isStandalone()) return;
    if (document.querySelector('.install-banner')) return;

    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const banner = document.createElement('div');
    banner.className = 'install-banner';
    banner.innerHTML = `
        <span class="material-icons">install_mobile</span>
        <div class="install-banner-text">
            <strong>ติดตั้ง RTA VTC</strong><br>
            <small id="installHint">${isIOS
                ? 'กด <span class="material-icons" style="font-size:14px;vertical-align:middle">ios_share</span> แล้วเลือก "Add to Home Screen"'
                : 'เพิ่มแอปบนหน้าจอหลัก'
            }</small>
        </div>
        <button id="btnInstall">${deferredPrompt ? 'ติดตั้ง' : (isIOS ? 'วิธีทำ' : 'ติดตั้ง')}</button>
    `;
    els.pageMain.insertBefore(banner, els.pageMain.firstChild);

    document.getElementById('btnInstall').addEventListener('click', async () => {
        if (deferredPrompt) {
            deferredPrompt.prompt();
            const result = await deferredPrompt.userChoice;
            if (result.outcome === 'accepted') {
                showToast('ติดตั้งแล้ว');
            }
            deferredPrompt = null;
            banner.remove();
        } else if (isIOS) {
            showToast('กด Share แล้วเลือก "Add to Home Screen"');
        } else {
            // Chrome: use menu > Install app
            showToast('กดเมนู ⋮ แล้วเลือก "ติดตั้งแอป"');
        }
    });
}

function updateInstallBanner() {
    const btn = document.getElementById('btnInstall');
    if (btn) {
        btn.textContent = 'ติดตั้ง';
    } else {
        showInstallBanner();
    }
}

// --- Event Listeners ---
els.btnJoin.addEventListener('click', () => {
    const room = els.roomName.value.trim();
    if (!room) {
        showToast('กรุณาใส่ชื่อห้องประชุม');
        els.roomName.focus();
        return;
    }
    showPrejoin(room);
});

els.roomName.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') els.btnJoin.click();
});

els.btnSettings.addEventListener('click', () => {
    loadSettingsUI();
    showPage(els.pageSettings);
});

els.btnBack.addEventListener('click', () => {
    showPage(els.pageMain);
});

els.btnSave.addEventListener('click', saveSettings);

els.btnClearHistory.addEventListener('click', () => {
    localStorage.removeItem(STORAGE_KEYS.history);
    renderHistory();
    showToast('ล้างประวัติแล้ว');
});

els.prejoinCancel.addEventListener('click', hidePrejoin);

els.prejoinJoin.addEventListener('click', () => {
    const room = els.prejoinRoom.textContent;
    hidePrejoin();
    startConference(room);
});

// Audio only disables camera
els.prejoinAudioOnly.addEventListener('change', () => {
    if (els.prejoinAudioOnly.checked) {
        els.prejoinCamera.checked = false;
        els.prejoinCamera.disabled = true;
    } else {
        els.prejoinCamera.disabled = false;
    }
});

// --- Init ---
renderHistory();
showInstallBanner();

// Register Service Worker
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('sw.js').catch(err => {
        console.log('SW registration failed:', err);
    });
}
