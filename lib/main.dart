// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twilio_voice/twilio_voice.dart';

import 'package:sample_project/firebase_options.dart';
import 'package:sample_project/screens/ui_call_screen.dart';

import 'utils.dart';

String token1 = '';
String client1ID = "AliceId";
String token2 = '';
String client2ID = "BobId";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    log(message.toString());
  });
  Stream<String> callEvents = TwilioVoice.instance.callEventsStream;
  callEvents.asBroadcastStream(
    onListen: (subscription) {
      log(subscription.toString());
    },
  );

  return runApp(MaterialApp(home: RegisterAs()));
}

class RegisterAs extends StatelessWidget {
  const RegisterAs({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return Scaffold(
      body: Center(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: controller,
              ),
              ElevatedButton(
                onPressed: () async {
                  TwilioVoice.instance.requestCallPhonePermission();
                  TwilioVoice.instance.requestReadPhoneStatePermission();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => App(
                        value: controller.text,
                      ),
                    ),
                    (route) => false,
                  );
                  // }
                },
                child: Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class App extends StatefulWidget {
  final String value;
  const App({
    super.key,
    required this.value,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String userId = "";
  String user = '';
  String userToken = '';
  String callSid = '';

  bool twilioInit = false;

  var authRegistered = false;

  var showingIncomingCallDialog = false;

  @override
  void initState() {
    super.initState();
    if (widget.value.contains("Alice".toLowerCase())) {
      user = client1ID;
      userToken = token1;
    } else {
      user = client2ID;
      userToken = token2;
    }

    TwilioVoice.instance.setOnDeviceTokenChanged((token) {
      printDebug("voip-device token changed");
      if (!kIsWeb) {
        register();
      }
    });

    register();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plugin example app"),
        actions: [
          _LogoutAction(
            token: userToken,
            onSuccess: () {
              setState(() {
                twilioInit = false;
              });
            },
            onFailure: (error) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Error"),
                  content: Text("Failed to unregister from calls: $error"),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    playAudioOnCall(
                      callSid,
                      'https://demo.twilio.com/docs/classic.mp3',
                    );
                  },
                  child: Text("Play recording in call"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: UICallScreen(
                    userId: userId,
                    onPerformCall: _onPerformCall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> playAudioOnCall(String callSid, String audioUrl) async {
    final dio = Dio();
    try {
      final response = await dio.post(
        'https://jamaal-chylaceous-nonsectionally.ngrok-free.dev/play-audio',
        data: {
          'audioUrl': audioUrl,
        },
      );
      log(response.data.toString());
    } catch (e) {
      log('Error: $e');
    }
  }

  Future<bool?> showIncomingCallScreen(
      BuildContext context, ActiveCall activeCall) async {
    if (!kIsWeb && !Platform.isAndroid) {
      printDebug("showIncomingCallScreen only for web");
      return false;
    }

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Incoming Call"),
          content: Text("Incoming call from ${activeCall.from}"),
          actions: [
            TextButton(
              child: const Text("Accept"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: const Text("Reject"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

  void register() async {
    printDebug("voip-service registration");

    bool success = false;
    success = await _registerFromEnvironment();

    if (success) {
      setState(() {
        twilioInit = true;
      });
    }
  }

  Future<bool> _registerAccessToken(String accessToken) async {
    printDebug("voip-registering access token");

    String? androidToken;
    if (!kIsWeb && Platform.isAndroid) {
      androidToken = await FirebaseMessaging.instance.getToken();
      printDebug("androidToken is ${androidToken!}");
    }
    final result = await TwilioVoice.instance.setTokens(
      accessToken: accessToken,
      deviceToken: androidToken,
    );
    return result ?? false;
  }

  Future<bool> _registerFromEnvironment() async {
    String? myId = user;
    String? myToken = userToken;
    if (myId.isEmpty) myId = null;
    if (myToken.isEmpty) myToken = null;

    printDebug("voip-registering with environment variables");
    if (myId == null || myToken == null) {
      printDebug(
          "Failed to register with environment variables, please provide ID and TOKEN");
      return false;
    }
    userId = myId;

    TwilioVoice.instance.registerClient(userId, "$userId name");
    return _registerAccessToken(myToken);
  }

  Future<void> _onPerformCall(String clientIdentifier) async {
    if (!await (TwilioVoice.instance.hasMicAccess())) {
      printDebug("request mic access");
      TwilioVoice.instance.requestMicAccess();
      return;
    }
    printDebug("starting call to $clientIdentifier");
    TwilioVoice.instance.call.place(
      to: clientIdentifier,
      from: userId,
      extraOptions: {
        'To': clientIdentifier,
        'From': userId,
      },
    );
  }
}

class _LogoutAction extends StatelessWidget {
  final String token;
  final void Function()? onSuccess;
  final void Function(String error)? onFailure;

  const _LogoutAction({
    this.onSuccess,
    this.onFailure,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
        onPressed: () async {
          final result = await TwilioVoice.instance.unregister(
            accessToken: token,
          );
          if (result == true) {
            onSuccess?.call();
          } else {
            onFailure?.call("Failed to unregister");
          }
        },
        label: const Text("Logout", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.logout, color: Colors.white));
  }
}
