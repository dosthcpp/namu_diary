import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/scheduler.dart';
import 'package:namu_diary/components/CustomTextField.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:namu_diary/main.dart';
import 'package:namu_diary/materials/GradientText.dart';
import 'package:namu_diary/utils.dart';

final _fireStore = FirebaseFirestore.instance;

class WriteDiaryPage extends StatefulWidget {
  static const id = 'write_diary_page';

  @override
  _WriteDiaryPageState createState() => _WriteDiaryPageState();
}

class _WriteDiaryPageState extends State<WriteDiaryPage> {
  final contentFocusNode = FocusNode();
  bool isUploading = false;
  String content = '';
  File _imageFile;

  void pickImage() async {
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
      // User canceled the picker
      print('User canceled the picker');
    }
  }

  void uploadDiary(BuildContext ctx, String content, File imageFile,
      String curDiaryDoc) async {
    try {
      final diaryCount =
          (await _fireStore.collection(curDiaryDoc).get()).docs.length;
      final paddedDocNum = numberPad('$diaryCount');
      final randomString = getRandomString();
      final imagePath =
          '/uploads/diary/${userProvider.currentUser}/$randomString';
      await _fireStore.collection(curDiaryDoc).add({
        "diaryNo": paddedDocNum,
        "content": content,
        "date": Timestamp.fromDate(DateTime.now()),
        "like": [],
        "reply": [],
        "imagePath": imagePath
      });
      final _fileRef = FirebaseStorage.instance.ref().child(imagePath);
      if (_fileRef != null) {
        _fileRef.delete();
      }
      await _fileRef.putFile(imageFile);
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
  Widget build(BuildContext _context) {
    BuildContext ctx =
        ModalRoute.of(context).settings.arguments as BuildContext;

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
                    "일지 작성",
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width / 10 * 1.5,
                      ),
                      child: Text(
                        "사진",
                        style: TextStyle(
                          fontWeight: FontWeight.w200,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
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
                                  onPressed: () {
                                    SchedulerBinding.instance
                                        .addPostFrameCallback((_) async {
                                      for (var i = 0;
                                          i < followers.length;
                                          ++i) {
                                        if (followers[i] !=
                                            userProvider.currentUser) {
                                          final path = '/diary_${userProvider.currentUser}';
                                          final index = numberPad('${(await _fireStore.collection(path).get()).docs.length}');
                                          await notify(
                                            userProvider.currentUser,
                                            followers[i],
                                            'follower_newdiary',
                                            DateTime.now(),
                                            '님이 ${int.tryParse(index) + 1?? 1} 번째 다이어리 올림: $content',
                                            path: path,
                                            index: index,
                                          );
                                        }
                                      }
                                      setState(() {
                                        isUploading = true;
                                      });
                                      uploadDiary(
                                        context,
                                        content,
                                        _imageFile,
                                        '/diary_${userProvider.currentUser}',
                                      );
                                      setState(() {
                                        isUploading = false;
                                      });
                                      Navigator.pop(_context);
                                    });
                                  },
                                  child: Text(
                                    "업로드",
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }),
                        ),
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
