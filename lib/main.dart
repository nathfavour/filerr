import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/send_screen.dart';
import 'screens/receive_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(FilerrApp());
}

class FilerrApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'filerr',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FilerrMainScaffold(),
    );
  }
}

class FilerrMainScaffold extends StatefulWidget {
  @override
  State<FilerrMainScaffold> createState() => _FilerrMainScaffoldState();
}

class _FilerrMainScaffoldState extends State<FilerrMainScaffold> {
  int _selectedIndex = 0;
  final _screens = [
    HomeScreen(),
    SendScreen(),
    ReceiveScreen(),
    SettingsScreen(),
  ];
  final _labels = ['Home', 'Send', 'Receive', 'Settings'];
  final _icons = [
    Icons.dashboard_customize_rounded, // Home
    Icons.upload_file_rounded, // Send
    Icons.download_for_offline_rounded, // Receive
    Icons.tune_rounded, // Settings
  ];
  final Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              backgroundColor: _purple.withOpacity(0.08),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: _purple, size: 32),
              unselectedIconTheme: IconThemeData(
                color: Colors.grey[600],
                size: 28,
              ),
              selectedLabelTextStyle: TextStyle(
                color: _purple,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(color: Colors.grey[600]),
              destinations: List.generate(
                _labels.length,
                (i) => NavigationRailDestination(
                  icon: Icon(_icons[i]),
                  label: Text(_labels[i]),
                ),
              ),
            ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar:
          isWide
              ? null
              : BottomNavigationBar(
                backgroundColor: _purple.withOpacity(0.95),
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                currentIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
                type: BottomNavigationBarType.fixed,
                items: List.generate(
                  _labels.length,
                  (i) => BottomNavigationBarItem(
                    icon: Icon(_icons[i]),
                    label: _labels[i],
                  ),
                ),
              ),
    );
  }
}
