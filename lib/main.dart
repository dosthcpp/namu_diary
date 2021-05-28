import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:namu_diary/providers/ARGardenProvider.dart';
import 'package:namu_diary/providers/AuthProvider.dart';
import 'package:namu_diary/providers/DictionaryProvider.dart';
import 'package:namu_diary/providers/NavigationProvider.dart';
import 'package:namu_diary/providers/ProfileProvider.dart';
import 'package:namu_diary/providers/UserProvider.dart';
import 'package:namu_diary/screens/ARGarden.dart';
import 'package:namu_diary/screens/Chatroom.dart';
import 'package:namu_diary/screens/HelpScreen.dart';
import 'package:namu_diary/screens/InputProfile.dart';
import 'package:namu_diary/screens/LoginPage.dart';
import 'package:namu_diary/screens/MainPage.dart';
import 'package:namu_diary/screens/PreStartingPage.dart';
import 'package:namu_diary/screens/RegisterPage.dart';
import 'package:namu_diary/screens/StartingPage.dart';
import 'package:namu_diary/screens/TestScreen.dart';
import 'package:namu_diary/screens/ViewDiary.dart';
import 'package:namu_diary/screens/ViewFeed.dart';
import 'package:namu_diary/screens/ViewImage.dart';
import 'package:namu_diary/screens/WriteDiaryPage.dart';
import 'package:namu_diary/screens/WriteFeedPage.dart';
import 'package:namu_diary/screens/FindPassword.dart';
import 'package:namu_diary/screens/ViewList.dart';
import 'package:provider/provider.dart';

final UserProvider userProvider = UserProvider();
final DictionaryProvider dicProvider = DictionaryProvider();
final ProfileProvider profileProvider = ProfileProvider();
final AuthProvider authProvider = AuthProvider();
final NavigationProvider navigationProvider = NavigationProvider();
final ARGardenProvider arGardenProvider = ARGardenProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FlutterDownloader.initialize(
    debug: false
  );
  runApp(NamuDiary());
}

class NamuDiary extends StatefulWidget {
  @override
  _NamuDiaryState createState() => _NamuDiaryState();
}

class _NamuDiaryState extends State<NamuDiary>{
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(
          create: (context) => userProvider,
        ),
        ChangeNotifierProvider<DictionaryProvider>(
          create: (context) => dicProvider,
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (context) => profileProvider,
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => authProvider,
        ),
        ChangeNotifierProvider<NavigationProvider>(
          create: (context) => navigationProvider,
        ),
        ChangeNotifierProvider<ARGardenProvider>(
          create: (context) => arGardenProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en', 'US'),
          Locale('ko', 'KR'),
        ],
        initialRoute: PreStartingPage.id,
        routes: {
          PreStartingPage.id: (context) => PreStartingPage(),
          StartingPage.id: (context) => StartingPage(),
          RegisterPage.id: (context) => RegisterPage(),
          InputProfile.id: (context) => InputProfile(),
          MainPage.id: (context) => MainPage(),
          ChatRoom.id: (context) => ChatRoom(),
          WriteFeedPage.id: (context) => WriteFeedPage(),
          WriteDiaryPage.id: (context) => WriteDiaryPage(),
          ARGarden.id: (context) => ARGarden(),
          TestScreen.id: (context) => TestScreen(),
          LoginPage.id: (context) => LoginPage(),
          FindPassword.id: (context) => FindPassword(),
          ViewDiary.id: (context) => ViewDiary(),
          ViewFeed.id: (context) => ViewFeed(),
          ViewList.id: (context) => ViewList(),
          ViewImage.id: (context) => ViewImage(),
          HelpScreen.id: (context) => HelpScreen(),
        },
      ),
    );
  }
}
