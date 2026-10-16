
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="theme-color" content="#080a10">
<title>DarkGPT AI</title>

<style>
:root {
  --bg: #080a10;
  --panel: #141824;
  --blue: #3988ff;
  --text: #f4f6ff;
  --muted: #929bb0;
}
* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: Arial, sans-serif;
  background: var(--bg);
  color: var(--text);
  min-height: 100dvh;
}

.app {
  max-width: 900px;
  height: 100dvh;
  margin: auto;
  display: flex;
  flex-direction: column;
  padding: 14px;
}

header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding-bottom: 15px;
  border-bottom: 1px solid #252b3a;
}

.brand h1 {
  font-size: 23px;
  margin: 0;
  color: white;
  text-shadow: 0 0 16px #3988ff66;
}
.brand p {
  margin: 5px 0 0;
  color: var(--blue);
  font-size: 12px;
}

button, select, textarea { font: inherit; }

button, select {
  color: var(--text);
  background: var(--panel);
  border: 1px solid #293247;
  border-radius: 12px;
  padding: 11px;
}

button { cursor: pointer; }
button:disabled { opacity: .5; cursor: default; }

.toolbar {
  display: flex;
  gap: 8px;
  padding: 12px 0;
}
.toolbar select { flex: 1; min-width: 0; }

#chat {
  flex: 1;
  overflow-y: auto;
  padding: 15px 2px;
  display: flex;
  flex-direction: column;
  gap: 15px;
  scroll-behavior: smooth;
}

.welcome {
  text-align: center;
  margin: auto;
  padding: 24px 10px;
}
.logo {
  width: 76px;
  height: 76px;
  margin: auto auto 18px;
  display: grid;
  place-items: center;
  border-radius: 25px;
  font-size: 35px;
  background: linear-gradient(145deg, #172b4d, #111521);
  border: 1px solid #3988ff88;
  box-shadow: 0 0 35px #3988ff22;
}
.welcome h2 { margin-bottom: 8px; }
.welcome p { color: var(--muted); line-height: 1.8; }

.message {
  max-width: 88%;
  padding: 14px;
  border-radius: 18px;
  line-height: 1.8;
  overflow-wrap: anywhere;
  white-space: pre-wrap;
}
.user {
  align-self: flex-start;
  background: #173b72;
  border: 1px solid #3988ff44;
}
.ai {
  align-self: flex-end;
  background: var(--panel);
  border: 1px solid #ffffff0d;
}
.error {
  background: #421d28;
  align-self: flex-end;
}
.copy {
  display: block;
  padding: 5px 0 0;
  border: 0;
  background: transparent;
  color: var(--blue);
  font-size: 12px;
}
#status {
  color: var(--blue);
  font-size: 12px;
  min-height: 18px;
  padding: 4px 2px;
}

.composer {
  display: flex;
  align-items: flex-end;
  gap: 9px;
  padding-top: 10px;
  border-top: 1px solid #252b3a;
}
#prompt {
  flex: 1;
  min-width: 0;
  resize: none;
  max-height: 140px;
  padding: 15px;
  border: 1px solid #293247;
  border-radius: 20px;
  outline: none;
  background: var(--panel);
  color: white;
  line-height: 1.5;
}
#prompt:focus { border-color: var(--blue); }

#send {
  width: 52px;
  height: 52px;
  font-size: 23px;
  border: 0;
  background: var(--blue);
  color: white;
  border-radius: 18px;
}

.footer {
  text-align: center;
  color: #6f7789;
  font-size: 11px;
  padding: 9px 0 0;
}

@media (max-width: 480px) {
  .app { padding: 10px; }
  .message { max-width: 94%; }
}
</style>
</head>

<body>
<div class="app">
  <header>
    <div class="brand">
      <h1>DarkGPT AI</h1>
      <p>ذكاء اصطناعي • <span id="modeLabel">المساعد العام</span></p>
    </div>
    <button id="newChat" title="محادثة جديدة">＋ جديد</button>
  </header>

  <div class="toolbar">
    <select id="mode" aria-label="نمط الذكاء الاصطناعي">
      <option value="normal">🤖 DarkGPT AI</option>
      <option value="deep">🧠 Deep Thinking</option>
      <option value="coding">💻 Coding AI</option>
      <option value="cybersecurity">🛡️ Cybersecurity</option>
      <option value="negative">⚫ Dark Analysis</option>
    </select>
  </div>

  <main id="chat" aria-live="polite">
    <div class="welcome" id="welcome">
      <div class="logo">⚡</div>
      <h2>مرحباً بك في DarkGPT</h2>
      <p>اسأل، تعلّم، حلّل، أو اكتب كوداً برمجياً.<br>
      ابدأ محادثتك الآن.</p>
    </div>
  </main>

  <div id="status"></div>

  <form class="composer" id="form">
    <textarea id="prompt" rows="1"
      placeholder="اكتب رسالتك هنا..."
      aria-label="رسالتك"></textarea>
    <button id="send" type="submit" aria-label="إرسال">↑</button>
  </form>

  <div class="footer">DarkGPT AI • تأكد من المعلومات المهمة دائماً</div>
</div>

<script>
const API_URL = ""; // أضف رابط الخادم عند توفره

const chat = document.getElementById("chat");
const promptBox = document.getElementById("prompt");
const sendButton = document.getElementById("send");
const statusBox = document.getElementById("status");
const modeSelect = document.getElementById("mode");

let history = [];
let loading = false;

const labels = {
  normal: "المساعد العام",
  deep: "التفكير التحليلي",
  coding: "البرمجة",
  cybersecurity: "الأمن السيبراني",
  negative: "التحليل النقدي"
};

modeSelect.addEventListener("change", () => {
  document.getElementById("modeLabel").textContent =
    labels[modeSelect.value];
});

function addMessage(text, type = "ai", copyable = false) {
  document.getElementById("welcome")?.remove();

  const bubble = document.createElement("div");
  bubble.className = "message " + type;

  const content = document.createElement("div");
  content.textContent = text;
  bubble.appendChild(content);

  if (copyable) {
    const copy = document.createElement("button");
    copy.className = "copy";
    copy.textContent = "نسخ الإجابة";

    copy.onclick = async () => {
      try {
        await navigator.clipboard.writeText(text);
        copy.textContent = "تم النسخ ✓";
      } catch {
        copy.textContent = "تعذر النسخ";
      }
    };

    bubble.appendChild(copy);
  }

  chat.appendChild(bubble);
  chat.scrollTop = chat.scrollHeight;
  return bubble;
}

function setLoading(value) {
  loading = value;
  sendButton.disabled = value;
  promptBox.disabled = value;
  statusBox.textContent = value ? "DarkGPT يفكر..." : "";
}

async function sendMessage(event) {
  event?.preventDefault();

  const message = promptBox.value.trim();
  if (!message || loading) return;

  if (!API_URL) {
    addMessage(message, "user");
    promptBox.value = "";
    addMessage(
      "الواجهة تعمل، لكن لم يتم ربط خادم الذكاء الاصطناعي بعد. " +
      "أضف رابط API في إعداد API_URL لتلقي إجابات حقيقية.",
      "error"
    );
    return;
  }

  const oldHistory = history.map(item => ({...item}));
  const mode = modeSelect.value;

  addMessage(message, "user");
  promptBox.value = "";
  promptBox.style.height = "auto";

  setLoading(true);
  const waiting = addMessage("جارٍ الاتصال بالخادم...", "ai");

  try {
    const response = await fetch(API_URL, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        message,
        mode,
        history: oldHistory
      })
    });

    if (!response.ok) {
      throw new Error("HTTP " + response.status);
    }

    const data = await response.json();
    const answer = String(
      data.reply ?? data.message ?? data.response ??
      "لم يرجع الخادم إجابة."
    );

    waiting.remove();
    addMessage(answer, "ai", true);

    history.push(
      {role: "user", content: message},
      {role: "assistant", content: answer}
    );
  } catch (error) {
    waiting.remove();
    addMessage(
      "تعذر الاتصال بالخادم. تحقق من الرابط والإنترنت وإعدادات API.",
      "error"
    );
  } finally {
    setLoading(false);
    promptBox.focus();
  }
}

document.getElementById("form").addEventListener("submit", sendMessage);

promptBox.addEventListener("input", () => {
  promptBox.style.height = "auto";
  promptBox.style.height =
    Math.min(promptBox.scrollHeight, 140) + "px";
});

document.getElementById("newChat").addEventListener("click", () => {
  if (loading) return;

  history = [];
  chat.replaceChildren();

  const welcome = document.createElement("div");
  welcome.id = "welcome";
  welcome.className = "welcome";
  welcome.innerHTML =
    '<div class="logo">⚡</div>' +
    '<h2>محادثة جديدة</h2>' +
    '<p>اكتب رسالتك لبدء محادثة جديدة.</p>';

  chat.appendChild(welcome);
  statusBox.textContent = "";
  modeSelect.value = "normal";
  document.getElementById("modeLabel").textContent = labels.normal;
});
</script>
</body>
</html>
