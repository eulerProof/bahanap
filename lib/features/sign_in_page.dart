import 'package:cc206_bahanap/features/dashboard_page.dart';
import 'package:cc206_bahanap/features/sign_up_page.dart';
import 'package:cc206_bahanap/features/forgot_password.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

Route _createFadeRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

Route _createFadeRoute2() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => SignUpPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

void _showDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();

  bool _keepMeLoggedIn = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, 'getstarted');
                      },
                      icon: const Icon(Icons.arrow_back,
                          size: 30, color: Color(0xFF32ade6)),
                    ),
                    const Text(
                      'Login Account',
                      style: TextStyle(
                          fontFamily: 'SfPro',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF154961)),
                    ),
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Email Address',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          labelText: 'Enter email address',
                          labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Password',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          labelText: 'Enter password',
                          labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _keepMeLoggedIn,
                              onChanged: (bool? value) {
                                setState(() {
                                  _keepMeLoggedIn = value ?? false;
                                });
                              },
                              activeColor: Colors.blue,
                            ),
                            const Text(
                              'Keep me logged in',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0XFF575757)),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, 'forgot');
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF32ade6),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final UserCredential credential = await FirebaseAuth
                                .instance
                                .signInWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );

                            _showDialog(context, 'Sign-In Successful',
                                'Welcome back, ${_emailController.text}!');
                            Future.delayed(const Duration(seconds: 1), () {
                              Navigator.pushNamed(context, 'dash');
                            });
                          } on FirebaseAuthException catch (e) {
                            String errorMessage =
                                'Invalid credentials. Please try again.';
                            if (e.code == 'user-not-found') {
                              errorMessage = 'No user found for that email.';
                            } else if (e.code == 'wrong-password') {
                              errorMessage =
                                  'Wrong password provided for that user.';
                            }

                            _showDialog(
                                context, 'Sign-In Failed', errorMessage);
                            Navigator.pushNamed(context, 'dash');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(300, 60),
                          backgroundColor: const Color(0XFF32ade6),
                          foregroundColor: Colors.white,
                          elevation: 5.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0XFF32ade6),
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'SfPro',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(_createFadeRoute2());
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.lightBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: SizedBox(
                height: 70,
                width: MediaQuery.sizeOf(context).width,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'sos');
                  },
                  backgroundColor: Colors
                      .transparent, // set to transparent so gradient shows
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: Container(
                    alignment: Alignment.center,
                    height: 77,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color.fromARGB(255, 255, 145, 145), // lighter red
                          Color(0xFFB70000), // dark red
                        ],
                        center: Alignment.center,
                        radius: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'SOS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 23,
                        fontFamily: 'SfPro',
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ))));
  }
}
