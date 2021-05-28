import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'package:namu_diary/api.dart';
import 'package:namu_diary/constants.dart';
import 'package:namu_diary/main.dart';
import 'package:namu_diary/providers/NavigationProvider.dart';
import 'package:namu_diary/screens/MainPage.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:http/http.dart' as http;
import 'package:namu_diary/utils.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:xml2json/xml2json.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:watcher/watcher.dart';

extension filterTreeName on String {
  bool isTreeName(List<String> treeDict) {
    final data = treeDict;
    var i = 0;
    for (; i < data.length && !(data[i] == this || this.contains("나무")); ++i);
    if (i < data.length) {
      return true;
    } else {
      return false;
    }
  }
}

class ARGarden extends StatefulWidget {
  static const id = 'ar_garden';

  @override
  _ARGardenState createState() => _ARGardenState();
}

class _ARGardenState extends State<ARGarden> {
  UnityWidgetController _unityWidgetController;
  bool isTreeNameLoading = false;
  List<String> treeNames = [];
  List<String> treeExplanation = [];
  List<TargetFocus> targets = [];
  String imageData = '';
  bool showTexture = true;
  int curIdx = 0;
  int flag = 0;
  int recognizeTree = 0, readQR = 1;

  bool showMsg = false, showSlider = false;
  bool canRecord = false;
  bool recording = false;
  String nickname = '';
  String selectedMsg = '';
  double selectedScale = 1.0;
  double selectedAngle = 0.0;
  double yLoc = 1.0;

  Timer dismissSlider;

  GlobalKey sliders = GlobalKey();
  GlobalKey recognizeTreeButton = GlobalKey();
  GlobalKey selectRespawnObjectButton = GlobalKey();
  GlobalKey saveButton = GlobalKey();
  GlobalKey selectObjectButton = GlobalKey();
  GlobalKey removeObjectButton = GlobalKey();
  GlobalKey changeGroundTextureButton = GlobalKey();
  GlobalKey toggleGroundTextureButton = GlobalKey();
  GlobalKey recordButton = GlobalKey();

  @override
  void initState() {
    targets.add(
      TargetFocus(
        identify: "sliders",
        keyTarget: sliders,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "슬라이더(타겟 선택시 화면 중간에 나타남)",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "위 가로 슬라이더: 오브젝트의 각도를 변경\n아래 가로 슬라이더: 오브젝트의 크기 변경\n오른쪽 세로 슬라이더: 오브젝트의 높이 변경",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "recognizeTreeButton",
        keyTarget: recognizeTreeButton,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "식물 인식",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "정원 조성중 모르는 나무가 있으면 이 버튼을 눌러 인식합니다.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "selectRespawnObjectButton",
        keyTarget: selectRespawnObjectButton,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "소환 오브젝트 변경",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "소환할 오브젝트를 변경합니다.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "saveButton",
        keyTarget: saveButton,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "세이브",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "현재까지 작성한 정원을 저장합니다.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "selectObjectButton",
        keyTarget: selectObjectButton,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "오브젝트 선택",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "소환된 오브젝트를 선택하여 위치를 바꾸거나 높이, 각도 등을 변경합니다.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "removeObjectButton",
        keyTarget: removeObjectButton,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "오브젝트 삭제",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "선택한 오브젝트를 삭제합니다.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "changeGroundTextureButton",
        keyTarget: changeGroundTextureButton,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "땅 텍스쳐 변경",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "땅 텍스쳐를 변경합니다.(잔디 또는 흙)",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "toggleGroundTextureButton",
        keyTarget: toggleGroundTextureButton,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "땅 보이기/숨기기",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "땅 텍스쳐를 숨기거나 보입니다.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "recordButton",
        keyTarget: recordButton,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "녹화",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "현재 작성중인 장면을 녹화하여 갤러리에 저장합니다.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // 그냥 꺼짐..
  // @override
  // void deactivate() {
  //   SchedulerBinding.instance.addPostFrameCallback((_) async {
  //     if(await _unityWidgetController.isLoaded() || await _unityWidgetController.isReady()) {
  //       await _unityWidgetController.quit();
  //     }
  //   });
  // }


  Future<void> setFlag(_flag) async {
    flag = _flag;
  }

  Future<void> setRecording() async {
    setState(() {
      recording = !recording;
    });
  }

  final items = [
    "Trees",
    "Flowers",
    "Vegetables",
    "Structures",
    "Tools",
    "Rocks",
    "Effects",
    "Farmer",
  ];

  Widget RenderIcons(context, index, NavigationProvider provider) {
    switch (provider.arItemIdx) {
      case 0:
        return Container(
          width: MediaQuery.of(context).size.width / 6.5,
          child: InkWell(
            child: Image.asset(
              'assets/aricon/tree00${numberPad((provider.arIconIdx + index).toString())}.png',
            ),
            onTap: () {
              _unityWidgetController.postMessage(
                "Respawner_${arGardenProvider.photonNickname}",
                "ChangeRespawnTarget",
                "${provider.arIconIdx + index}",
              );
            },
          ),
        );
      case 1:
        return Container(
          width: MediaQuery.of(context).size.width / 6.5,
          child: InkWell(
            child: provider.arIconIdx + index + 45 <= 322
                ? Image.asset(
                    'assets/aricon/tree00${numberPad((provider.arIconIdx + index + 45).toString())}.png',
                  )
                : Container(),
            onTap: () {
              _unityWidgetController.postMessage(
                "Respawner_${arGardenProvider.photonNickname}",
                "ChangeRespawnTarget",
                "${provider.arIconIdx + index + 45}",
              );
            },
          ),
        );
      case 2:
        return Container(
          width: MediaQuery.of(context).size.width / 6.5,
          child: InkWell(
            child: provider.arIconIdx + index + 323 <= 336
                ? Image.asset(
                    'assets/aricon/tree00${numberPad((provider.arIconIdx + index + 323).toString())}.png',
                  )
                : Container(),
            onTap: () {
              _unityWidgetController.postMessage(
                "Respawner_${arGardenProvider.photonNickname}",
                "ChangeRespawnTarget",
                "${provider.arIconIdx + index + 323}",
              );
            },
          ),
        );
      case 3:
        return Container(
          width: MediaQuery.of(context).size.width / 6.5,
          child: InkWell(
            child: provider.arIconIdx + index + 337 <= 362
                ? Image.asset(
                    'assets/aricon/tree00${numberPad((provider.arIconIdx + index + 337).toString())}.png',
                  )
                : Container(),
            onTap: () {
              _unityWidgetController.postMessage(
                "Respawner_${arGardenProvider.photonNickname}",
                "ChangeRespawnTarget",
                "${provider.arIconIdx + index + 337}",
              );
            },
          ),
        );
      case 4:
        return Container(
          width: MediaQuery.of(context).size.width / 6.5,
          child: InkWell(
            child: provider.arIconIdx + index + 363 <= 383
                ? Image.asset(
                    'assets/aricon/tree00${numberPad((provider.arIconIdx + index + 363).toString())}.png',
                  )
                : Container(),
            onTap: () {
              _unityWidgetController.postMessage(
                "Respawner_${arGardenProvider.photonNickname}",
                "ChangeRespawnTarget",
                "${provider.arIconIdx + index + 363}",
              );
            },
          ),
        );
      case 5:
        return Container(
          width: MediaQuery.of(context).size.width / 6.5,
          child: InkWell(
            child: provider.arIconIdx + index + 383 <= 402
                ? Image.asset(
                    'assets/aricon/tree00${numberPad((provider.arIconIdx + index + 383).toString())}.png',
                  )
                : Container(),
            onTap: () {
              _unityWidgetController.postMessage(
                "Respawner_${arGardenProvider.photonNickname}",
                "ChangeRespawnTarget",
                "${provider.arIconIdx + index + 383}",
              );
            },
          ),
        );
      case 6:
        return Container(
          width: MediaQuery.of(context).size.width / 6.5,
          child: InkWell(
            child: provider.arIconIdx + index + 403 <= 404
                // 403, 404
                ? Center(
                    child: Text(
                      "나비효과",
                    ),
                  )
                : provider.arIconIdx + index + 403 <= 407
                    ? Center(
                        child: Text(
                          "벌레효과",
                        ),
                      )
                    : Container(),
            // 405, 406, 407
            onTap: () {
              _unityWidgetController.postMessage(
                "Respawner_${arGardenProvider.photonNickname}",
                "ChangeRespawnTarget",
                "${provider.arIconIdx + index + 403}",
              );
            },
          ),
        );
      case 7:
        return Container(
          width: MediaQuery.of(context).size.width / 6.5,
          child: InkWell(
            child: provider.arIconIdx + index + 408 <= 410
                ? Image.asset(
                    'assets/aricon/tree00${numberPad((provider.arIconIdx + index + 408).toString())}.png',
                  )
                : Container(),
            onTap: () {
              _unityWidgetController.postMessage(
                "Respawner_${arGardenProvider.photonNickname}",
                "ChangeRespawnTarget",
                "${provider.arIconIdx + index + 408}",
              );
            },
          ),
        );
      default:
        return Container();
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => SafeArea(
          bottom: false,
          child: Stack(
            children: [
              UnityWidget(
                onUnityCreated: onUnityCreated,
                onUnityMessage: onUnityMessage,
              ),
              Positioned.fill(
                bottom: 100.0,
                child: Visibility(
                  visible: showMsg,
                  child: Text(
                    selectedMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 120.0,
                right: MediaQuery.of(context).size.width / 8,
                left: MediaQuery.of(context).size.width / 8,
                child: Visibility(
                  visible: showSlider,
                  child: Container(
                    height: 100,
                    child: Slider(
                      value: selectedScale,
                      min: 0.1,
                      max: 3.0,
                      divisions: 50,
                      onChanged: (double value) {
                        if (dismissSlider != null) {
                          dismissSlider?.cancel();
                        }
                        dismissSlider = Timer(Duration(seconds: 3), () {
                          setState(() {
                            showSlider = false;
                          });
                          _unityWidgetController.postMessage(
                            "Respawner_${arGardenProvider.photonNickname}",
                            "ReleaseSelected",
                            "",
                          );
                        });
                        setState(() {
                          selectedScale = value;
                        });
                        _unityWidgetController.postMessage(
                          "Respawner_${arGardenProvider.photonNickname}",
                          "Resize",
                          "$value",
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 60.0,
                right: 0.0,
                child: InkWell(
                  key: sliders,
                  child: Image.asset(
                    'assets/question-mark.png',
                    width: 60.0,
                  ),
                  onTap: () {
                    TutorialCoachMark(
                      context,
                      targets: targets,
                      colorShadow: Color(kMainColor),
                      hideSkip: true,
                    )..show();
                  },
                ),
              ),
              Positioned(
                right: 0,
                bottom: MediaQuery.of(context).size.height / 5,
                top: MediaQuery.of(context).size.height / 5,
                child: Visibility(
                  visible: showSlider,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Slider(
                      value: yLoc,
                      min: -1.0,
                      max: 1.0,
                      divisions: 200,
                      onChanged: (double value) {
                        if (dismissSlider != null) {
                          dismissSlider?.cancel();
                        }
                        dismissSlider = Timer(Duration(seconds: 3), () {
                          setState(() {
                            showSlider = false;
                          });
                          _unityWidgetController.postMessage(
                            "Respawner_${arGardenProvider.photonNickname}",
                            "ReleaseSelected",
                            "",
                          );
                        });
                        setState(() {
                          yLoc = value;
                        });
                        _unityWidgetController.postMessage(
                          "Respawner_${arGardenProvider.photonNickname}",
                          "AdjustHeight",
                          "$value",
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 60.0,
                right: MediaQuery.of(context).size.width / 8,
                left: MediaQuery.of(context).size.width / 8,
                child: Visibility(
                  visible: showSlider,
                  child: Container(
                    height: 100,
                    child: Slider(
                      value: selectedAngle,
                      min: -180.0,
                      max: 180.0,
                      divisions: 360,
                      onChanged: (double value) {
                        if (dismissSlider != null) {
                          dismissSlider?.cancel();
                        }
                        dismissSlider = Timer(Duration(seconds: 3), () {
                          setState(() {
                            showSlider = false;
                          });
                          _unityWidgetController.postMessage(
                            "Respawner_${arGardenProvider.photonNickname}",
                            "ReleaseSelected",
                            "",
                          );
                        });
                        setState(() {
                          selectedAngle = value;
                        });
                        _unityWidgetController.postMessage(
                          "Respawner_${arGardenProvider.photonNickname}",
                          "Rotate",
                          "$value",
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: FloatingActionButton(
                  key: recognizeTreeButton,
                  heroTag: 'recognize',
                  onPressed: () async {
                    setFlag(recognizeTree).then((_) {
                      _unityWidgetController.postMessage(
                        "AROrigin_${arGardenProvider.photonNickname}",
                        "sendImage",
                        "",
                      );
                    });
                    // await identify();
                  },
                  backgroundColor: Color(kMainColor),
                  child: Image.asset(
                    'assets/tree.png',
                    width: 30.0,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 60.0,
                child: FloatingActionButton(
                  key: selectRespawnObjectButton,
                  heroTag: 'selectRespawnObject',
                  child: Image.asset(
                    'assets/select.png',
                    width: 30.0,
                  ),
                  onPressed: () {
                    _unityWidgetController.postMessage(
                      "Respawner_${arGardenProvider.photonNickname}",
                      "ReleaseSelected",
                      "",
                    );
                    Scaffold.of(context).showBottomSheet<void>(
                      (BuildContext context) {
                        return Container(
                          height: 180,
                          color: Colors.white,
                          child: Column(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    child: Icon(
                                      Icons.close,
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: 8,
                                    itemBuilder: (context, index) => TextButton(
                                      child: Text(
                                        items[index],
                                        style: TextStyle(
                                          color: Color(
                                            kMainColor,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        navigationProvider.setIconIdx(0);
                                        navigationProvider.setARItemIdx(index);
                                      },
                                    ),
                                    separatorBuilder: (context, index) =>
                                        SizedBox(
                                      width: 3.0,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 9,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      child: InkWell(
                                        child: Icon(
                                          Icons.arrow_back_ios,
                                        ),
                                        onTap: () {
                                          navigationProvider.decreaseIndex();
                                        },
                                      ),
                                    ),
                                    Center(
                                      child: Consumer<NavigationProvider>(
                                        builder: (_, provider, __) =>
                                            ListView.separated(
                                          shrinkWrap: true,
                                          scrollDirection: Axis.horizontal,
                                          separatorBuilder: (context, index) {
                                            return SizedBox(
                                              width: 8.0,
                                            );
                                          },
                                          itemBuilder: (context, index) {
                                            return RenderIcons(
                                                context, index, provider);
                                          },
                                          itemCount: 5,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      child: InkWell(
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                        ),
                                        onTap: () {
                                          navigationProvider.increaseIndex();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  backgroundColor: Color(kMainColor),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 120.0,
                child: FloatingActionButton(
                  key: saveButton,
                  heroTag: 'save',
                  onPressed: () async {
                    final path =
                        (await getApplicationDocumentsDirectory()).path;
                    final watcher = DirectoryWatcher("$path/");
                    watcher.events.listen(
                      (event) {
                        if (event.path.split("/").last == 'save.es3') {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Platform.isAndroid
                                  ? AlertDialog(
                                      title: Text('Alert!'),
                                      content: Text("세이브파일이 저장되었습니다."),
                                      actions: [
                                        TextButton(
                                          child: Text('OK'),
                                          onPressed: () {
                                            Navigator.pop(context, "OK");
                                          },
                                        ),
                                      ],
                                    )
                                  : CupertinoAlertDialog(
                                      title: Text('Alert!'),
                                      content: Text("세이브파일이 저장되었습니다."),
                                      actions: [
                                        TextButton(
                                          child: Text('OK'),
                                          onPressed: () {
                                            Navigator.pop(context, "OK");
                                          },
                                        ),
                                      ],
                                    );
                            },
                          );
                        }
                      },
                    );
                    _unityWidgetController.postMessage(
                      "Respawner_${arGardenProvider.photonNickname}",
                      "SaveGardenObjs",
                      "",
                    );
                  },
                  backgroundColor: Colors.red,
                  child: Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 180.0,
                child: FloatingActionButton(
                  key: selectObjectButton,
                  heroTag: 'selectobj',
                  onPressed: () async {
                    _unityWidgetController.postMessage(
                      "Respawner_${arGardenProvider.photonNickname}",
                      "SelectObject",
                      "",
                    );
                  },
                  backgroundColor: Color(kMainColor),
                  child: Icon(
                    Icons.select_all,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 240.0,
                child: FloatingActionButton(
                  key: removeObjectButton,
                  heroTag: 'destroy',
                  onPressed: () async {
                    _unityWidgetController.postMessage(
                      "Respawner_${arGardenProvider.photonNickname}",
                      "DestroySelected",
                      "",
                    );
                  },
                  backgroundColor: Colors.red,
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 60.0,
                right: 0.0,
                child: FloatingActionButton(
                  key: changeGroundTextureButton,
                  heroTag: 'setTexture',
                  onPressed: () {
                    _unityWidgetController.postMessage(
                      "AROrigin_${arGardenProvider.photonNickname}",
                      "ChangeTexture",
                      "",
                    );
                  },
                  backgroundColor: Color(kMainColor),
                  child: Icon(
                    Icons.texture,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 120.0,
                right: 0.0,
                child: FloatingActionButton(
                  key: toggleGroundTextureButton,
                  heroTag: 'toggleTexture',
                  onPressed: () async {
                    _unityWidgetController.postMessage(
                      "AROrigin_${arGardenProvider.photonNickname}",
                      "SetTexture",
                      "",
                    );
                    setState(() {
                      showTexture = !showTexture;
                    });
                  },
                  backgroundColor: showTexture ? Colors.red : Color(kMainColor),
                  child: Icon(
                    showTexture ? Icons.close : Icons.texture,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: FloatingActionButton(
                  key: recordButton,
                  heroTag: 'record',
                  onPressed: () async {
                    if (canRecord) {
                      setRecording().then((_) async {
                        if (recording == false) {
                          final path =
                              (await getApplicationDocumentsDirectory()).path;
                          final watcher = DirectoryWatcher("$path/Recordings/");
                          watcher.events.listen(
                            (event) {
                              GallerySaver.saveVideo(event.path).then(
                                (_) {
                                  setState(() {
                                    isTreeNameLoading = false;
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Platform.isAndroid
                                          ? AlertDialog(
                                              title: Text('Alert!'),
                                              content: Text("비디오가 저장되었습니다."),
                                              actions: [
                                                TextButton(
                                                  child: Text('OK'),
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        context, "OK");
                                                  },
                                                ),
                                              ],
                                            )
                                          : CupertinoAlertDialog(
                                              title: Text('Alert!'),
                                              content: Text("비디오가 저장되었습니다."),
                                              actions: [
                                                TextButton(
                                                  child: Text('OK'),
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        context, "OK");
                                                  },
                                                ),
                                              ],
                                            );
                                    },
                                  );
                                },
                              );
                            },
                          );
                          _unityWidgetController.postMessage(
                            "ScreenRecordingManager",
                            "StopRecording",
                            "",
                          );
                        } else {
                          _unityWidgetController.postMessage(
                            "ScreenRecordingManager",
                            "StartRecording",
                            "",
                          );
                        }
                      });
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Platform.isAndroid
                              ? AlertDialog(
                                  title: Text('Alert!'),
                                  content: Text("화면 녹화가 준비되지 않았습니다."),
                                  actions: [
                                    TextButton(
                                      child: Text('OK'),
                                      onPressed: () {
                                        Navigator.pop(context, "OK");
                                      },
                                    ),
                                  ],
                                )
                              : CupertinoAlertDialog(
                                  title: Text('Alert!'),
                                  content: Text("Recorder is not set!"),
                                  actions: [
                                    TextButton(
                                      child: Text('OK'),
                                      onPressed: () {
                                        Navigator.pop(context, "OK");
                                      },
                                    ),
                                  ],
                                );
                        },
                      );
                    }
                  },
                  backgroundColor: Color(kMainColor),
                  child: recording
                      ? Icon(
                          Icons.stop,
                          size: 30.0,
                        )
                      : Icon(
                          Icons.play_arrow,
                          size: 30.0,
                        ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Visibility(
                    visible: isTreeNameLoading,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  icon: Icon(Icons.close),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Callback that connects the created controller to the unity controller
  void onUnityCreated(controller) {
    this._unityWidgetController = controller;
  }

  Future<List<String>> search(message) async {
    treeNames.clear();
    final response = await http.post(
      Uri.https('api.plant.id', '/v2/identify'),
      headers: {"Content-Type": "application/json", "Api-Key": apiKey},
      body: jsonEncode(
        {
          "images": [message.toString()],
          "modifiers": ["similar_images"],
          "plant_details": [
            "common_names",
            "url",
            "wiki_description",
            "taxonomy"
          ]
        },
      ),
    );
    final suggestions = json.decode(response.body)['suggestions'];
    for (var i = 0; i < suggestions.length; ++i) {
      final xml2json = Xml2Json();
      final _res = await http.get(
        Uri.http(
          'openapi.nature.go.kr',
          '/openapi/service/rest/PlantService/plntIlstrSearch',
          {
            'serviceKey': treeSearchApiKey,
            'st': '2',
            'sw': suggestions[i]['plant_name'],
            'dateGbn': '',
            'dateFrom': '',
            'numOfRows': '10',
            'pageNo': '1',
          },
        ),
      );
      xml2json.parse(utf8.decode(_res.bodyBytes));
      final data =
          json.decode(xml2json.toBadgerfish())['response']['body']['items'];
      if (data.length > 0) {
        for (var item in Map.castFrom(data).values) {
          try {
            for (var _item in item) {
              treeNames.add(Map.from(_item['plantGnrlNm']).values.elementAt(0));
            }
          } catch (e) {
            treeNames.add(
                Map.from(Map.from(item)['plantGnrlNm']).values.elementAt(0));
          }
        }
      }
      try {
        final _suggestions = suggestions[i]['plant_details']['common_names'];
        if (_suggestions != null && _suggestions.length > 0) {
          for (var name in _suggestions) {
            final response = await http.get(
              Uri.https(
                'ko.wikipedia.org',
                '/w/api.php',
                {
                  'action': 'query',
                  'prop': 'extracts',
                  'origin': '*',
                  'format': 'json',
                  'generator': 'search',
                  'gsrnamespace': '0',
                  'gsrlimit': '1',
                  'gsrsearch': name,
                },
              ),
            );
            final explanation = Map.castFrom(json.decode(response.body)).values;
            if (explanation.length > 1) {
              for (var el in explanation) {
                if (el.runtimeType != String) {
                  final boom = Map.castFrom(el);
                  if (boom.containsKey('pages')) {
                    final Map gatheredInfo =
                        Map.castFrom(Map.castFrom(boom['pages']).values.first);
                    if ((gatheredInfo['title'] as String)
                        .isTreeName(dicProvider.treeDict)) {
                      treeNames.add(gatheredInfo['title']);
                    }
                  }
                }
              }
            }
          }
        } else {
          print('null array cannot be iterated!');
        }
      } on Exception catch (e) {
        print("Fetch failed!");
        isTreeNameLoading = false;
      }
    }
    return treeNames.toSet().toList();
  }

  Future<List<String>> postSearch(names) async {
    treeExplanation.clear();
    for (var name in names) {
      final response = await http.get(
        Uri.https(
          'ko.wikipedia.org',
          '/w/api.php',
          {
            'action': 'query',
            'prop': 'extracts',
            'origin': '*',
            'format': 'json',
            'generator': 'search',
            'gsrnamespace': '0',
            'gsrlimit': '1',
            'gsrsearch': name,
          },
        ),
      );
      final explanation = Map.castFrom(json.decode(response.body)).values;
      if (explanation.length > 1) {
        final searchList = List.from(explanation);
        String found;
        var i = 0;
        for (; i < searchList.length; ++i) {
          found = '';
          if (searchList[i].runtimeType != String) {
            final boom = Map.castFrom(searchList[i]);
            if (boom.containsKey('pages')) {
              final gatheredInfo =
                  Map.castFrom(Map.castFrom(boom['pages']).values.first);
              if (gatheredInfo['title'] == name) {
                found = gatheredInfo['extract'];
                break;
              }
            }
          }
        }
        if (i < searchList.length) {
          treeExplanation.add(found);
        } else {
          treeExplanation.add('검색결과 없음');
        }
      } else {
        treeExplanation.add('검색결과 없음');
      }
    }
    return treeExplanation;
  }

  void onUnityMessage(message) async {
    final msg = message.toString();
    if (msg.startsWith("#")) {
      // init
      arGardenProvider.setPhotonNickname(msg.substring(1));
      // final _ref = FirebaseStorage.instance
      //     .ref()
      //     .child('uploads/save/${userProvider.currentUser}/save.es3');
      // try {
      //   final httpClient = HttpClient();
      //   var request = await httpClient.getUrl(Uri.parse(await _ref.getDownloadURL()));
      //   var response = await request.close();
      //   var bytes = await consolidateHttpClientResponseBytes(response);
      //   String dir = (await getApplicationDocumentsDirectory()).path;
      //   File file = File('$dir/save.es3');
      //   await file.writeAsBytes(bytes);
      //   _unityWidgetController.postMessage(
      //     "Respawner_${arGardenProvider.photonNickname}",
      //     "Init",
      //     file,
      //   );
      // } catch(e) {
      //   final filePath =
      //       "${(await getApplicationDocumentsDirectory()).path}/save.es3";
      //   if (File(filePath).existsSync()) {
      //     _unityWidgetController.postMessage(
      //       "Respawner_${arGardenProvider.photonNickname}",
      //       "Init",
      //       filePath,
      //     );
      //   }
      // }
    } else if (msg.startsWith("!")) {
      if (msg.substring(1) == 'first') {
        canRecord = true;
      } else if (msg.substring(1) == 'missing') {
        setState(() {
          showSlider = false;
        });
      } else {
        if (dismissSlider != null) {
          dismissSlider?.cancel();
        }
        setState(() {
          selectedMsg = msg.substring(1);
          yLoc = 0.0;
          selectedScale = 1.0;
          selectedAngle = 0.0;
          showMsg = true;
          showSlider = true;
        });
        Timer(Duration(milliseconds: 200), () {
          setState(() {
            showMsg = false;
          });
        });
        dismissSlider = Timer(Duration(seconds: 3), () {
          setState(() {
            showSlider = false;
          });
          _unityWidgetController.postMessage(
            "Respawner_${arGardenProvider.photonNickname}",
            "ReleaseSelected",
            "",
          );
        });
      }
    } else {
      if (flag == recognizeTree) {
        setState(() {
          isTreeNameLoading = true;
        });
        final names = await search(message);
        final explanations = await postSearch(names);
        if (names.length > 0 && explanations.length > 0) {
          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        20.0,
                      ),
                    ),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (context, idx) {
                        return Offstage(
                          offstage: curIdx != idx,
                          child: TickerMode(
                            enabled: curIdx == idx,
                            child: Container(
                              height:
                                  MediaQuery.of(context).size.height / 10 * 6.5,
                              padding: EdgeInsets.all(
                                20.0,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  20.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    offset: Offset(0, 5),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (curIdx > 0) {
                                              setState(() {
                                                curIdx--;
                                              });
                                            }
                                          },
                                          child: Icon(
                                            Icons.arrow_back,
                                          ),
                                        ),
                                        Text(
                                          names[idx],
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            if (curIdx < names.length - 1) {
                                              setState(() {
                                                curIdx++;
                                              });
                                            }
                                          },
                                          child: Icon(
                                            Icons.arrow_forward,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 10,
                                    child: SingleChildScrollView(
                                      child: Html(
                                        data: explanations[idx],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          "확인",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      itemCount: names.length,
                    ),
                  );
                },
              );
            },
          );
        }
        setState(() {
          isTreeNameLoading = false;
        });
      }
    }
  }
}
