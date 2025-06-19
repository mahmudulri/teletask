import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:teletask/homepage.dart';

import 'checkip.dart';
import 'livesms.dart';
import 'newhome.dart';
import 'set_number.dart';
import 'webpage.dart';
import 'welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyC_nXzWZOVQXd4zgwu9tihvwEFu8nHjo5Q",
        authDomain: "mypassmanager-33a37.firebaseapp.com",
        projectId: "mypassmanager-33a37",
        storageBucket: "mypassmanager-33a37.appspot.com",
        messagingSenderId: "1036948660110",
        appId: "1:1036948660110:web:523f41636aea8ef6d48edf"),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tele Work',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SetNumber(),
    );
  }
}
