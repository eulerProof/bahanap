import 'package:flutter/material.dart';
import 'package:cc206_bahanap/features/dashboard_page.dart';
import 'package:cc206_bahanap/features/map_page.dart';
import 'package:cc206_bahanap/features/news_page.dart';
import 'package:cc206_bahanap/features/account_page.dart';

class TabView extends StatelessWidget {
  const TabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 4,
      child: Scaffold(
        bottomNavigationBar: TabBar(tabs: [
          Tab(
              icon: Icon(
            Icons.home_outlined,
            size: 30,
          )),
          Tab(
            icon: Icon(
              Icons.map_outlined,
              size: 30,
            ),
          ),
          Tab(
              icon: Icon(
            Icons.explore_outlined,
            size: 30,
          )),
          Tab(
              icon: Icon(
            Icons.account_circle_outlined,
            size: 30,
          )),
        ]),
        body: TabBarView(children: [
          DashboardPage(),
          MapPage(),
          NewsPage(),
          AccountPage(),
        ]),

        //     floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     // Add your SOS button action here
        //   },
        //   backgroundColor: Colors.red,
        //   child: Text(
        //     'SOS',
        //     style: TextStyle(fontWeight: FontWeight.bold),
        //   ),
        // ),
      ),
    );
  }
}
