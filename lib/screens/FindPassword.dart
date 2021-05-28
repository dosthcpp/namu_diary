import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:namu_diary/constants.dart';

final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
final _auth = FirebaseAuth.instance;

class FindPassword extends StatefulWidget {
  static const id = "find_password";

  @override
  _FindPasswordState createState() => _FindPasswordState();
}

class _FindPasswordState extends State<FindPassword> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool showEmailReset = false;
  bool wrongEmail = false;
  String email = '';
  User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !showEmailReset
            ? Text(
                "비밀번호 찾기",
                style: TextStyle(
                  color: Colors.black,
                ),
              )
            : null,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: MaterialButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.close,
            size: 30.0,
            color: Colors.black,
          ),
        ),
        actions: [
          Visibility(
            visible: !showEmailReset,
            child: TextButton(
              child: Text(
                "다음",
                style: TextStyle(),
              ),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  try {
                    _auth
                        .signInWithEmailAndPassword(
                      email: email,
                      password: 'password',
                    )
                        .catchError((e) {
                      if (e.code == 'wrong-password') {
                        setState(() {
                          showEmailReset = true;
                        });
                        _auth.sendPasswordResetEmail(email: email);
                        email = '';
                      } else if (e.code == 'user-not-found') {
                        setState(() {
                          wrongEmail = true;
                        });
                        Timer(
                          Duration(seconds: 3), () {
                          setState(() {
                            wrongEmail = false;
                          });
                        },
                        );
                      }
                    });
                  } catch (e) {
                    print(e);
                  }
                }
              },
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Offstage(
            offstage: showEmailReset,
            child: TickerMode(
              enabled: !showEmailReset,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: CustomTextFormField(
                        label: "이메일 주소",
                        hintText: "example@email.com",
                        type: TextInputType.emailAddress,
                        isPasswordField: false,
                        onChanged: (String _email) {
                          email = _email;
                        },
                        validator: (_email) => !emailRegex.hasMatch(_email)
                            ? '이메일 형식에 맞지 않습니다.'
                            : null,
                      ),
                    ),
                    Visibility(
                      visible: wrongEmail,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.1,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              "등록되지 않은 이메일입니다.",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.0,
                              )
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Offstage(
            offstage: !showEmailReset,
            child: TickerMode(
              enabled: showEmailReset,
              child: Center(
                child: Column(
                  children: [
                    Text(
                      "비밀번호 초기화 이메일을 보냈습니다.\n이메일로 받은 링크를 클릭하여 초기화를 완료하세요.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 10 * 8,
                      child: Material(
                        borderRadius: BorderRadius.circular(
                          5.0,
                        ),
                        color: Color(kMainColor),
                        child: MaterialButton(
                          child: Text(
                            "완료",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final Function onChanged, validator;
  final String label, hintText;
  final TextInputType type;
  bool isPasswordField = false;

  CustomTextFormField(
      {this.onChanged,
      this.label,
      this.hintText,
      this.validator,
      this.type,
      this.isPasswordField});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 10.0,
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 10 * 8,
        child: TextFormField(
          obscureText: isPasswordField == true ? true : false,
          onChanged: onChanged,
          validator: validator,
          keyboardType: type,
          cursorColor: Color(kMainColor),
          decoration: InputDecoration(
            hintText: hintText,
            labelText: label,
            labelStyle: TextStyle(
              fontSize: 18.0,
              color: Colors.black54,
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(kMainColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
