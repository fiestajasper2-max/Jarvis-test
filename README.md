# Jarvis AI Assistant

A free, open-source Jarvis-style AI assistant for Android.

**Features (Phase 1):**
- Holographic particle orb UI
- Voice conversation
- Groq-powered AI (Llama models)
- Calm + witty + lightly sarcastic personality
- Long-term memory
- Web search capability
- Open apps
- Set alarms & reminders
- Take notes

## How to get the APK (No computer needed)

### 1. Create GitHub Repository
1. Go to [github.com/new](https://github.com/new)
2. Repository name: `jarvis`
3. Make it Public
4. Click **Create repository**

### 2. Upload the files
You can upload using the GitHub website (from your phone):

1. In your new repo, click **Add file** → **Upload files**
2. Upload **all** the folders and files I give you (keep the same structure)
3. Commit the changes

### 3. Add your Groq API Key (IMPORTANT)
1. Go to https://console.groq.com and create a free account
2. Create an API key and copy it
3. In your GitHub repo, open the file: `lib/services/groq_service.dart`
4. Find this line:
   `static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';`
5. Replace `YOUR_GROQ_API_KEY_HERE` with your real key (keep the quotes)
6. Commit the change

### 4. Build the APK automatically
1. Go to the **Actions** tab in your GitHub repo
2. Click **Build APK** on the left
3. Click **Run workflow** button → Run workflow
4. Wait 6-12 minutes
5. When it finishes (green check), click the run → download **jarvis-apk**
6. Unzip it and install the APK on your phone

### 5. Install on your phone
- Allow "Install unknown apps" for your browser/files app
- Open the APK and install
- Grant Microphone permission when Jarvis asks

## Important Notes
- The first build can take longer
- If the build fails, tell me the error and I’ll fix the files
- This is Phase 1. Wake word, reading notifications, and deeper social media control will come in future updates
- The holographic orb reacts to listening / speaking / thinking

## Personality
Calm, friendly, with light wit and occasional sarcasm — like a more relaxed movie Jarvis.

