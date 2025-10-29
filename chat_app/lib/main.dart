import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString('username');

  runApp(MyApp(initialUsername: username));
}

class MyApp extends StatelessWidget {
  final String? initialUsername;
  const MyApp({super.key, this.initialUsername});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: (initialUsername != null && initialUsername!.isNotEmpty)
          ? HomeScreen(username: initialUsername!)
          : const LoginScreen(),
    );
  }
}
