import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  final List<String> items = List.generate(3, (index) => "Item $index");

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'BaHanap',
                      key: ValueKey('bahanapText'),
                      style: TextStyle(
                        fontSize: 35,
                        fontFamily: 'Gilroy',
                        color: Color(0XFF32ade6),
                        letterSpacing: -3.0,
                      ),
                    ),
                    // IconButton(
                    //   padding: const EdgeInsets.all(9),
                    //   icon: const Icon(Icons.notifications_none_outlined,
                    //       color: Colors.black),
                    //   iconSize: 35,
                    //   onPressed: () {},
                    // ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent News',
                      style: TextStyle(
                        fontSize: 25,
                        fontFamily: 'Gilroy',
                        color: Color(0XFF154961),
                        letterSpacing: -1.0,
                      ),
                    ),
                    // Padding(
                    //   padding: EdgeInsets.only(top: 7),
                    //   child: Text(
                    //     'See All',
                    //     style: TextStyle(
                    //       fontWeight: FontWeight.bold,
                    //       fontSize: 18,
                    //       fontFamily: 'SfPro',
                    //       color: Color(0xffafafaf),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: SizedBox(
                            width: 300,
                            height: 700,
                            child: Center(
                              child: Card(
                                color: Color.fromARGB(255, 175, 220, 241),
                                elevation: 10,
                                child: Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.asset(
                                          'assets/pepito.png',
                                          fit: BoxFit.fitWidth,
                                          width: 400,
                                          height: 90,
                                        ),
                                      ),
                                      const Text(
                                        'Pepito rapidly intensifies into typhoon',
                                        style: TextStyle(
                                          fontFamily: 'SfPro',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Typhoon Pepito (Man-yi) will continue to undergo rapid intensification until Saturday, November 16...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Color.fromARGB(255, 62, 62, 62),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )),
              ),
              const Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'More Stories',
                      style: TextStyle(
                        fontSize: 25,
                        fontFamily: 'Gilroy',
                        color: Color(0XFF154961),
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                    height: 300,
                    width: 800,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          child: SizedBox(
                            width: 200,
                            height: 700,
                            child: Center(
                              child: Card(
                                color: Color.fromARGB(255, 175, 220, 241),
                                elevation: 10,
                                child: Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.asset(
                                          'assets/pepito.png',
                                          fit: BoxFit.fitHeight,
                                          width: 200,
                                          height: 120,
                                        ),
                                      ),
                                      const Text(
                                        'Ofel weakens into severe tropical storm...',
                                        style: TextStyle(
                                          fontFamily: 'SfPro',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'At its peak, Ofel was a super typhoon with maximum sust...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Color.fromARGB(255, 62, 62, 62),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: SizedBox(
            height: 90,
            width: 90,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, 'sos');
              },
              backgroundColor: const Color.fromARGB(255, 239, 66, 63),
              shape: const CircleBorder(),
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
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xff32ade6),
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SizedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home),
                      color: Colors.white,
                      onPressed: () {
                        if (ModalRoute.of(context)?.settings.name != 'dash') {
                          Navigator.pushNamed(context, 'dash');
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.map),
                      color: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, 'map');
                      },
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      iconSize: 30,
                      color: Colors.white,
                      onPressed: () {
                        if (ModalRoute.of(context)?.settings.name !=
                            'notifications') {
                          Navigator.pushNamed(context, 'notifications');
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person),
                      iconSize: 30,
                      color: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, 'profile');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
