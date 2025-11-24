import 'package:flutter/material.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  bool _showGetStarted = true;
  bool _showBahanapText = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 400,
                    height: 400,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _showGetStarted
                          ? Image.asset(
                              'assets/getstarted.png',
                              key: const ValueKey('initialImage'),
                            )
                          : Image.asset(
                              'assets/screen3.png',
                              key: const ValueKey('newImage'),
                            ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: _showBahanapText
                        ? const Text(
                            'BaHanap',
                            key: ValueKey('bahanapText'),
                            style: TextStyle(
                              fontSize: 80,
                              fontFamily: 'Gilroy',
                              color: Color(0XFF32ade6),
                              letterSpacing: -4.0,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const Text(
                            'Stay Connected.\nStay Protected.',
                            key: ValueKey('initialText'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                              fontFamily: 'SfPro',
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Receive real-time alerts, connect with \n'
                    'rescuers, and access the latest news.',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SfPro',
                      color: Color(0xFFA0A0A0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -1),
                          end: const Offset(0, 0),
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _showGetStarted
                        ? ElevatedButton(
                            key: const ValueKey('getStartedButton'),
                            onPressed: () {
                              setState(() {
                                _showGetStarted = false;
                                _showBahanapText = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(259, 71),
                              backgroundColor: Colors.lightBlue,
                              foregroundColor: Colors.white,
                              elevation: 5.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                fontFamily: 'SfPro',
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Column(
                            key: const ValueKey('loginSignUpButtons'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, 'signin');
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(300, 60),
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0XFF32ade6),
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
                              const SizedBox(height: 5),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, 'signup');
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(300, 60),
                                  backgroundColor: const Color(0XFF32ade6),
                                  foregroundColor: Colors.white,
                                  elevation: 5.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 0,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'SfPro',
                                  ),
                                ),
                              ),
                              SizedBox(height: 75)
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        )),
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
                backgroundColor:
                    Colors.transparent, // set to transparent so gradient shows
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
              )),
        ));
  }
}
