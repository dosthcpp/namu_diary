import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:namu_diary/main.dart';
import 'package:namu_diary/screens/HelpScreen.dart';
import 'package:namu_diary/screens/MainPage.dart';

import 'package:namu_diary/utils.dart';
import 'package:namu_diary/components/Logo.dart';
import 'package:namu_diary/screens/RegisterPage.dart';
import 'package:namu_diary/screens/LoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class StartingPage extends StatefulWidget {
  static const id = 'starting_page';

  @override
  _StartingPageState createState() => _StartingPageState();
}

class _StartingPageState extends State<StartingPage> {
  VideoPlayerController _controller;

  @override
  void initState() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if((await SharedPreferences.getInstance()).getBool('willLoginPermanently')) {
        final _auth = FirebaseAuth.instance;
        final _fireStore = FirebaseFirestore.instance;
        UserCredential uc = await _auth.signInWithEmailAndPassword(
          email: await FlutterSecureStorage().read(key: 'email'),
          password: await FlutterSecureStorage().read(key: 'password'),
        );
        if (uc != null) {
          final info = await _fireStore
              .collection('/userInfo_${_auth.currentUser.email}')
              .limit(1)
              .get();
          await _fireStore
              .collection('/userInfo_${_auth.currentUser.email}')
              .doc(info.docs[0].id)
              .update({
            'lastLogin': Timestamp.fromDate(DateTime.now()),
          });
          authProvider.setCurrentUser(info.docs[0].data()['nickname']);
          Navigator.pushReplacementNamed(context, HelpScreen.id);
        }
      }
    });
    _controller = VideoPlayerController.network('https://korjarvis.asuscomm.com:9098/placeholder.mp4')
      ..initialize().then((_) {
        _controller.play();
        _controller.setLooping(true);
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size?.width ?? 0,
                height: _controller.value.size?.height ?? 0,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 10 * 2,
                  ),
                  TreeiumLogo(
                    fontSize: 30.0,
                    color: Colors.white,
                  ),
                  SizedBox(
                    height: 30.0,
                  ),
                  Text(
                    "트리움은 커뮤니티 정원에 대한 정보를 공유하는 공간입니다.\n자신만의 정원을 보여주세요!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 10 * 9,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5.0),
                        child: MaterialButton(
                          child: Text(
                            "이메일로 가입",
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, RegisterPage.id);
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 10 * 9,
                      child: Material(
                        color: Color(0xff5dca65),
                        borderRadius: BorderRadius.circular(5.0),
                        child: MaterialButton(
                          child: Text(
                            "네이버로 가입",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            showAlert(context);
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 10 * 9,
                      child: Material(
                        color: Color(0xffd95140),
                        borderRadius: BorderRadius.circular(5.0),
                        child: MaterialButton(
                          child: Text(
                            "구글로 가입",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            showAlert(context);
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 10 * 9,
                      child: MaterialButton(
                        child: Text(
                          "이미 가입하셨나요? 로그인하기",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, LoginPage.id);
                        },
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 10 * 1,
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
