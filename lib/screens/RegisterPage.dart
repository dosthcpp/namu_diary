import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:namu_diary/screens/InputProfile.dart';
import 'package:namu_diary/providers/AuthProvider.dart';
import 'package:namu_diary/constants.dart';

final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
final RegExp birthRegex = RegExp(
    r"^(19[0-9][0-9]|20\d{2})([\/.-])(0[0-9]|1[0-2])([\/.-])(0[1-9]|[1-2][0-9]|3[0-1])$");
final _auth = FirebaseAuth.instance;

class RegisterPage extends StatefulWidget {
  static const id = "register_page";

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<bool> _enabled = List.filled(3, false);
  bool showAgreement = false;
  bool showEmailVerificationPage = false;
  bool isEmailVerified = false;
  List<bool> agree = List.filled(2, false);
  Timer _timer;
  User user;

  // TextEditingController certEditCtrl1 = TextEditingController();
  // FocusNode certFocusNode1 = FocusNode();
  // TextEditingController certEditCtrl2 = TextEditingController();
  // FocusNode certFocusNode2 = FocusNode();
  // TextEditingController certEditCtrl3 = TextEditingController();
  // FocusNode certFocusNode3 = FocusNode();
  // TextEditingController certEditCtrl4 = TextEditingController();
  // FocusNode certFocusNode4 = FocusNode();

  @override
  void initState() {
    if(_auth.currentUser != null) {
      _auth.signOut();
    }
    Future(
      () async {
        _timer = Timer.periodic(
          Duration(seconds: 3),
          (timer) async {
            if (_auth.currentUser != null) {
              _auth.currentUser..reload();
              var user = _auth.currentUser;
              if (user.emailVerified) {
                setState(() {
                  isEmailVerified = user.emailVerified;
                });
                timer.cancel();
              }
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !showEmailVerificationPage
            ? Text(
                "회원가입",
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
            visible: !showAgreement,
            child: TextButton(
              child: Text(
                "다음",
                style: TextStyle(),
              ),
              onPressed:
                  _enabled.where((enabled) => enabled == true).length == 3
                      ? () {
                          final FormState form = _formKey.currentState;
                          if (form.validate()) {
                            setState(() {
                              showAgreement = true;
                            });
                          }
                          // Navigator.pushNamed(context, InputProfile.id);
                        }
                      : null,
            ),
          ),
          // TextButton(
          //   child: Text(
          //     "뒤로",
          //     style: TextStyle(),
          //   ),
          //   onPressed: () {
          //     setState(
          //       () {
          //         showEmailVerificationPage = false;
          //         isEmailVerified = false;
          //       },
          //     );
          //   },
          // ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Offstage(
            offstage: showEmailVerificationPage,
            child: TickerMode(
              enabled: !showEmailVerificationPage,
              child: Form(
                key: _formKey,
                child: Consumer<AuthProvider>(
                  builder: (_, provider, __) => Column(
                    children: [
                      CustomTextFormField(
                        label: "이메일 주소",
                        hintText: "example@email.com",
                        type: TextInputType.emailAddress,
                        isPasswordField: false,
                        onChanged: (String _email) {
                          provider.setEmail(_email);
                          if (_email.length > 0) {
                            setState(() {
                              _enabled[0] = true;
                            });
                          } else {
                            setState(() {
                              _enabled[0] = false;
                            });
                          }
                        },
                        validator: (_email) => !emailRegex.hasMatch(_email)
                            ? '이메일 형식에 맞지 않습니다.'
                            : null,
                      ),
                      CustomTextFormField(
                        label: "비밀번호",
                        hintText: "비밀번호는 8자 이상 입력하세요.",
                        isPasswordField: true,
                        onChanged: (String _passwd) {
                          provider.setPasswd(_passwd);
                          if (_passwd.length > 0) {
                            setState(() {
                              _enabled[1] = true;
                            });
                          } else {
                            setState(() {
                              _enabled[1] = false;
                            });
                          }
                        },
                        validator: (String _passwd) =>
                            _passwd.length < 8 ? '비밀번호는 8자 이상이어야 합니다.' : null,
                      ),
                      CustomTextFormField(
                        label: "이름",
                        isPasswordField: false,
                        onChanged: (String _name) {
                          provider.setName(_name);
                          if (_name.length > 0) {
                            setState(() {
                              _enabled[2] = true;
                            });
                          } else {
                            setState(() {
                              _enabled[2] = false;
                            });
                          }
                        },
                      ),
                      SizedBox(
                          // height: 10.0,
                          ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width / 10 * 1,
                          ),
                          child: Visibility(
                            visible: showAgreement,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 10.0,
                                ),
                                Row(
                                  children: [
                                    RoundCheckbox(
                                      check: agree[0] && agree[1],
                                      onTap: () {
                                        setState(() {
                                          if (!agree[0] || !agree[1]) {
                                            agree[0] = true;
                                            agree[1] = true;
                                          } else {
                                            agree[0] = false;
                                            agree[1] = false;
                                          }
                                        });
                                      },
                                    ),
                                    SizedBox(
                                      width: 5.0,
                                    ),
                                    Text(
                                      "전체 동의",
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10.0,
                                ),
                                Row(
                                  children: [
                                    RoundCheckbox(
                                      check: agree[0],
                                      onTap: () {
                                        setState(() {
                                          agree[0] = !agree[0];
                                        });
                                      },
                                    ),
                                    SizedBox(
                                      width: 5.0,
                                    ),
                                    Text(
                                      "이용약관",
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10.0,
                                ),
                                Row(
                                  children: [
                                    RoundCheckbox(
                                      check: agree[1],
                                      onTap: () {
                                        setState(() {
                                          agree[1] = !agree[1];
                                        });
                                      },
                                    ),
                                    SizedBox(
                                      width: 5.0,
                                    ),
                                    Text(
                                      "개인정보 수집 및 이용에 대한 안내",
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.0),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width /
                                      10 *
                                      8,
                                  child: Material(
                                    borderRadius: BorderRadius.circular(
                                      5.0,
                                    ),
                                    color: agree[0] && agree[1]
                                        ? Color(kMainColor)
                                        : Colors.grey.withOpacity(0.5),
                                    child: MaterialButton(
                                      child: Text(
                                        "완료",
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      onPressed: agree[0] && agree[1]
                                          ? () {
                                              setState(
                                                () {
                                                  showEmailVerificationPage =
                                                      true;
                                                },
                                              );
                                              provider.sendEmail();
                                              // certFocusNode1.requestFocus();
                                            }
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Offstage(
            offstage: !showEmailVerificationPage,
            child: TickerMode(
              enabled: showEmailVerificationPage,
              child: Consumer<AuthProvider>(
                builder: (_, provider, __) => Center(
                  child: Column(
                    children: [
                      Text(
                        provider?.email ?? '',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Text(
                        "인증 메일을 발송했습니다.\n이메일로 받은 링크를 클릭하세요.",
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
                          color: isEmailVerified
                              ? Color(kMainColor)
                              : Colors.grey.withOpacity(0.5),
                          child: MaterialButton(
                            child: Text(
                              "완료",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            onPressed: isEmailVerified
                                ? () {
                                    Navigator.pushNamed(
                                        context, InputProfile.id);
                                  }
                                : null,
                          ),
                        ),
                      ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     CertNumberField(
                      //       ctrl: certEditCtrl1,
                      //       focusNode: certFocusNode1,
                      //       onChanged: (String _number) {
                      //         if (certEditCtrl1.text.length > 0) {
                      //           certEditCtrl1.text = _number.substring(0, 1);
                      //           certEditCtrl1.selection =
                      //               TextSelection.fromPosition(
                      //             TextPosition(
                      //               offset: certEditCtrl1.text.length,
                      //             ),
                      //           );
                      //           certFocusNode2.requestFocus();
                      //         }
                      //       },
                      //     ),
                      //     SizedBox(
                      //       width: 10.0,
                      //     ),
                      //     CertNumberField(
                      //       ctrl: certEditCtrl2,
                      //       focusNode: certFocusNode2,
                      //       onChanged: (String _number) {
                      //         if (certEditCtrl2.text.length > 0) {
                      //           certEditCtrl2.text = _number.substring(0, 1);
                      //           certEditCtrl2.selection =
                      //               TextSelection.fromPosition(
                      //             TextPosition(
                      //               offset: certEditCtrl2.text.length,
                      //             ),
                      //           );
                      //           certFocusNode3.requestFocus();
                      //         } else {
                      //           certFocusNode1.requestFocus();
                      //         }
                      //       },
                      //     ),
                      //     SizedBox(
                      //       width: 10.0,
                      //     ),
                      //     CertNumberField(
                      //       ctrl: certEditCtrl3,
                      //       focusNode: certFocusNode3,
                      //       onChanged: (String _number) {
                      //         if (certEditCtrl3.text.length > 0) {
                      //           certEditCtrl3.text = _number.substring(0, 1);
                      //           certEditCtrl3.selection =
                      //               TextSelection.fromPosition(
                      //             TextPosition(
                      //               offset: certEditCtrl3.text.length,
                      //             ),
                      //           );
                      //           certFocusNode4.requestFocus();
                      //         } else {
                      //           certFocusNode2.requestFocus();
                      //         }
                      //       },
                      //     ),
                      //     SizedBox(
                      //       width: 10.0,
                      //     ),
                      //     CertNumberField(
                      //       ctrl: certEditCtrl4,
                      //       focusNode: certFocusNode4,
                      //       onChanged: (String _number) {
                      //         if (certEditCtrl4.text.length > 0) {
                      //           certEditCtrl4.text = _number.substring(0, 1);
                      //           certEditCtrl4.selection =
                      //               TextSelection.fromPosition(
                      //             TextPosition(
                      //               offset: certEditCtrl4.text.length,
                      //             ),
                      //           );
                      //         } else {
                      //           certFocusNode3.requestFocus();
                      //         }
                      //       },
                      //     ),
                      //   ],
                      // )
                    ],
                  ),
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
    return Center(
      child: Padding(
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
      ),
    );
  }
}

class RoundCheckbox extends StatelessWidget {
  final Function onTap;
  final bool check;

  RoundCheckbox({this.onTap, this.check});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 25.0,
        height: 25.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: check ? Color(kMainColor) : Colors.transparent,
          border: Border.all(
            color: check ? Colors.transparent : Colors.grey.withOpacity(0.5),
          ),
        ),
        child: Icon(
          Icons.check,
          size: 18.0,
          color: check ? Colors.white : Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }
}
//
// class CertNumberField extends StatelessWidget {
//   final Function onChanged;
//   final TextEditingController ctrl;
//   final FocusNode focusNode;
//
//   CertNumberField({this.onChanged, this.ctrl, this.focusNode});
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 20.0,
//       child: TextFormField(
//         controller: ctrl,
//         focusNode: focusNode,
//         textAlign: TextAlign.center,
//         onChanged: onChanged,
//         keyboardType: TextInputType.number,
//         cursorColor: Color(kMainColor),
//         decoration: InputDecoration(
//           labelStyle: TextStyle(
//             fontSize: 18.0,
//             color: Colors.black54,
//           ),
//           focusedBorder: UnderlineInputBorder(
//             borderSide: BorderSide(
//               color: Color(kMainColor),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
