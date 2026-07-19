import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'state/settings_state.dart';
import 'theme/app_theme.dart';
import 'screens/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsState();
  final appState = AppState();
  await Future.wait([settings.load(), appState.load()]);

  runApp(TsuketoriApp(settings: settings, appState: appState));
}

class TsuketoriApp extends StatelessWidget {
  const TsuketoriApp({
    super.key,
    required this.settings,
    required this.appState,
  });

  final SettingsState settings;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: Consumer<SettingsState>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'ツケトリ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            home: const RootShell(),
          );
        },
      ),
    );
  }
}
