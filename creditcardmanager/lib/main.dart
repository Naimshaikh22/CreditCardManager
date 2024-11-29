import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:creditcardmanager/ShowCreditCard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures bindings are ready
  await Firebase.initializeApp(); //
  

 FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
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
      title: 'Credit Card Manager',
      home: CreditCardListPage(),
    );
  }
}
