import 'package:cc206_bahanap/features/sign_up_page.dart';
import 'package:cc206_bahanap/features/forgot_password.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  bool _keepMeLoggedIn = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Agreement"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms and Conditions & Privacy Policy',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF37ade6)),
              ),
              SizedBox(height: 20),
              Text(
                "1. Terms of Use",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF575757)),
              ),
              Text(
                "By accessing and using BaHanap, you agree to be bound by these terms and conditions. If you do not agree with any part of these terms, please do not use our services.",
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 20),
              Text(
                "2. User Eligibility",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF575757)),
              ),
              Text(
                "You must be at least 12 years old to use our services. By using our services, you represent and warrant that you meet the age requirement.",
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 20),
              Text(
                "3. Privacy Policy",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF575757)),
              ),
              Text(
                "Your use of our services is also governed by our Privacy Policy, which can be found in bahanap/privacy_policy. Please review our Privacy Policy to understand how we collect, use, and protect your personal information.\n",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
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
                      'Create Account',
                      style: TextStyle(
                          fontFamily: 'SfPro',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF154961)),
                    ),
                    const Text(
                      'Sign up to continue',
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
                      maxLength: 45,
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
                      'Name',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    TextFormField(
                      controller: _nameController,
                      maxLength: 20,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          labelText: 'Enter name',
                          labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Phone number',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    TextFormField(
                      maxLength: 15,
                      controller: _phoneController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          labelText: 'Enter phone number',
                          labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15)),
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
                      maxLength: 20,
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
                    const SizedBox(height: 16),
                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    TextFormField(
                      maxLength: 20,
                      obscureText: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          labelText: 'Re-enter password',
                          labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
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
                              'I agree with the',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0XFF575757)),
                            ),
                            TextButton(
                              onPressed: _showTermsDialog,
                              child: const Text(
                                'terms and conditions and privacy policy.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0XFF32ade6)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final credential =
                                await _auth.createUserWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );

                            String uid = credential.user!.uid;

                            await _firestore
                                .collection('profiles')
                                .doc(uid)
                                .set({
                              'uid': uid,
                              'email': _emailController.text,
                              'Name': _nameController.text,
                              'PhoneNumber': _phoneController.text,
                            });

                            _showDialog(context, 'Sign-Up Successful',
                                'Account created successfully!');

                            Navigator.pushReplacementNamed(context, 'signin');
                          } on FirebaseAuthException catch (e) {
                            String errorMessage =
                                'An error occurred. Please try again.';
                            if (e.code == 'weak-password') {
                              errorMessage =
                                  'The password provided is too weak.';
                            } else if (e.code == 'email-already-in-use') {
                              errorMessage =
                                  'The account already exists for that email.';
                            }

                            _showDialog(
                                context, 'Sign-Up Failed', errorMessage);
                          } catch (e) {
                            print(e);
                            _showDialog(context, 'Error',
                                'An unexpected error occurred.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(300, 60),
                          backgroundColor: Color(0XFF32ade6),
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
                          'Sign up',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'SfPro'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        SizedBox(width: 12),
                        Text(
                          'or sign up with',
                          style: TextStyle(color: Color(0Xff575757)),
                        ),
                        SizedBox(width: 12),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: const Text("Login with google"),
                                    content:
                                        const Text("Google Login API here."),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Ok"))
                                    ],
                                  ));
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          foregroundColor: Colors.black,
                          elevation: 5.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/google.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: const Text("Login with apple"),
                                    content:
                                        const Text("Apple Login API here."),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Ok"))
                                    ],
                                  ));
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 5.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/apple.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Continue with Apple',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: const Text("Login with facebook"),
                                    content:
                                        const Text("Facebook Login API here."),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Ok"))
                                    ],
                                  ));
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Color(0XFF3b5998),
                          foregroundColor: Colors.white,
                          elevation: 5.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/facebook.png',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Continue with Facebook',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 70)
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
              height: 50,
              width: MediaQuery.sizeOf(context).width,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'sos');
                },
                backgroundColor: const Color.fromARGB(255, 239, 66, 63),
                child: const Text(
                  'SOS',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      fontFamily: 'SfPro',
                      color: Colors.white,
                      letterSpacing: 3),
                ),
              ),
            )));
  }
}
