import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:namu_diary/components/CustomTextField.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:namu_diary/main.dart';
import 'package:namu_diary/materials/GradientText.dart';
import 'package:namu_diary/utils.dart';

final _fireStore = FirebaseFirestore.instance;

class WriteFeedPage extends StatefulWidget {
  static const id = 'write_feed_page';

  @override
  _WriteFeedPageState createState() => _WriteFeedPageState();
}

class _WriteFeedPageState extends State<WriteFeedPage> {
  final contentFocusNode = FocusNode();
  File _imageFile;
  bool init = false;
  String content = '';
  bool isUploading = false;

  void pickImage() async {
    setState(() {
      init = true;
    });
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      String filePath = result?.files?.single?.path ?? '';
      if (filePath != null) {
        setState(() {
          _imageFile = File(filePath);
        });
      } else {
        print('No image selected.');
      }
    } else {
      dicProvider.clearTreeList();
      // User canceled the picker
      print('User canceled the picker');
    }
  }

  uploadFeed(context, username, content, imageFile) async {
    try {
      final count = (await _fireStore
              .collection('/feed_${userProvider.currentGarden}')
              .get())
          .docs
          .length;
      final randomString = getRandomString();
      final imagePath =
          'uploads/${userProvider.currentGarden}/feed/$randomString';
      await _fireStore.collection('/feed_${userProvider.currentGarden}').add({
        'feedNo': numberPad(count.toString()),
        'user': username,
        'content': content,
        'date': Timestamp.fromDate(DateTime.now()),
        'reply': [],
        'like': [],
        'type': 'feed',
        "imagePath": imagePath,
      });
      await uploadImageToFirebase(
        imagePath,
        imageFile,
      );
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  Widget get uploadImage {
    return _imageFile == null
        ? Container(
            width: 120.0,
            height: 120.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                10.0,
              ),
              gradient: LinearGradient(
                colors: [
                  Color(0xff40c149),
                  Color(0xff30a69a),
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                child: Column(
                  children: [
                    SizedBox(
                      height: 5.0,
                    ),
                    Container(
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/file_upload.png',
                        fit: BoxFit.contain,
                        width: 80.0,
                      ),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Text(
                      "사진 업로드",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
                onTap: () {
                  pickImage();
                },
              ),
            ),
          )
        : MaterialButton(
            child: Container(
              width: MediaQuery.of(context).size.width / 10 * 8,
              height: 400.0,
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: FileImage(_imageFile),
                ),
              ),
            ),
            onPressed: () {
              pickImage();
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 10 * 1,
                  ),
                  GradientText(
                    "피드 작성",
                    gradient: LinearGradient(
                      colors: [
                        Color(0xff40c149),
                        Color(0xff30a69a),
                      ],
                    ),
                    weight: FontWeight.w700,
                    size: 40.0,
                  ),
                  SizedBox(
                    height: 50.0,
                  ),
                  CustomTextField(
                    disabled: true,
                    ctx: context,
                    label: '유저',
                    init: true,
                    useMaxline: false,
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  CustomTextField(
                    disabled: false,
                    ctx: context,
                    label: '내용',
                    init: false,
                    height: 120.0,
                    useMaxline: true,
                    onChanged: (val) {
                      content = val;
                    },
                    controller: null,
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  uploadImage,
                  SizedBox(
                    height: 30.0,
                  ),
                  isUploading
                      ? JumpingText(
                          '업로드중입니다...',
                        )
                      : Container(
                          width: MediaQuery.of(context).size.width / 10 * 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              5.0,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Color(0xff40c149),
                                Color(0xff30a69a),
                              ],
                            ),
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                              stream: _fireStore
                                  .collection(
                                      '/userInfo_${userProvider.currentEmail}')
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, info) {
                                final List followers = info?.data?.docs != null
                                    ? List.from((info?.data?.docs
                                            ?.elementAt(0)
                                            ?.data() ??
                                        {'follower': []})['follower'])
                                    : [];
                                return MaterialButton(
                                  onPressed: () async {
                                    for (var i = 0; i < followers.length; ++i) {
                                      if (followers[i] !=
                                          userProvider.currentUser) {
                                        final path =
                                            '/feed_${userProvider.currentGarden}';
                                        final index = numberPad((await _fireStore
                                                .collection(
                                                    '/feed_${userProvider.currentGarden}')
                                                .get())
                                            .docs
                                            .length
                                            .toString());
                                        await notify(
                                          userProvider.currentUser,
                                          followers[i],
                                          'feed',
                                          DateTime.now(),
                                          "님이 ${int.tryParse(index) + 1 ?? 1}번째 피드 올림: $content",
                                          path: path,
                                          index: index,
                                        );
                                      }
                                    }
                                    isUploading = true;
                                    await uploadFeed(
                                      context,
                                      userProvider.currentUser,
                                      content,
                                      _imageFile,
                                    );
                                    isUploading = false;
                                  },
                                  child: Text(
                                    "업로드",
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }),
                        )
                ],
              ),
              Image.asset(
                'assets/background.png',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
