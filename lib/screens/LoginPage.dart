import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:namu_diary/screens/HelpScreen.dart';

import 'package:namu_diary/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:namu_diary/screens/RegisterPage.dart';
import 'package:namu_diary/screens/MainPage.dart';
import 'package:namu_diary/providers/AuthProvider.dart';
import 'package:namu_diary/constants.dart';
import 'package:namu_diary/screens/FindPassword.dart';
import 'package:shared_preferences/shared_preferences.dart';

final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");

class LoginPage extends StatefulWidget {
  static const id = 'login_page';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool enable1 = false, enable2 = false, error = false;
  bool willLoginPermanently = false;
  SharedPreferences pref;
  String errorString = '';

  @override
  void initState() {
    getPref();
  }

  getPref() async {
    pref = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: Form(
        key: _formKey,
        child: Consumer<AuthProvider>(
          builder: (_, provider, __) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width / 10 * 0.5,
                  ),
                  child: Text(
                    "로그인",
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width / 10 * 0.5,
                  ),
                  child: Row(
                    children: [
                      Text(
                        "혹은 ",
                        style: TextStyle(
                          fontSize: 12.0,
                        ),
                      ),
                      InkWell(
                        child: Text(
                          "계정 생성",
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.blueAccent,
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, RegisterPage.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              CustomTextFormField(
                label: "이메일 주소",
                hintText: "example@email.com",
                type: TextInputType.emailAddress,
                isPasswordField: false,
                onChanged: (String _email) {
                  provider.setEmail(_email);
                  setState(() {
                    if (emailRegex.hasMatch(_email)) {
                      enable1 = true;
                    } else {
                      enable1 = false;
                    }
                  });
                },
                onFieldSubmitted: (_email) {
                  _formKey.currentState.validate();
                },
                validator: (_email) =>
                    !emailRegex.hasMatch(_email) ? '이메일 형식에 맞지 않습니다.' : null,
              ),
              CustomTextFormField(
                label: "비밀번호",
                hintText: "비밀번호는 8자 이상 입력하세요.",
                isPasswordField: true,
                onChanged: (String _passwd) {
                  provider.setPasswd(_passwd);
                  setState(() {
                    if (_passwd.length >= 8) {
                      enable2 = true;
                    } else {
                      enable2 = false;
                    }
                  });
                },
                onFieldSubmitted: (_passwd) {
                  _formKey.currentState.validate();
                },
                validator: (String _passwd) =>
                    _passwd.length < 8 ? '비밀번호는 8자 이상이어야 합니다.' : null,
              ),
              SizedBox(
                height: 5.0,
              ),
              Visibility(
                visible: error,
                child: Text(
                  errorString,
                  style: TextStyle(
                    color: Colors.red,
                  ),
                )
              ),
              SizedBox(
                height: 10.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "로그인 유지",
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  RoundCheckbox(
                    onTap: () {
                      setState(() {
                        willLoginPermanently = !willLoginPermanently;
                      });
                      if(willLoginPermanently) {
                        pref.setBool('willLoginPermanently', true);
                      } else {
                        pref.setBool('willLoginPermanently', false);
                      }
                    },
                    check: willLoginPermanently,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.05,
                  ),
                ],
              ),
              SizedBox(
                height: 10.0,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 10 * 9,
                child: Material(
                  borderRadius: BorderRadius.circular(
                    5.0,
                  ),
                  color: enable1 && enable2
                      ? Color(kMainColor)
                      : Colors.grey.withOpacity(0.5),
                  child: MaterialButton(
                    child: Text(
                      "로그인",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () async {
                      final FormState form = _formKey.currentState;
                      if (form.validate()) {
                        String status = await provider.login(willLoginPermanently);
                        if (status == 'success') {
                          Navigator.pushReplacementNamed(context, HelpScreen.id);
                        } else {
                          setState(() {
                            error = true;
                            errorString = status;
                          });
                          Timer(
                            Duration(seconds: 5),
                            () => {
                              setState(
                                () {
                                  error = false;
                                  errorString = '';
                                },
                              )
                            },
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 10 * 9,
                child: Material(
                  color: Color(0xff5dca65),
                  borderRadius: BorderRadius.circular(5.0),
                  child: MaterialButton(
                    child: Text(
                      "네이버로 로그인",
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
                height: 10.0,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 10 * 9,
                child: Material(
                  color: Color(0xffd95140),
                  borderRadius: BorderRadius.circular(5.0),
                  child: MaterialButton(
                    child: Text(
                      "구글로 로그인",
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
                height: 10.0,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width / 10 * 0.5,
                  ),
                  child: InkWell(
                    child: Text(
                      "비밀번호 찾기",
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.blueAccent,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, FindPassword.id);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final Function onChanged, validator;
  final String label, hintText;
  final Function onFieldSubmitted;
  final TextInputType type;
  bool isPasswordField = false;

  CustomTextFormField(
      {this.onChanged,
      this.label,
      this.hintText,
      this.onFieldSubmitted,
      this.validator,
      this.type,
      this.isPasswordField});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 10.0,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 10 * 9,
          child: TextFormField(
            obscureText: isPasswordField == true ? true : false,
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
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
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.red,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.red,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.black,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(kMainColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
