import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter/material.dart';
import 'package:namu_diary/screens/ARGarden.dart';
import 'package:system_info/system_info.dart';

const int MEGABYTE = 1024 * 1024;

class ARGardenPrev extends StatefulWidget {
  final Function callback;

  ARGardenPrev({this.callback});

  @override
  _ARGardenPrevState createState() => _ARGardenPrevState();
}

class _ARGardenPrevState extends State<ARGardenPrev> {
  GlobalKey connectButton = GlobalKey();

  @override
  void initState() {
    widget.callback(
      [
        TargetFocus(
          identify: "connectToARGarden",
          keyTarget: connectButton,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AR가든 접속",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "AR가든에 접속하여 나만의 정원을 만들어 보세요!",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MaterialButton(
              key: connectButton,
              padding: EdgeInsets.zero,
              child: Image.asset(
                'assets/park.png',
                width: MediaQuery.of(context).size.width * 0.7,
              ),
              onPressed: () {
                if (Platform.isIOS) {
                  showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: Text('Alert!'),
                          content: Text(
                              "디바이스의 메모리가 4기가 이하일 경우 시스템 과부하가 발생하거나 어플이 강제 종료될 수 있습니다. 실행하시겠습니까?"),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.pop(context, "Cancel");
                              },
                            ),
                            TextButton(
                              child: Text('OK'),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(context, ARGarden.id);
                              },
                            )
                          ],
                        );
                      });
                } else {
                  if (SysInfo.getTotalPhysicalMemory() ~/ MEGABYTE < 4096) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Alert!'),
                          content: Text(
                              "디바이스의 메모리가 4기가 이하이므로 시스템 과부하가 발생하거나 어플이 강제 종료될 수 있습니다. 실행하시겠습니까?"),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.pop(context, "Cancel");
                              },
                            ),
                            TextButton(
                              child: Text('OK'),
                              onPressed: () {
                                Navigator.pushNamed(context, ARGarden.id);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    Navigator.pushNamed(context, ARGarden.id);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
