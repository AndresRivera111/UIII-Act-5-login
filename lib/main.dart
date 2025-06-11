import 'package:flutter/material.dart';
import 'package:myapp/toys.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async { // Removed 'List<String> args' as it's not used
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter engine is initialized before Firebase

  try {
    // Initialize Firebase with the provided options
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBGC-3SptCLmKzKJZeHLErlCoV71yoNvmM",
        appId: "1:309356786150:android:3c1bb1264bd37301d4e627",
        messagingSenderId: "309356786150",
        projectId: "notesapp-15985",
      ),
    );
    print("Firebase initialized successfully!"); // Confirmation message
  } catch (e) {
    // Catch any errors during Firebase initialization
    print("Error initializing Firebase: $e");
    // Optionally, you could show an error dialog to the user or
    // provide a fallback UI in case Firebase initialization fails.
    // For example:
    // runApp(ErrorApp(errorMessage: "Failed to connect to backend: $e"));
  }

  // Run your main application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp with debugShowCheckedModeBanner set to false for a cleaner UI
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Toys(), // Your Notes application widget
    );
  }
}
