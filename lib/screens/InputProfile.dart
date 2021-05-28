import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';

import 'package:namu_diary/screens/RegisterPage.dart';
import 'package:namu_diary/main.dart';
import 'package:namu_diary/utils.dart';

final _fireStore = FirebaseFirestore.instance;
final RegExp phoneRegex = RegExp(r"^\d{3}-\d{3,4}-\d{4}$");

class InputProfile extends StatefulWidget {
  static const id = 'input_profile';

  @override
  _InputProfileState createState() => _InputProfileState();
}

class _InputProfileState extends State<InputProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String nickname = '';
  File _profileImage;
  FocusNode birthdayFocusNode = FocusNode();
  TextEditingController birthdayTEC = TextEditingController();
  FocusNode genderFocusNode = FocusNode();
  FocusNode phoneNumberFocusNode = FocusNode();
  String phoneNumber = '';
  bool areYouMale = true;
  bool check = false;
  bool hasError = false;
  String errorStatus = '';

  Future pickImage() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      String filePath = result?.files?.single?.path ?? '';

      setState(
        () {
          if (filePath != null) {
            _profileImage = File(filePath);
          } else {
            print('No image selected.');
          }
        },
      );
    } else {
      // User canceled the picker
    }
  }

  void _showDatePicker(ctx) {
    // showCupertinoModalPopup is a built-in function of the cupertino library
    showCupertinoModalPopup(
      context: ctx,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height / 10 * 3.5,
        color: Color.fromARGB(255, 255, 255, 255),
        child: Column(
          children: [
            SizedBox(
              height: 10.0,
            ),
            Center(
              child: Container(
                height: MediaQuery.of(ctx).size.height / 10 * 2.5,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: DateTime(2000, 1, 1),
                  onDateTimeChanged: (DateTime dt) {
                    setState(
                      () {
                        birthdayTEC.text =
                            "${dt.year}년 ${dt.month}월 ${dt.day}일";
                      },
                    );
                  },
                ),
              ),
            ),
            // Close the modal
            CupertinoButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(ctx).pop(),
            )
          ],
        ),
      ),
    );
  }

  chkNotEmpty(String val) {
    return (val.length != 0 && val.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    bool enabled = chkNotEmpty(nickname) &&
        chkNotEmpty(birthdayTEC.text) &&
        check &&
        chkNotEmpty(phoneNumber);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          40.0,
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          title: Text(
            "프로필 작성",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<QuerySnapshot>(
            stream: _fireStore.collection('userList').snapshots(),
            builder: (context, userList) {
              final list = userList?.data?.docs?.map((el) => el.data()['username']) ?? [];
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20.0,
                    ),
                    Center(
                      child: CircleAvatar(
                        radius: 50.0,
                        backgroundColor: Colors.white,
                        child: InkWell(
                          onTap: () {
                            pickImage();
                          },
                          child: ClipOval(
                            child: _profileImage == null
                                ? Icon(
                                    Icons.person,
                                    size: 80.0,
                                    color: Colors.black,
                                  )
                                : Image.file(
                                    _profileImage,
                                    fit: BoxFit.cover,
                                    width: 100.0,
                                    height: 100.0,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    TextField(
                      onChanged: (val) {
                        nickname = val;
                      },
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: "닉네임 입력",
                      ),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    _CustomTextField(
                      title: "생일",
                      focusNode: birthdayFocusNode,
                      controller: birthdayTEC,
                      onTap: () {
                        _showDatePicker(context);
                      },
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width / 10 * 0.5,
                        ),
                        child: Text(
                          "성별",
                          style: TextStyle(
                            fontSize: check ? 11.5 : 15.0,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Text(
                              "남",
                              style: TextStyle(
                                fontSize: 30.0,
                              ),
                            ),
                            SizedBox(
                              width: 10.0,
                            ),
                            RoundCheckbox(
                              onTap: () {
                                setState(() {
                                  areYouMale = true;
                                });
                              },
                              check: check && areYouMale,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "여",
                              style: TextStyle(
                                fontSize: 30.0,
                              ),
                            ),
                            SizedBox(
                              width: 10.0,
                            ),
                            RoundCheckbox(
                              onTap: () {
                                setState(() {
                                  areYouMale = false;
                                  check = true;
                                });
                              },
                              check: check && !areYouMale,
                            ),
                          ],
                        ),
                      ],
                    ),
                    _CustomTextField(
                      title: "휴대폰 번호",
                      hintText: '010-0000-1111',
                      focusNode: phoneNumberFocusNode,
                      onChanged: (val) {
                        phoneNumber = val;
                      },
                      onFieldSubmitted: (str) {
                        _formKey.currentState.validate();
                      },
                      validator: (_phone) => !phoneRegex.hasMatch(_phone)
                          ? '핸드폰 번호 형식에 맞지 않습니다.'
                          : null,
                    ),
                    SizedBox(
                      height: 15.0,
                    ),
                    Visibility(
                      visible: hasError,
                      child: Text(
                        errorStatus,
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 15.0,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 10 * 9,
                      child: Material(
                        color: enabled && _formKey.currentState.validate()
                            ? Color(0xff5dca65)
                            : Colors.black54,
                        borderRadius: BorderRadius.circular(5.0),
                        child: MaterialButton(
                            child: Text(
                              "완료",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                              ),
                            ),
                            onPressed: enabled &&
                                    _formKey.currentState.validate()
                                ? () async {
                                    try {
                                      if(list.where((el) => el == nickname).length != 0) {
                                        SchedulerBinding.instance.addPostFrameCallback((_) {
                                          setState(() {
                                            hasError = true;
                                            errorStatus = '닉네임이 중복됩니다.';
                                          });
                                          Timer(Duration(seconds: 3), () {
                                            setState(() {
                                              hasError = false;
                                              errorStatus = '';
                                            });
                                          });
                                        });
                                      } else if(_profileImage == null) {
                                        SchedulerBinding.instance.addPostFrameCallback((_) {
                                          setState(() {
                                            hasError = true;
                                            errorStatus = '프로필 사진을 지정해 주세요.';
                                          });
                                          Timer(Duration(seconds: 3), () {
                                            setState(() {
                                              hasError = false;
                                              errorStatus = '';
                                            });
                                          });
                                        });
                                      } else {
                                        final snapshot = await _fireStore
                                            .collection(
                                            "/userInfo_${authProvider.email}")
                                            .get();
                                        if (snapshot.docs.length == 0) {
                                          await _fireStore
                                              .collection(
                                              "/userInfo_${authProvider.email}")
                                              .add(
                                            {
                                              'nickname': nickname,
                                              'diaryCount': 0,
                                              'follower': [],
                                              'following': [],
                                              'birthday': birthdayTEC.text,
                                              'gender': areYouMale ? '남' : '여',
                                              'phoneNumber': phoneNumber,
                                            },
                                          );
                                          await _fireStore
                                              .collection("/userList")
                                              .add(
                                            {
                                              'username': nickname,
                                              'email': authProvider.email,
                                            },
                                          );

                                          await uploadImageToFirebase(
                                            'uploads/userProfile/$nickname',
                                            _profileImage,
                                          );
                                          authProvider.clearAll();
                                        }
                                        int popCount = 0;
                                        Navigator.popUntil(context, (route) {
                                          return popCount++ == 2;
                                        });
                                      }
                                    } on FirebaseAuthException catch (e) {} catch (e) {}
                                  }
                                : null),
                      ),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 10 * 9,
                      child: Text(
                        "프로필 사진, 생년월일, 성별은 당신과 맞는 트리움 환경을 제공하기 위해 사용되며, 트리움 이용기간 동안 보관되는 것에 동의합니다.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 10 * 9,
                      child: Text(
                        "프로필 공개 여부는 설정할 수 있으며, 위 내용에 동의하지 않아도 트리움을 이용할 수 있습니다.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final Function onTap;
  final Function onChanged;
  final FocusNode focusNode;
  final String hintText;
  final String title;
  final TextEditingController controller;
  final Function onFieldSubmitted;
  final Function validator;

  _CustomTextField(
      {this.focusNode,
      this.onTap,
      this.onChanged,
      this.onFieldSubmitted,
      this.title,
      this.hintText,
      this.controller,
      this.validator});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 10 * 9,
      child: TextFormField(
        controller: controller,
        onTap: onTap,
        onFieldSubmitted: onFieldSubmitted,
        onChanged: onChanged,
        validator: validator,
        style: TextStyle(fontSize: 30.0),
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: title,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black54,
            ),
          ),
          labelStyle: TextStyle(
            color: focusNode.hasFocus ? Colors.black : Colors.black54,
            fontSize: 15.0,
          ),
        ),
      ),
    );
  }
}
