import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/economy/presentation/bloc/wallet_bloc.dart';
import 'features/economy/presentation/bloc/wallet_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const BrixRunApp());
}

class BrixRunApp extends StatelessWidget {
  const BrixRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // WalletBloc lives at app scope — all pages share the same instance
      create: (_) => sl<WalletBloc>()..add(const LoadWallet()),
      child: MaterialApp.router(
        title: 'BrixRun',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
