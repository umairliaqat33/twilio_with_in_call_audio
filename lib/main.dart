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
// +19712656927

String token1 =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTSzM3OTY1NDUwNTc3M2I1ODAyZTdiMDA3M2Y4MDAzYTU5LTE3NjIzNzgyODkiLCJncmFudHMiOnsiaWRlbnRpdHkiOiJBbGljZUlkIiwidm9pY2UiOnsiaW5jb21pbmciOnsiYWxsb3ciOnRydWV9LCJvdXRnb2luZyI6eyJhcHBsaWNhdGlvbl9zaWQiOiJBUDU0ZTgxN2RlMzNiMTgzNDhiYjYxZGQ4NDZlODUxOGY4In0sInB1c2hfY3JlZGVudGlhbF9zaWQiOiJDUjhiZmM0MTc2MTlhNjE2ODVjMjFkZDUyOGQzZjliNGUzIn19LCJpYXQiOjE3NjIzNzgyODksImV4cCI6MTc2MjM4MTg4OSwiaXNzIjoiU0szNzk2NTQ1MDU3NzNiNTgwMmU3YjAwNzNmODAwM2E1OSIsInN1YiI6IkFDZWZiYTBhMTc5MjRhZmQwZjViYmQzOTNmNTk3OTM5MjgifQ.tTs8OFyc5-d1MYjklKHuYuilV3jaOM1UXEAZyGPLBhE';
String client1ID = "AliceId";
String token2 =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTSzM3OTY1NDUwNTc3M2I1ODAyZTdiMDA3M2Y4MDAzYTU5LTE3NjIzNzg1MDAiLCJncmFudHMiOnsiaWRlbnRpdHkiOiJCb2JJZCIsInZvaWNlIjp7ImluY29taW5nIjp7ImFsbG93Ijp0cnVlfSwib3V0Z29pbmciOnsiYXBwbGljYXRpb25fc2lkIjoiQVA1NGU4MTdkZTMzYjE4MzQ4YmI2MWRkODQ2ZTg1MThmOCJ9LCJwdXNoX2NyZWRlbnRpYWxfc2lkIjoiQ1I4YmZjNDE3NjE5YTYxNjg1YzIxZGQ1MjhkM2Y5YjRlMyJ9fSwiaWF0IjoxNzYyMzc4NTAwLCJleHAiOjE3NjIzODIxMDAsImlzcyI6IlNLMzc5NjU0NTA1NzczYjU4MDJlN2IwMDczZjgwMDNhNTkiLCJzdWIiOiJBQ2VmYmEwYTE3OTI0YWZkMGY1YmJkMzkzZjU5NzkzOTI4In0.sKxycbsZNT6NDVux1Gy2qpXYzNCcofMWhQFwveixx6I';
String client2ID = "BobId";

extension IterableExtension<E> on Iterable<E> {
  /// Extension on [Iterable]'s [firstWhere] that returns null if no element is found instead of throwing an exception.
  E? firstWhereOrNull(bool Function(E element) test, {E Function()? orElse}) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return (orElse == null) ? null : orElse();
  }
}

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
                  // bool? isRegistered =
                  //     await TwilioVoice.instance.registerPhoneAccount();
                  // // if (isRegistered ?? false) {
                  // TwilioVoice.instance.openPhoneAccountSettings();
                  // bool? isEnabled =
                  //     await TwilioVoice.instance.isPhoneAccountEnabled();
                  // log("Phone account registration status: $isEnabled");
                  TwilioVoice.instance
                      .requestCallPhonePermission(); // Gives Android permissions to place calls
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

    listenForEvents();
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
                      callSid, // Store this when call connects
                      'https://demo.twilio.com/docs/classic.mp3', // Public URL of your audio
                    );
                  },
                  child: Text("Play recording in call"),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child:
                        // twilioInit
                        //     ?
                        UICallScreen(
                      userId: userId,
                      onPerformCall: _onPerformCall,
                    )
                    // : UIRegistrationScreen(
                    //     onRegister: _onRegisterWithToken,
                    //   ),
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
          // 'callSid': callSid,
          'audioUrl': audioUrl,
        },
      );
      log(response.data.toString());
    } catch (e) {
      log('Error: $e');
    }
  }
  // void _showWebIncomingCallDialog() async {
  //   showingIncomingCallDialog = true;
  //   final activeCall = TwilioVoice.instance.call.activeCall!;
  //   final action = await showIncomingCallScreen(context, activeCall);
  //   if (action == true) {
  //     printDebug("accepting call");
  //     TwilioVoice.instance.call.answer();
  //   } else if (action == false) {
  //     printDebug("rejecting call");
  //     TwilioVoice.instance.call.hangUp();
  //   } else {
  //     printDebug("no action");
  //   }
  // }

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

  // Future<bool> _registerFromCredentials(String identity, String token) async {
  //   userId = identity;
  //   return _registerAccessToken(token);
  // }

  void listenForEvents() {
    TwilioVoice.instance.callEventsListener.listen((event) async {
      switch (event) {
        // case CallEvent.initiated:
        //   log("Call Initiated: ${event.toString()}");
        //   break;
        case CallEvent.incoming:
          log("Incoming Call Event: ${event.toString()}");
          break;
        case CallEvent.ringing:
          log("Ringing Event: ${event.toString()}");
          break;
        case CallEvent.connected:
          {
            log("Call Connected: ${event.toString()}");
            await checkActiveCall();
          }
          break;
        case CallEvent.callEnded:
          log("Call Ended: ${event.toString()}");
          break;
        default:
          log("Other Event: ${event.toString()}");
      }
    });
  }

  Future<void> checkActiveCall() async {
    try {
      final dio = Dio(BaseOptions(
          baseUrl: 'https://jamaal-chylaceous-nonsectionally.ngrok-free.dev'));

      final response = await dio.get('/call');
      // ignore: prefer_interpolation_to_compose_strings
      // log("call data: " + response.data);
      callSid = response.data['sid'];
      // if (response.data['active'] == true) {
      //   final call = response.data['call'];
      //   print('Active call: ${call['sid']} to ${call['to']}');
      // } else {
      //   print('No active call.');
      // }
    } catch (e) {
      log('Error fetching active call: $e');
    }
  }

// "client:"
//           "e7474e57-0453-4108-a202-96238a8e2f64"
//           "?displayName=Mike Tyson&language=pakistani&isRejoin=false&linguist=Barts linguist238"
//           "&BookingId=LS164876&customerDeviceId=2748&LinguistEmailAddress=mohsinlatif@autosmarttech.com"
//           "&to=e7474e57-0453-4108-a202-96238a8e2f64&gender=Male&lastCallStartTime=null&organizationName=org123"
//           "&subject=Booking Views&startDate=(2025-04-18 12:01:53.060885&duration=15",
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

  // Future<void> _onRegisterWithToken([String? identity]) async {
  //   return _registerFromCredentials(identity ?? "Unknown", userToken)
  //       .then((value) {
  //     if (!value) {
  //       showDialog(
  //         context: context,
  //         builder: (context) => const AlertDialog(
  //           title: Text("Error"),
  //           content: Text("Failed to register for calls"),
  //         ),
  //       );
  //     } else {
  //       setState(() {
  //         twilioInit = true;
  //       });
  //     }
  //   });
  // }
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
