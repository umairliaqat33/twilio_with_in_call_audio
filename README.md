📱 Flutter Twilio Voice Calling App

A Flutter application that integrates Twilio Programmable Voice to make and receive voice calls between users using your custom Node.js backend as the token + TwiML server.

This app also supports:

📞 Outgoing and incoming calls between users

🔔 Handling Twilio call events (incoming, connected, ended, etc.)

🔊 Playing audio inside an ongoing call via backend /play-audio endpoint

🚀 Features

Handle and join conference rooms

Listen to real-time call events (incoming, connected, ended, etc.)

Play custom audio files during active calls

Built with the twilio_voice Flutter plugin

⚙️ Setup Instructions

1. Install dependencies
   flutter pub get

2. Configure Backend URL

This app connects to your Twilio token server (Node.js backend).
In your Dart code, set your backend base URL:

const String baseUrl = "https://<your-ngrok-or-deployed-backend-url>";

3. Add dependencies in pubspec.yaml
   dependencies:
   flutter:
   sdk: flutter
   twilio_voice: ^0.2.0+1
   firebase_messaging: ^15.2.5
   firebase_core: ^3.13.0
   cloud_functions: ^5.4.0
   dio: ^5.9.0

4. Android Setup
   🧩 Permissions

Add these lines inside android/app/src/main/AndroidManifest.xml:

<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />

Also, ensure your minimum SDK is at least 26 in android/app/build.gradle:

defaultConfig {
minSdkVersion 26
}

6. Initialize Twilio Voice SDK

In your main.dart:

import 'package:twilio_voice/twilio_voice.dart';
import 'package:flutter/material.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
await TwilioVoice.instance.init();
runApp(const MyApp());
}

📞 Make an Outgoing Call
await TwilioVoice.instance.call.make(
to: "bob",
accessToken: token,
);

🔊 Play Audio During Call

This triggers your backend /play-audio endpoint to play an audio file in the live call.

🔁 End-to-End Flow
[Flutter] → /token → [Backend] → Twilio generates access token
↓
User A starts call to "bob"
↓
Twilio routes via backend /voice webhook
↓
User B receives incoming call
↓
Both users are connected via Twilio
↓
Backend /play-audio can inject media during the call
