import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/app_router.dart';
import 'features/share/providers/share_import_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: const ProviderScope(
        child: SakuinApp(),
      ),
    ),
  );
}

class SakuinApp extends ConsumerStatefulWidget {
  const SakuinApp({super.key});

  @override
  ConsumerState<SakuinApp> createState() => _SakuinAppState();
}

class _SakuinAppState extends ConsumerState<SakuinApp> {
  @override
  void initState() {
    super.initState();
    // Share Import (cold start): pick up text shared from banking /
    // e-wallet apps when Sakuin was launched via a SHARE intent. This also
    // subscribes the warm-start stream for the whole session; the native
    // intent is reset right after it has been handled.
    ref.read(shareImportProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final colorScheme = ref.watch(resolvedColorSchemeProvider(brightness));

    return MaterialApp.router(
      title: 'Sakuin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(scheme: colorScheme),
      darkTheme: AppTheme.dark(scheme: colorScheme),
      themeMode: ThemeMode.system,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: appRouter,
    );
  }
}
