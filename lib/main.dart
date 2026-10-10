import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'state/settings_state.dart';
import 'theme/app_theme.dart';
import 'screens/root_shell.dart';
import 'screens/settings/backup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  final settings = SettingsState();
  final appState = AppState();
  late Future<void> loading = _load();

  Future<void> _load() async {
    await Future.wait([
      initializeDateFormatting('ja'),
      settings.load(),
      appState.load(),
    ]);
  }

  @override
  void dispose() {
    settings.dispose();
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return TsuketoriApp(settings: settings, appState: appState);
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child:
                snapshot.hasError
                    ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('保存データを読み込めませんでした。データは変更していません。'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => setState(() => loading = _load()),
                            child: const Text('再試行'),
                          ),
                          Builder(
                            builder:
                                (recoveryContext) => TextButton(
                                  onPressed: () async {
                                    final restored = await Navigator.of(
                                      recoveryContext,
                                    ).push<bool>(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ChangeNotifierProvider.value(
                                              value: appState,
                                              child: const BackupScreen(
                                                closeOnRestore: true,
                                              ),
                                            ),
                                      ),
                                    );
                                    if (restored == true && mounted) {
                                      setState(() => loading = _load());
                                    }
                                  },
                                  child: const Text('バックアップから復元'),
                                ),
                          ),
                        ],
                      ),
                    )
                    : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
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
