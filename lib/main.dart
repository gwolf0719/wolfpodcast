import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'injection/injection_container.dart' as di;
import 'presentation/bloc/download/download_bloc.dart';
import 'presentation/bloc/subscription/subscription_bloc.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化依賴注入 (包含 Hive 初始化)
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 使用 MultiBlocProvider 在應用程式頂層提供 BLoCs
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.getIt<SubscriptionBloc>()),
        BlocProvider(create: (_) => di.getIt<DownloadBloc>()),
      ],
      child: MaterialApp(
        title: 'Wolf Podcast',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
