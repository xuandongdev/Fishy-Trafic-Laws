import 'package:fishy/ViewModels/AddLawContentVM.dart';
import 'package:fishy/ViewModels/AddLawVM.dart';
import 'package:fishy/ViewModels/ChatVM.dart';
import 'package:fishy/Views/LawManageScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fishy/Views/ChatScreen.dart';
import 'package:fishy/Views/LoginScreen.dart';
import 'package:fishy/Configs/Constants.dart';
import 'Models/LawContentModel.dart';
import 'Models/LawModel.dart';
import 'Themes/ThemeData.dart';
import 'ViewModels/AuthVM.dart';
import 'ViewModels/ChatHistoryVM.dart';
import 'ViewModels/LawVM.dart';
import 'ViewModels/LoginVM.dart';
import 'ViewModels/ThemeVM.dart';
import 'Views/AddLawContentScreen.dart';
import 'Views/AddLawScreen.dart';
import 'Views/ChatHistoryScreen.dart';
import 'Views/EditContentScreen.dart';
import 'Views/LawDetailScreen.dart';
import 'Views/LogoutScreen.dart';
import 'Views/SettingScreen.dart';
import 'Views/SignupScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  //await EmbeddingService.generateAndUpdateAllEmbeddings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => AddLawVM()),
        ChangeNotifierProvider(create: (_) => AddContentVM()),
        ChangeNotifierProvider(create: (_) => LawViewModel()),
        ChangeNotifierProvider(create: (_) => ChatHistoryViewModel()),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          Provider.of<ThemeNotifier>(context).isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
      initialRoute: "/login",
      routes: {
        "/login": (context) => LoginScreen(),
        "/chat": (context) => const ChatScreen(),
        "/logout": (context) => LogoutScreen(),
        "/register": (context) => SignUpScreen(),
        "/setting": (context) => SettingsScreen(),
        "/addLaw": (context) => AddLawScreen(),
        "/addData": (context) => AddLawContentScreen(sohieuvanban: ""),
        "/chatHistory": (context) => ChatHistoryScreen(),
        "/lawMana": (context) => LawManageScreen(),
        '/lawDetail': (context) {
          final law = ModalRoute.of(context)!.settings.arguments as LawModel?;
          return LawDetailScreen(law: law);
        },
        '/editContent': (context) {
          final content = ModalRoute.of(context)!.settings.arguments as LawContentModel;
          return EditContentScreen(content: content);
        }
      },
    );
  }
}
