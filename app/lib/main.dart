import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'notifications.dart';
import 'screens/calendar_screen.dart';
import 'screens/notes_screen.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');
  final notifications = NotificationService();
  await notifications.init();
  final storage = await Storage.open();
  final state = AppState(storage, notifications);
  await state.load();
  runApp(
    ChangeNotifierProvider.value(value: state, child: const QuickNotesApp()),
  );
}

class QuickNotesApp extends StatelessWidget {
  const QuickNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickNotes',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorSchemeSeed: Colors.amber,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.amber,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Разрешение на уведомления запрашиваем после первого кадра.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppState>().notifications.requestPermission(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pages = [NotesScreen(), CalendarScreen()];
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 720; // ПК: боковая панель вместо нижней
      return Scaffold(
        body: Row(children: [
          if (wide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.sticky_note_2_outlined),
                    selectedIcon: Icon(Icons.sticky_note_2),
                    label: Text('Заметки')),
                NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: Text('Календарь')),
              ],
            ),
          Expanded(child: pages[_index]),
        ]),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.sticky_note_2_outlined),
                      selectedIcon: Icon(Icons.sticky_note_2),
                      label: 'Заметки'),
                  NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: 'Календарь'),
                ],
              ),
      );
    });
  }
}
