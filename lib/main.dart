import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/paper_repository.dart';
import 'state/app_state.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PaperFlowApp());
}

class PaperFlowApp extends StatelessWidget {
  const PaperFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(SharedPrefsPaperRepository())..init(),
      child: MaterialApp(
        title: 'PaperFlow',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
