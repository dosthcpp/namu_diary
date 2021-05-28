import 'package:flutter/material.dart';
import 'package:namu_diary/main.dart';
import 'package:namu_diary/screens/StartingPage.dart';
import 'package:progress_indicators/progress_indicators.dart';

class PreStartingPage extends StatefulWidget {
  static const id = 'pre_starting_page';

  @override
  _PreStartingPageState createState() => _PreStartingPageState();
}

class _PreStartingPageState extends State<PreStartingPage> {
  String loadingMsg = '딕셔너리 파일 생성중입니다.';

  load() async {
    dicProvider.loadDic().then((_) {
      Navigator.of(context).pushNamed(StartingPage.id);
    });
  }

  @override
  void initState() {
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            JumpingText(
              loadingMsg,
            ),
          ],
        ),
      ),
    );
  }
}
