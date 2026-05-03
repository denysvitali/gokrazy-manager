import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'home.dart';
import 'theme.dart';

export 'api.dart'
    show
        CertificatePinRequired,
        GokrazyClient,
        InstanceRepository,
        certificateFingerprint,
        normalizeUrl;
export 'models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadThemePreference();
  runApp(const GokrazyManagerApp());
}

class GokrazyManagerApp extends StatefulWidget {
  const GokrazyManagerApp({super.key});

  @override
  State<GokrazyManagerApp> createState() => _GokrazyManagerAppState();
}

class _GokrazyManagerAppState extends State<GokrazyManagerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              HomeShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const _RouteShellOutlet(),
              ),
              GoRoute(
                path: '/instance/:instanceId',
                builder: (context, state) => const _RouteShellOutlet(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const _RouteShellOutlet(),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeVariant>(
      valueListenable: appThemeVariant,
      builder: (context, variant, _) {
        final lightTheme = buildAppTheme(Brightness.light);
        final darkTheme = buildAppTheme(Brightness.dark);
        final amoledTheme = buildAppTheme(Brightness.dark, amoledBlack: true);

        ThemeMode mode;
        ThemeData resolvedDark;
        switch (variant) {
          case AppThemeVariant.system:
            mode = ThemeMode.system;
            resolvedDark = darkTheme;
            break;
          case AppThemeVariant.light:
            mode = ThemeMode.light;
            resolvedDark = darkTheme;
            break;
          case AppThemeVariant.dark:
            mode = ThemeMode.dark;
            resolvedDark = darkTheme;
            break;
          case AppThemeVariant.amoledBlack:
            mode = ThemeMode.dark;
            resolvedDark = amoledTheme;
            break;
        }

        return MaterialApp.router(
          title: 'Gokrazy Manager',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: resolvedDark,
          themeMode: mode,
          routerConfig: _router,
        );
      },
    );
  }
}

class _RouteShellOutlet extends StatelessWidget {
  const _RouteShellOutlet();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
