import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection.dart';
import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/domain/analytics_service.dart';
import 'features/economy/presentation/bloc/wallet_bloc.dart';
import 'features/economy/presentation/bloc/wallet_event.dart';
import 'features/missions/presentation/bloc/mission_bloc.dart';
import 'features/missions/presentation/bloc/mission_event.dart';
import 'features/ranking/presentation/bloc/ranking_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  // Registra el arranque (sesión + primer uso + día activo).
  sl<AnalyticsService>().startSession();
  runApp(const BrixRunApp());
}

class BrixRunApp extends StatelessWidget {
  const BrixRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<WalletBloc>()..add(const LoadWallet())),
        BlocProvider(create: (_) => sl<MissionBloc>()..add(const LoadMissions())),
        BlocProvider(create: (_) => sl<RankingBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Run For Win',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        // Internacionalización: detecta el idioma del dispositivo y carga uno
        // de los soportados; si no hay coincidencia, cae a español.
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        localeListResolutionCallback: (deviceLocales, supported) =>
            Locale(AppLocalizations.resolveLanguage(deviceLocales)),
      ),
    );
  }
}

