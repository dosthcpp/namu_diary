import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:namu_diary/constants.dart';
import 'package:namu_diary/screens/MainPage.dart';

class HelpScreen extends StatefulWidget {
  static const id = 'help_screen';

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  SharedPreferences prefs;

  void _onIntroEnd(context) async {
    await prefs.setBool('hasReadHelpPage', true);
    Navigator.pushNamed(context, MainPage.id);
  }

  Widget _buildImage(String assetName, [double width = 350]) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.1,
      ),
      child: Image.asset('assets/$assetName', width: width),
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      prefs = await SharedPreferences.getInstance();
      if(prefs.getBool('hasReadHelpPage') ?? false) {
        Navigator.pushNamed(context, MainPage.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0);

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: bodyStyle,
      descriptionPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      pages: [
        PageViewModel(
          title: "소통해요!",
          body:
              "내가 일상에서 본 식물 사진들을 업로드하고, 내가 본 식물들에 관해 사람들과 이야기 나눠봐요!",
          image: _buildImage('communication.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "가꾸어요!",
          body:
              "AR정원으로 나만의 정원을 꾸며봐요!",
          image: _buildImage('farming.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "공유해요!",
          body:
              "내가 본 식물들, 내가 꾸민 AR정원을 사람들과 함께 공유해요!",
          image: _buildImage('sharing.png'),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skipFlex: 0,
      nextFlex: 0,
      //rtl: true, // Display as right-to-left
      skip: Text(
        'Skip',
        style: TextStyle(
          color: Color(kMainColor),
        ),
      ),
      next: Icon(
        Icons.arrow_forward,
        color: Color(
          kMainColor,
        ),
      ),
      done: Text(
        'Done',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(kMainColor),
        ),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: EdgeInsets.all(16),
      controlsPadding: kIsWeb
          ? EdgeInsets.all(12.0)
          : EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: DotsDecorator(
        size: Size(10.0, 10.0),
        color: Colors.black12,
        activeSize: Size(22.0, 10.0),
        activeColor: Color(kMainColor),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }
}
