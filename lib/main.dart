import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:telephony/telephony.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _message = "";
  String _messageType = "";
  final telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void onMessage(SmsMessage message) async {
    String smsBody = message.body ?? "Error reading message body.";
    sendRequest(smsBody);
    setState(() {
      _message = message.body ?? "Error reading message body.";
    });
  }

  void onBackgroundMessage(SmsMessage message) async {
    String smsBody = message.body ?? "Error reading message body.";
    debugPrint("Background message: ${message.body}");
  }

  sendRequest(String msgBody) async {
    String apiUrl = "https://api.cyberenigma.uz/analiz?msg=$msgBody";

    try {
      var response = await http.get(
        Uri.parse(apiUrl),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        print(responseData);

        if (responseData['status'] == 'spam') {
          _messageType = "Spam xabar";
          showNotification(
            "Spam xabar",
            "Bu xabarda spam aniqlandi: $msgBody",
          );
        } else {
          _messageType = "Oddiy xabar";
          print("Message is not spam");
        }
      } else {
        print("Failed to send SMS to API: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error sending SMS to API: $e");
    }
  }

  void showNotification(String title, String body) async {
    var androidDetails = const AndroidNotificationDetails(
      'channel_id',
      'Channel Name',
      priority: Priority.high,
      importance: Importance.high,
      ticker: 'ticker',
    );
    var platformChannelSpecifics = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'New Payload',
    );
  }

  Future<void> initPlatformState() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (initializationSettings) {});

    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(
        onNewMessage: onMessage,
        onBackgroundMessage: onBackgroundMessage,
        listenInBackground: true,
      );
    }

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('CyberEnigma'),
        ),
        body: Column(
          children: [
            Image.asset(
              "lib/logo.png",
              alignment: Alignment.topCenter,
              height: 350,
            ),
            Center(child: Text("Oxirgi SMS: $_message")),
            Center(child: Text("Oxirgi SMS turi: $_messageType")),
          ],
        ),
      ),
    );
  }
}
