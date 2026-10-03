import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // IMPORT AUTH
import 'package:cloud_firestore/cloud_firestore.dart'; // IMPORT DATABASE
import 'firebase_options.dart';
import 'dart:async';

// Import your dashboards
import 'student_dashboard.dart';
import 'faculity.dart';
import 'admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(LoginApp());
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akal Attendance',
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check if user is already logged in?
    // For now, we stick to your flow: Splash -> Login
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002046),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/images/12.png', height: 100, width: 100,
                  // Add error builder in case image is missing
                  errorBuilder: (c, o, s) => Icon(Icons.school, size: 80, color: Color(0xFF002046))),
            ),
            SizedBox(height: 200),
            Text(
              'Akal University',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42 ,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Value Based Education',
              style: TextStyle(color: Colors.white70, fontSize: 32),
            ),
            SizedBox(height: 50),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// --- LOGIN SCREEN WITH REAL BACKEND ---
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Colors
  final Color kalgidharBlue = const Color(0xFF002046);
  final Color kalgidharTeal = const Color(0xFF00796B);

  // State
  String selectedRole = 'Student'; // Used only for UI preference, logic uses Database
  bool rememberMe = true;
  String selectedLanguage = 'English';
  bool _isPasswordVisible = false;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final roleKeys = ['Student', 'Faculty', 'Admin'];
  final languages = ['English', 'Punjabi', 'Hindi'];

  final Map<String, Map<String, String>> _localizedValues = {
    'English': {
      'subtitle': 'True learning induces in the mind service to mankind.',
      'username': 'Email Address', // Changed from User Name to Email for Firebase
      'password': 'Password',
      'remember': 'Remember me',
      'pref_lang': 'Preferred language',
      'login': 'Log In',
      'Student': 'Student',
      'Faculty': 'Faculty',
      'Admin': 'Admin',
      'empty_user': 'Please enter Email',
      'empty_pass': 'Please enter Password',
    },
    'Punjabi': {
      'subtitle': 'ਗਿਆਨ ਨੂੰ ਵਿਚਾਰੋ ਅਤੇ ਚਿੰਤਨ ਕਰੋ...',
      'username': 'ਈਮੇਲ ਪਤਾ',
      'password': 'ਪਾਸਵਰਡ',
      'remember': 'ਮੈਨੂੰ ਯਾਦ ਰੱਖੋ',
      'pref_lang': 'ਪਸੰਦੀਦਾ ਭਾਸ਼ਾ',
      'login': 'ਲੌਗ ਇਨ',
      'Student': 'ਵਿਦਿਆਰਥੀ',
      'Faculty': 'ਫੈਕਲਟੀ',
      'Admin': 'ਪ੍ਰਬੰਧਕ',
      'empty_user': 'ਕਿਰਪਾ ਕਰਕੇ ਈਮੇਲ ਦਰਜ ਕਰੋ',
      'empty_pass': 'ਕਿਰਪਾ ਕਰਕੇ ਪਾਸਵਰਡ ਦਰਜ ਕਰੋ',
    },
    'Hindi': {
      'subtitle': 'ज्ञान पर चिंतन और मनन करें...',
      'username': 'ईमेल पता',
      'password': 'पासवर्ड',
      'remember': 'मुझे याद रखें',
      'pref_lang': 'पसंदीदा भाषा',
      'login': 'लॉग इन',
      'Student': 'छात्र',
      'Faculty': 'संकाय',
      'Admin': 'व्यवस्थापक',
      'empty_user': 'कृपया ईमेल दर्ज करें',
      'empty_pass': 'कृपया पासवर्ड दर्ज करें',
    },
  };

  String getTrans(String key) {
    return _localizedValues[selectedLanguage]?[key] ?? key;
  }

  // --- REAL LOGIN FUNCTION ---
  Future<void> _handleLogin() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) return;

    // 2. Show Loading Indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. Firebase Auth: Check Email/Password
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 4. Firestore: Get User Role
      // We look up the 'users' collection using the User ID (UID)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // Close Loading Indicator
      if (mounted) Navigator.pop(context);

      if (userDoc.exists) {
        // Get the role stored in the database
        // Note: We use data()['role'] instead of UI dropdown for security
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        String role = data?['role'] ?? 'Student'; // Default to Student if missing

        // 5. Navigate
        if (role == 'Student') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentDashboard()));
        } else if (role == 'Faculty') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FacultyDashboard()));
        } else if (role == 'Admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboard()));
        } else {
          _showError("Unknown role assigned contact Admin.");
        }
      } else {
        _showError("User record not found in Database.");
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // Close loading if error
      String message = "Login Failed";
      if (e.code == 'user-not-found') message = "No user found with this email.";
      if (e.code == 'wrong-password') message = "Incorrect password.";
      if (e.code == 'invalid-email') message = "Email address is invalid.";
      _showError(message);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("An error occurred: ${e.toString()}");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
              Container(
                color: kalgidharBlue,
                padding: EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  children: [
                    Text(
                      '', // Placeholder
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      getTrans('subtitle'),
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Logo
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Image.asset('assets/images/12.png', height: 100, width: 100,
                  errorBuilder: (c, o, s) => Icon(Icons.school, size: 80, color: kalgidharBlue),
                ),
              ),
              SizedBox(height: 50),

              // Login Form
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // USERNAME / EMAIL
                      TextFormField(
                        controller: usernameController,
                        keyboardType: TextInputType.emailAddress, // Key change for Email
                        decoration: InputDecoration(
                          labelText: getTrans('username'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return getTrans('empty_user');
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // PASSWORD
                      TextFormField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: getTrans('password'),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return getTrans('empty_pass');
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // ROLE SELECTOR (Visual Only now)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: roleKeys.map((roleKey) {
                          final isSelected = selectedRole == roleKey;
                          return ElevatedButton(
                            onPressed: () => setState(() => selectedRole = roleKey),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? kalgidharBlue : Colors.grey[300],
                              foregroundColor: isSelected ? Colors.white : Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(getTrans(roleKey)),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 10),

                      // SETTINGS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: rememberMe,
                                activeColor: kalgidharTeal,
                                onChanged: (val) => setState(() => rememberMe = val),
                              ),
                              Text(getTrans('remember')),
                            ],
                          ),
                          DropdownButton<String>(
                            value: selectedLanguage,
                            underline: Container(height: 2, color: kalgidharBlue),
                            onChanged: (val) => setState(() => selectedLanguage = val!),
                            items: languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          // CONNECTED TO NEW FUNCTION
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kalgidharBlue,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            getTrans('login'),
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}