import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/record_page.dart';
import 'pages/past_runs_page.dart';
import 'pages/settings_page.dart';
import 'pages/calendar_page.dart';
import 'pages/plans_page.dart';
import 'background_location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundLocationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Georgia',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF19647E)),
      ),
      home: const MyHomePage(title: 'My run app!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  // key to control the PastRunsPage
  final GlobalKey<PastRunsPageState> _pastRunsKey = GlobalKey<PastRunsPageState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // refresh runs when switching to the Home tab
    if (index == 0) {
      _pastRunsKey.currentState?.loadRuns();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // attach key so we can reload runs when tab changes
          PastRunsPage(key: _pastRunsKey),
          const RecordPage(),
          const CalendarPage(),
          const PlansPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Record Run'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Plans'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

