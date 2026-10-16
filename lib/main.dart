import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.content.ClipData;
import android.content.ClipboardManager
import android.content.Context;
import android.view.Gravity;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.view.inputmethod.EditorInfo;
import android.widget.*;
import org.json.JSONArray;
import org.json.JSONObject;
import java.net.HttpURLConnection;
import java.net.URL;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends Activity {

    private static final int BG = Color.rgb(8, 10, 16);
    private static final int PANEL = Color.rgb(20, 24, 36);
    private static final int BLUE = Color.rgb(57, 136, 255);

    // استبدل بالرابط الحقيقي بعد إنشاء الخادم
    private static final String API_URL =
            "https://YOUR-BACKEND-URL/chat";

    private LinearLayout messages;
    private EditText input;
    private ScrollView scroll;
    private Spinner modes;
    private Button sendButton;
    private TextView status;
    private ProgressBar progress;

    private boolean loading = false;
    private final ExecutorService executor =
            Executors.newSingleThreadExecutor();
    private final JSONArray history = new JSONArray();

    private final String[] modeKeys = {
            "normal", "deep", "coding",
            "cybersecurity", "negative"
    };

    private final String[] modeNames = {
            "🤖 DarkGPT AI",
            "🧠 Deep Thinking",
            "💻 Coding AI",
            "🛡️ Cybersecurity",
            "⚫ Dark Analysis"
    };

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);

        getWindow().setStatusBarColor(BG);
        getWindow().setNavigationBarColor(BG);

        buildUI();
        addBubble("مرحباً بك في DarkGPT AI!\nاكتب رسالتك للبدء.",
                false, false, false);
    }

    private GradientDrawable shape(int color, int radius) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(radius);
        return d;
    }

    private TextView text(String value, int size) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(size);
        t.setTextColor(Color.WHITE);
        return t;
    }

    private void buildUI() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(12, 8, 12, 8);
        root.setBackgroundColor(BG);
        setContentView(root);

        // رأس التطبيق
        LinearLayout header = new LinearLayout(this);
        header.setGravity(Gravity.CENTER_VERTICAL);

        LinearLayout brand = new LinearLayout(this);
        brand.setOrientation(LinearLayout.VERTICAL);

        TextView title = text("DarkGPT AI", 23);
        title.setTypeface(null, Typeface.BOLD);
        brand.addView(title);

        status = text("مساعدك الذكي", 12);
        status.setTextColor(BLUE);
        brand.addView(status);

        header.addView(brand,
                new LinearLayout.LayoutParams(0, -2, 1));

        Button newChat = new Button(this);
        newChat.setText("＋");
        newChat.setContentDescription("محادثة جديدة");
        header.addView(newChat);
        root.addView(header);

        newChat.setOnClickListener(v -> newConversation());

        // اختيار نمط الذكاء الاصطناعي
        modes = new Spinner(this);

        ArrayAdapter<String> adapter = new ArrayAdapter<>(
                this,
                android.R.layout.simple_spinner_item,
                modeNames);

        adapter.setDropDownViewResource(
                android.R.layout.simple_spinner_dropdown_item);

        modes.setAdapter(adapter);

        LinearLayout.LayoutParams modeParams =
                new LinearLayout.LayoutParams(-1, 50);

        modeParams.setMargins(0, 8, 0, 8);
        root.addView(modes, modeParams);

        // منطقة المحادثة
        scroll = new ScrollView(this);
        scroll.setFillViewport(true);

        messages = new LinearLayout(this);
        messages.setOrientation(LinearLayout.VERTICAL);
        messages.setPadding(2, 14, 2, 14);

        scroll.addView(messages);

        root.addView(scroll,
                new LinearLayout.LayoutParams(-1, 0, 1));

        // مؤشر الانتظار
        progress = new ProgressBar(this);
        progress.setIndeterminate(true);
        progress.setVisibility(View.GONE);

        root.addView(progress,
                new LinearLayout.LayoutParams(28, 28));

        // منطقة الكتابة
        LinearLayout composer = new LinearLayout(this);
        composer.setGravity(Gravity.CENTER_VERTICAL);
        composer.setPadding(0, 8, 0, 4);

        input = new EditText(this);
        input.setTextColor(Color.WHITE);
        input.setHintTextColor(Color.LTGRAY);
        input.setHint("اكتب رسالتك...");
        input.setTextSize(15);
        input.setPadding(16, 10, 16, 10);
        input.setMinHeight(52);
        input.setMaxLines(5);
        input.setBackground(shape(PANEL, 24));
        input.setImeOptions(EditorInfo.IME_ACTION_SEND);

        composer.addView(input,
                new LinearLayout.LayoutParams(0, -2, 1));

        sendButton = new Button(this);
        sendButton.setText("↑");
        sendButton.setTextSize(22);
        sendButton.setTextColor(Color.WHITE);
        sendButton.setBackground(shape(BLUE, 24));

        LinearLayout.LayoutParams sendParams =
                new LinearLayout.LayoutParams(58, 52);

        sendParams.setMargins(7, 0, 0, 0);
        composer.addView(sendButton, sendParams);
        root.addView(composer);

        sendButton.setOnClickListener(v -> sendMessage());

        input.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEND) {
                sendMessage();
                return true;
            }
            return false;
        });
    }

    private void addBubble(String value, boolean user,
                           boolean error, boolean copyable) {

        LinearLayout row = new LinearLayout(this);
        row.setGravity(user ? Gravity.RIGHT : Gravity.LEFT);
        row.setOrientation(LinearLayout.VERTICAL);

        TextView bubble = text(value, 15);
        bubble.setGravity(Gravity.START);
        bubble.setPadding(15, 12, 15, 12);
        bubble.setTextIsSelectable(true);

        int color = error
                ? Color.rgb(65, 27, 36)
                : user
                ? Color.rgb(23, 59, 114)
                : PANEL;

        bubble.setBackground(shape(color, 20));

        int maxWidth = getResources()
                .getDisplayMetrics().widthPixels - 48;

        int width = Math.min(
                (int) (getResources()
                        .getDisplayMetrics().widthPixels * 0.82),
                maxWidth);

        LinearLayout.LayoutParams bubbleParams =
                new LinearLayout.LayoutParams(width, -2);

        row.addView(bubble, bubbleParams);

        if (copyable && !user) {
            TextView copy = text("نسخ الإجابة", 12);
            copy.setTextColor(BLUE);
            copy.setPadding(8, 5, 8, 5);

            copy.setOnClickListener(v -> {
                ClipboardManager clipboard =
                        (ClipboardManager) getSystemService(
                                Context.CLIPBOARD_SERVICE);

                clipboard.setPrimaryClip(
                        ClipData.newPlainText(
                                "DarkGPT response", value));

                Toast.makeText(this, "تم نسخ الإجابة",
                        Toast.LENGTH_SHORT).show();
            });

            row.addView(copy);
        }

        LinearLayout.LayoutParams rowParams =
                new LinearLayout.LayoutParams(-1, -2);

        rowParams.setMargins(0, 0, 0, 12);
        messages.addView(row, rowParams);

        scroll.post(() ->
                scroll.fullScroll(View.FOCUS_DOWN));
    }

    private void newConversation() {
        if (loading) return;

        messages.removeAllViews();

        while (history.length() > 0) {
            history.remove(0);
        }

        modes.setSelection(0);

        addBubble("بدأت محادثة جديدة.",
                false, false, false);
    }

    private void sendMessage() {
        if (loading) return;

        final String question =
                input.getText().toString().trim();

        if (question.isEmpty()) return;

        if (API_URL.contains("YOUR-BACKEND-URL")) {
            addBubble(
                    "واجهة DarkGPT جاهزة، لكن لا يوجد خادم متصل. "
                    + "أنشئ خادم API ثم ضع رابطه في API_URL.",
                    false, true, false);
            return;
        }

        final String selectedMode =
                modeKeys[modes.getSelectedItemPosition()];

        final JSONArray oldHistory = new JSONArray();

        for (int i = 0; i < history.length(); i++) {
            oldHistory.put(history.optJSONObject(i));
        }

        input.setText("");
        hideKeyboard();

        addBubble(question, true, false, false);

        loading = true;
        sendButton.setEnabled(false);
        progress.setVisibility(View.VISIBLE);
        status.setText("جارٍ الاتصال...");

        final TextView waiting =
                text("DarkGPT يفكر...", 14);

        waiting.setTextColor(BLUE);
        messages.addView(waiting);

        scroll.post(() ->
                scroll.fullScroll(View.FOCUS_DOWN));

        executor.execute(() -> {
            String answer;
            boolean failed = false;
            HttpURLConnection connection = null;

            try {
                JSONObject payload = new JSONObject();
                payload.put("message", question);
                payload.put("mode", selectedMode);
                payload.put("history", oldHistory);

                connection = (HttpURLConnection)
                        new URL(API_URL).openConnection();

                connection.setRequestMethod("POST");
                connection.setConnectTimeout(15000);
                connection.setReadTimeout(90000);
                connection.setDoOutput(true);

                connection.setRequestProperty(
                        "Content-Type",
                        "application/json; charset=UTF-8");

                connection.setRequestProperty(
                        "Accept", "application/json");

                try (OutputStream out =
                             connection.getOutputStream()) {
                    out.write(payload.toString().getBytes(
                            StandardCharsets.UTF_8));
                }

                int code = connection.getResponseCode();

                InputStream stream =
                        code >= 200 && code < 300
                                ? connection.getInputStream()
                                : connection.getErrorStream();

                StringBuilder response = new StringBuilder();

                if (stream != null) {
                    try (BufferedReader reader =
                                 new BufferedReader(
                                         new InputStreamReader(
                                                 stream,
                                                 StandardCharsets.UTF_8))) {

                        String line;

                        while ((line = reader.readLine()) != null) {
                            response.append(line);
                        }
                    }
                }

                if (code < 200 || code >= 300) {
                    throw new IOException("HTTP " + code);
                }

                JSONObject data =
                        new JSONObject(response.toString());

                answer = data.optString(
                        "reply",
                        data.optString(
                                "message",
                                data.optString(
                                        "response",
                                        "لم يرجع الخادم إجابة.")));

                JSONObject userItem = new JSONObject();
                userItem.put("role", "user");
                userItem.put("content", question);
                history.put(userItem);

                JSONObject assistantItem = new JSONObject();
                assistantItem.put("role", "assistant");
                assistantItem.put("content", answer);
                history.put(assistantItem);

            } catch (Exception e) {
                answer = "تعذر الاتصال بالخادم. تحقق من رابط "
                        + "API والإنترنت وإعدادات الخادم.";
                failed = true;

            } finally {
                if (connection != null) {
                    connection.disconnect();
                }
            }

            final String result = answer;
            final boolean isError = failed;

            runOnUiThread(() -> {
                messages.removeView(waiting);

                addBubble(result, false, isError, !isError);

                loading = false;
                sendButton.setEnabled(true);
                progress.setVisibility(View.GONE);
                status.setText("مساعدك الذكي");
            });
        });
    }

    private void hideKeyboard() {
        try {
            InputMethodManager imm =
                    (InputMethodManager) getSystemService(
                            Context.INPUT_METHOD_SERVICE);

            imm.hideSoftInputFromWindow(
                    input.getWindowToken(), 0);

        } catch (Exception ignored) {
        }
    }

    @Override
    protected void onDestroy() {
        executor.shutdownNow();
        super.onDestroy();
    }
}
