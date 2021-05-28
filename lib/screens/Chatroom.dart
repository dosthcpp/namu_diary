import 'dart:io';
import 'dart:ui';
import 'dart:isolate';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:namu_diary/arguments.dart';
import 'package:namu_diary/shared/ProfileImage.dart';
import 'package:namu_diary/main.dart';
import 'package:namu_diary/constants.dart';
import 'package:namu_diary/screens/ViewImage.dart';
import 'package:namu_diary/utils.dart';

final _storage = FirebaseStorage.instance;

class ChatRoom extends StatefulWidget {
  static const id = 'chat_room';

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final textEditingController = TextEditingController();
  ScrollController scrollController = ScrollController();

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  GlobalKey imageButton = GlobalKey();
  GlobalKey saveButton = GlobalKey();
  GlobalKey openDrawer = GlobalKey();
  List<TargetFocus> buttonTargets = [];

  int progress = 0;
  String messageText;
  bool isVisible = true;
  bool showModal = false;
  String status = '';
  Map<String, String> emails = {};

  Future uploadARSaveFileToFirebase(File saveFile, String path) async {
    final fileRef = _storage.ref().child(path);
    if (fileRef != null) {
      fileRef.delete();
    }
    await fileRef.putFile(saveFile);
  }

  Future exitRoom(curChatDoc, store) async {
    final result = await store
        .collection(curChatDoc)
        .where('username', isEqualTo: userProvider.currentUser)
        .limit(1)
        .get();
    if (result.docs.length != 0) {
      await store.collection(curChatDoc).doc(result.docs[0].id).delete();
    } else {
      print('something gone wrong!');
    }
  }

  Future<Map<String, String>> getEmailFromParticipants(
      List<dynamic> participants) async {
    for (var i = 0; i < participants.length; ++i) {
      emails[participants[i]] = await userProvider.getEmail(participants[i]);
    }
    return emails;
  }

  Future<File> pickImage() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      String filePath = result?.files?.single?.path ?? '';

      if (filePath != null) {
        return Future.value(File(filePath));
      } else {
        print('No image selected.');
        return null;
      }
    } else {
      // User canceled the picker
      return null;
    }
  }

  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen(
      (dynamic data) {
        String id = data[0];
        DownloadTaskStatus status = data[1];
        int progress = data[2];
        if (progress == 100) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Platform.isAndroid
                  ? AlertDialog(
                      title: Text('Alert!'),
                      content: Text("세이브파일 저장 완료"),
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
                      content: Text("세이브파일 저장 완료"),
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
    FlutterDownloader.registerCallback(downloadCallback);

    buttonTargets.add(
      TargetFocus(
        identify: "imageButton",
        keyTarget: imageButton,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "이미지 업로드",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "나무 이미지를 업로드하거나, 자랑하고 싶은 이미지를 업로드 할 수도 있습니다.",
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

    buttonTargets.add(
      TargetFocus(
        identify: "saveButton",
        keyTarget: saveButton,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "세이브 공유",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "AR가든 세이브파일을 공유하는 버튼입니다.",
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

    buttonTargets.add(
      TargetFocus(
        identify: "openDrawer",
        keyTarget: openDrawer,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "참여자 보기",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "채팅 참여자들을 볼 수 있고, 탭하여 참여자와 개인 채팅을 즐기거나 팔로우할 수 있습니다.",
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

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    final ChatRoomArgs arguments =
        ModalRoute.of(context).settings.arguments as ChatRoomArgs;

    final isPrivateChat = arguments.chatDocPath.startsWith('/private');

    return WillPopScope(
      onWillPop: () async => false,
      child: StreamBuilder<QuerySnapshot>(
        stream: !isPrivateChat
            ? FirebaseFirestore.instance
                .collection(arguments.chatDocPathParticipants)
                .snapshots()
            : null,
        builder: (context, stream) {
          final List participants = !isPrivateChat
              ? stream?.data?.docs != null
                  ? stream?.data?.docs
                      ?.map((doc) =>
                          (doc?.data() ?? {'username': []})['username'])
                      ?.toList()
                  : []
              : [
                  arguments.chatDocPath.split('_')[1],
                  arguments.chatDocPath.split('_')[2]
                ];
          return FutureBuilder(
            future: getEmailFromParticipants(participants),
            builder: (_, emails) {
              if (!emails.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              return Scaffold(
                key: _scaffoldKey,
                appBar: AppBar(
                  leading: InkWell(
                    child: Icon(
                      Platform.isIOS
                          ? Icons.arrow_back_ios_new
                          : Icons.arrow_back,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  centerTitle: true,
                  title: Text(
                    arguments.roomTitle,
                  ),
                  backgroundColor: Color(kMainColor),
                  actions: [
                    StatefulBuilder(
                      builder: (BuildContext context, setState) {
                        return IconButton(
                          key: openDrawer,
                          icon: Icon(Icons.format_align_right),
                          onPressed: () {
                            _scaffoldKey.currentState.openEndDrawer();
                          },
                        );
                      },
                    )
                  ],
                ),
                endDrawer: Drawer(
                  child: Stack(
                    children: [
                      Transform(
                        transform: Matrix4.translationValues(0, 50, 0),
                        child: Container(
                          height: double.maxFinite,
                          child: ListView.builder(
                            itemCount:
                                participants == null ? 0 : participants.length,
                            itemBuilder: (context, i) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.0,
                                ),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      profileImage(
                                        participants[i],
                                        50.0,
                                      ),
                                      SizedBox(
                                        width: 10.0,
                                      ),
                                      Text(
                                        participants[i],
                                        style: TextStyle(
                                          color: participants[i] ==
                                                  userProvider.currentUser
                                              ? Colors.red
                                              : Colors.black,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    showBottomModal(
                                      context,
                                      participants[i],
                                      isPrivateChat,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height / 10 * 1.2,
                        child: DrawerHeader(
                          child: Transform(
                            transform: Matrix4.translationValues(0, -10, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Builder(
                                      builder: (context) => InkWell(
                                        onTap: () {
                                          Scaffold.of(context).openDrawer();
                                        },
                                        child: Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10.0,
                                    ),
                                    Text(
                                      '참여자',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.0,
                                      ),
                                    ),
                                  ],
                                ),
                                // await exitRoom(arguments.chatDocPathParticipants, arguments.store);
                              ],
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: Color(kMainColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                body: Column(
                  children: [
                    _MessagesStream(
                        showModal: showModal,
                        context: context,
                        onTapProfile: (sender) {
                          showBottomModal(context, sender, false);
                        }),
                    Expanded(
                      flex: showModal ? 2 : 1,
                      child: Material(
                        elevation: 10.0,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 10.0,
                            right: 10.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: InkWell(
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(kMainColor),
                                        borderRadius: BorderRadius.circular(
                                          30.0,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      showModal = !showModal;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 10,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 3.0,
                                    horizontal: 10.0,
                                  ),
                                  child: TextField(
                                    controller: textEditingController,
                                    decoration: kMessageTextFieldDecoration,
                                    onChanged: (value) {
                                      messageText = value;
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RawMaterialButton(
                                  onPressed: () async {
                                    DateTime now = DateTime.now();
                                    if (messageText != null) {
                                      textEditingController.clear();
                                      for (var i = 0;
                                          i < participants.length;
                                          ++i) {
                                        if (participants[i] !=
                                            userProvider.currentUser) {
                                          await notify(
                                            userProvider.currentUser,
                                            participants[i],
                                            'chat',
                                            DateTime.now(),
                                            !isPrivateChat
                                                ? "${int.tryParse(arguments.chatDocPath.split('chat')[2]) ?? 1}번째 단톡방: $messageText"
                                                : "${userProvider.currentUser}님이 개인챗으로 $messageText라고 남겼습니다.",
                                            path: arguments.chatDocPath,
                                            isPrivateChat: isPrivateChat,
                                          );
                                        }
                                      }
                                      await arguments.store
                                          .collection(arguments.chatDocPath)
                                          .add(
                                        {
                                          'content': messageText,
                                          'sender': userProvider.currentUser,
                                          'date': Timestamp.fromDate(now),
                                          'type': 'chat',
                                        },
                                      );
                                    }
                                  },
                                  child: Icon(
                                    Icons.arrow_back,
                                    size: 35.0,
                                    color: Color(kMainColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: showModal,
                      child: Expanded(
                        flex: 7,
                        child: CustomScrollView(
                          physics: NeverScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 10.0,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 1.0,
                                  mainAxisSpacing: 10.0,
                                  crossAxisSpacing: 10.0,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    switch (index) {
                                      case 0:
                                        return Center(
                                          child: StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection(
                                                      arguments.chatDocPath)
                                                  .where('type',
                                                      isEqualTo: 'image')
                                                  .snapshots(),
                                              builder: (context, chats) {
                                                return InkWell(
                                                  key: imageButton,
                                                  child: CircleAvatar(
                                                    backgroundColor: Colors.red,
                                                    radius: 30.0,
                                                    child: Icon(
                                                      Icons.image,
                                                    ),
                                                  ),
                                                  onTap: () async {
                                                    try {
                                                      File _image =
                                                          await pickImage();
                                                      if (_image != null) {
                                                        final imagePath =
                                                            'uploads/${userProvider.currentGarden}/groupchat${arguments.chatDocPath}/${getRandomString()}.png';
                                                        uploadImageToFirebase(
                                                          imagePath,
                                                          _image,
                                                        );
                                                        await arguments.store
                                                            .collection(arguments
                                                                .chatDocPath)
                                                            .add(
                                                          {
                                                            'sender':
                                                                userProvider
                                                                    .currentUser,
                                                            'date': Timestamp
                                                                .fromDate(
                                                                    DateTime
                                                                        .now()),
                                                            'type': 'image',
                                                            'imagePath':
                                                                imagePath,
                                                          },
                                                        );
                                                        FirebaseVisionImage
                                                            visionImage =
                                                            FirebaseVisionImage
                                                                .fromFilePath(
                                                                    _image
                                                                        .path);

                                                        final ImageLabeler
                                                            labelDetector =
                                                            FirebaseVision
                                                                .instance
                                                                .imageLabeler();
                                                        final List<ImageLabel>
                                                            labels =
                                                            await labelDetector
                                                                .processImage(
                                                                    visionImage);
                                                        var i = 0;
                                                        for (;
                                                            i < labels.length &&
                                                                !((labels[i]
                                                                            .text
                                                                            .contains(
                                                                                'Forest') ||
                                                                        labels[i]
                                                                            .text
                                                                            .contains(
                                                                                'Tree') ||
                                                                        labels[i]
                                                                            .text
                                                                            .contains(
                                                                                'Plant') ||
                                                                        labels[i]
                                                                            .text
                                                                            .contains(
                                                                                'Flower') ||
                                                                        labels[i]
                                                                            .text
                                                                            .contains(
                                                                                'Fern') ||
                                                                        labels[i]
                                                                            .text
                                                                            .contains(
                                                                                'Wood') ||
                                                                        labels[i]
                                                                            .text
                                                                            .contains(
                                                                                'Shrub')) &&
                                                                    labels[i]
                                                                            .confidence >
                                                                        0.5);
                                                            ++i) {}
                                                        if (i < labels.length) {
                                                          await dicProvider
                                                              .findTree(
                                                                  _image.path);
                                                          String treeNameText =
                                                              dicProvider
                                                                  .treeNames
                                                                  .map((name) =>
                                                                      "- $name")
                                                                  .join("\n");
                                                          await arguments.store
                                                              .collection(arguments
                                                                  .chatDocPath)
                                                              .add(
                                                            {
                                                              'content':
                                                                  treeNameText,
                                                              'sender':
                                                                  userProvider
                                                                      .currentUser,
                                                              'date': Timestamp
                                                                  .fromDate(
                                                                      DateTime
                                                                          .now()),
                                                              'type': 'chat',
                                                            },
                                                          );
                                                        } else {
                                                          print('not a plant');
                                                        }
                                                      }
                                                    } on PlatformException catch (err) {
                                                      print(err);
                                                    } catch (err) {
                                                      print(err);
                                                    }
                                                  },
                                                );
                                              }),
                                        );
                                        break;
                                      case 1:
                                        return Center(
                                          child: StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection(
                                                    arguments.chatDocPath)
                                                .where('type',
                                                    isEqualTo: 'image')
                                                .snapshots(),
                                            builder: (context, chats) {
                                              return InkWell(
                                                key: saveButton,
                                                child: CircleAvatar(
                                                  backgroundColor:
                                                      Color(kMainColor),
                                                  radius: 30.0,
                                                  child: Icon(
                                                    Icons.save,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onTap: () async {
                                                  try {
                                                    final saveFile = File(
                                                        '${(await getApplicationDocumentsDirectory()).path}/save.es3');
                                                    final path =
                                                        'uploads/save/${userProvider.currentUser}/save.es3';
                                                    if (saveFile.existsSync()) {
                                                      uploadARSaveFileToFirebase(
                                                              saveFile, path)
                                                          .then(
                                                        (_) async {
                                                          print('업로드 완료');
                                                          await arguments.store
                                                              .collection(arguments
                                                                  .chatDocPath)
                                                              .add(
                                                            {
                                                              'sender':
                                                                  userProvider
                                                                      .currentUser,
                                                              'date': Timestamp
                                                                  .fromDate(
                                                                      DateTime
                                                                          .now()),
                                                              'type':
                                                                  'savefile',
                                                              'filePath': path,
                                                            },
                                                          );
                                                        },
                                                      );
                                                    } else {
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return Platform
                                                                  .isAndroid
                                                              ? AlertDialog(
                                                                  title: Text(
                                                                      'Alert!'),
                                                                  content: Text(
                                                                      "저장된 AR가든 세이브파일이 없습니다."),
                                                                  actions: [
                                                                    TextButton(
                                                                      child: Text(
                                                                          'OK'),
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context,
                                                                            "OK");
                                                                      },
                                                                    ),
                                                                  ],
                                                                )
                                                              : CupertinoAlertDialog(
                                                                  title: Text(
                                                                      'Alert!'),
                                                                  content: Text(
                                                                      "저장된 AR가든 세이브파일이 없습니다."),
                                                                  actions: [
                                                                    TextButton(
                                                                      child: Text(
                                                                          'OK'),
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context,
                                                                            "OK");
                                                                      },
                                                                    ),
                                                                  ],
                                                                );
                                                        },
                                                      );
                                                    }
                                                  } on PlatformException catch (err) {
                                                    print(err);
                                                  } catch (err) {
                                                    print(err);
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        );
                                        break;
                                      case 2:
                                        return Center(
                                          child: InkWell(
                                            child: Image.asset(
                                              'assets/question-mark.png',
                                              width: 60.0,
                                            ),
                                            onTap: () {
                                              TutorialCoachMark(
                                                context,
                                                targets: buttonTargets,
                                                colorShadow: Color(kMainColor),
                                              )..show();
                                            },
                                          ),
                                        );
                                        break;
                                      default:
                                        break;
                                    }
                                    return Container();
                                  },
                                  childCount: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MessagesStream extends StatelessWidget {
  bool showModal = false;
  final BuildContext context;
  final Function onTapProfile;

  _MessagesStream({
    this.showModal,
    this.context,
    this.onTapProfile,
  });

  Future<List<dynamic>> getImageBubbles(
      List<QueryDocumentSnapshot> imgDocs, chatPath) async {
    try {
      if (imgDocs != null && imgDocs.length > 0) {
        List<_ImageBubble> imageBubbles = [];
        for (var i = 0; i < imgDocs.length; ++i) {
          var img = imgDocs[i];
          String messageSender = img['sender'];
          final DateTime time = img['date'].toDate();
          var imgUrl;
          try {
            imgUrl = await FirebaseStorage?.instance
                    ?.ref()
                    ?.child(img['imagePath'])
                    ?.getDownloadURL() ??
                'https://via.placeholder.com/100';
          } catch (e) {
            imgUrl = 'https://korjarvis.asuscomm.com:9098/spinner.gif';
          }
          final onDismissed = (_) async {
            await FirebaseFirestore.instance
                .collection(chatPath)
                .doc(imgDocs[i].id)
                .delete();
            final fileRef =
                FirebaseStorage?.instance?.ref()?.child(img['imagePath']);
            if (fileRef != null) {
              await fileRef?.delete();
            }
          };
          final imageBubble = _ImageBubble(
            key: ValueKey(imgDocs[i]),
            context: context,
            onTapProfile: () {
              onTapProfile(messageSender);
            },
            onDismissed: onDismissed,
            sender: messageSender,
            // chat
            imgUrl: imgUrl,
            time: time.toString(),
            isMe: userProvider.currentUser == messageSender,
          );
          imageBubbles.add(imageBubble);
        }
        return imageBubbles;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getSavefileBubbles(
      List<QueryDocumentSnapshot> savefiles, chatPath) async {
    try {
      if (savefiles != null && savefiles.length > 0) {
        List<_SavefileBubble> savefileBubbles = [];
        for (var i = 0; i < savefiles.length; ++i) {
          var save = savefiles[i];
          String messageSender = save['sender'];
          final DateTime time = save['date'].toDate();
          var saveFileUrl;
          try {
            saveFileUrl = await FirebaseStorage?.instance
                    ?.ref()
                    ?.child(save['filePath'])
                    ?.getDownloadURL() ??
                'https://korjarvis.asuscomm.com:9098/save.es3';
          } catch (e) {
            saveFileUrl = 'https://korjarvis.asuscomm.com:9098/save.es3';
          }
          final onDismissed = (_) async {
            await FirebaseFirestore.instance
                .collection(chatPath)
                .doc(savefiles[i].id)
                .delete();
            final fileRef =
                FirebaseStorage?.instance?.ref()?.child(save['filePath']);
            if (fileRef != null) {
              await fileRef?.delete();
            }
          };
          final savefileBubble = _SavefileBubble(
            key: ValueKey(savefiles[i]),
            context: context,
            onTapProfile: () {
              onTapProfile(messageSender);
            },
            onDismissed: onDismissed,
            sender: messageSender,
            // chat
            saveFileUrl: saveFileUrl,
            time: time.toString(),
            isMe: userProvider.currentUser == messageSender,
          );
          savefileBubbles.add(savefileBubble);
        }
        return savefileBubbles;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChatRoomArgs args =
        ModalRoute.of(context).settings.arguments as ChatRoomArgs;
    final FirebaseFirestore _fireStore = args.store;
    final String chatPath = args.chatDocPath;

    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore
          .collection(chatPath)
          .where('type', isEqualTo: 'savefile')
          .snapshots(),
      builder: (context, savefiles) {
        return FutureBuilder<List<dynamic>>(
          future: getSavefileBubbles(savefiles?.data?.docs ?? [], chatPath),
          builder: (context, saveBubbles) {
            if (!saveBubbles.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            return StreamBuilder<QuerySnapshot>(
              stream: _fireStore
                  .collection(chatPath)
                  .where('type', isEqualTo: 'image')
                  .snapshots(),
              builder: (context, images) {
                if (!images.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                return FutureBuilder(
                  future: getImageBubbles(images?.data?.docs ?? [], chatPath),
                  builder: (context, imgBubbles) {
                    if (!imgBubbles.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return StreamBuilder<QuerySnapshot>(
                      stream: _fireStore
                          .collection(chatPath)
                          .where('type', isEqualTo: 'chat')
                          .snapshots(),
                      builder: (context, chats) {
                        if (!chats.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              backgroundColor: Colors.lightBlueAccent,
                            ),
                          );
                        }

                        List<dynamic> messageBubbles = [];
                        // get messages
                        for (var i = 0; i < chats.data.docs.length; ++i) {
                          final message = chats.data.docs[i];
                          final String messageText =
                              message['content']; // messages from FirebaseData
                          String messageSender = message['sender'] != null
                              ? message['sender']
                              : 'sender';
                          final DateTime time = message['date'].toDate();
                          final onDismissed = (_) async {
                            await _fireStore
                                .collection(chatPath)
                                .doc(chats.data.docs[i].id)
                                .delete();
                          };
                          final messageBubble = _MessageBubble(
                            key: ValueKey(chats.data.docs[i]),
                            onDismissed: onDismissed,
                            context: context,
                            onTapProfile: () {
                              onTapProfile(messageSender);
                            },
                            sender: messageSender,
                            text: messageText,
                            time: time.toString(),
                            isMe: userProvider.currentUser == messageSender,
                          );
                          messageBubbles.add(messageBubble);
                        }

                        // get images
                        for (_ImageBubble imgBubble in imgBubbles.data) {
                          messageBubbles.add(imgBubble);
                        }

                        // get save files
                        for (_SavefileBubble savefileBubble
                            in saveBubbles.data) {
                          messageBubbles.add(savefileBubble);
                        }

                        messageBubbles.sort((a, b) {
                          var aTime = a.time;
                          var bTime = b.time;
                          return -aTime.compareTo(bTime);
                        });

                        List<Widget> ret = [];
                        for (var i = 0; i < messageBubbles.length; ++i) {
                          ret.add(messageBubbles[i]);
                          if (i + 1 != messageBubbles.length &&
                              messageBubbles[i].time.toString().split(" ")[0] !=
                                  messageBubbles[i + 1]
                                      .time
                                      .toString()
                                      .split((" "))[0]) {
                            ret.add(
                              _CustomDivider(
                                time: DateTime.parse(
                                  messageBubbles[i].time,
                                ),
                              ),
                            );
                          }
                          if (i == messageBubbles.length - 1) {
                            ret.add(
                              _CustomDivider(
                                time: DateTime.parse(
                                  messageBubbles[i].time,
                                ),
                              ),
                            );
                          }
                        }

                        return Expanded(
                          flex: showModal ? 12 : 10,
                          child: ListView(
                            reverse: true,
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 20.0,
                            ),
                            children: ret,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CustomDivider extends StatelessWidget {
  _CustomDivider({@required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 10.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            child: Center(
              child: Text(
                time.toString().split(" ")[0].split("-")[0] +
                    "년 " +
                    time.toString().split(" ")[0].split("-")[1] +
                    "월 " +
                    time.toString().split(" ")[0].split("-")[2] +
                    "일",
                style: TextStyle(
                  fontSize: 12.0,
                ),
              ),
            ),
            decoration: BoxDecoration(color: Colors.grey[200]),
            width: MediaQuery.of(context).size.width / 10 * 8,
            height: 20.0,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  _MessageBubble({
    this.key,
    this.onDismissed,
    this.context,
    this.onTapProfile,
    @required this.sender,
    @required this.text,
    @required this.time,
    @required this.isMe,
  });

  final ValueKey key;
  final BuildContext context;
  final Function onTapProfile;
  final Function onDismissed;
  final String sender;
  final String text;
  final String time;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    double c_width = MediaQuery.of(context).size.width * 0.4;

    if (!isMe) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: 5.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              child: profileImage(
                sender,
                40.0,
              ),
              onTap: onTapProfile,
            ),
            SizedBox(
              width: 10.0,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Material(
                      borderRadius: kBorderRadiusIfIsNotMe,
                      color: Colors.black54,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 5.0,
                          horizontal: 15.0,
                        ),
                        child: Container(
                          width: text.length < 11 ? null : c_width,
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Text(
                      time.split(" ")[1].split(":")[0] +
                          ":" +
                          time.split(" ")[1].split(":")[1],
                      style: TextStyle(
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Dismissible(
        key: key,
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: MediaQuery.of(context).size.width * 0.05,
              ),
              child: Text(
                "삭제",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        onDismissed: onDismissed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 5.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    sender,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time.split(" ")[1].split(":")[0] +
                            ":" +
                            time.split(" ")[1].split(":")[1],
                        style: TextStyle(
                          fontSize: 12.0,
                        ),
                      ),
                      SizedBox(
                        width: 10.0,
                      ),
                      Material(
                        borderRadius: kBorderRadiusIfIsMe,
                        color: Color(kMainColor),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 15.0,
                          ),
                          child: Container(
                            width: text.length < 11 ? null : c_width,
                            child: Text(
                              text,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                                fontSize: 15.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 10.0,
              ),
              InkWell(
                child: profileImage(
                  sender,
                  40.0,
                ),
                onTap: onTapProfile,
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _ImageBubble extends StatelessWidget {
  _ImageBubble({
    this.key,
    this.context,
    this.onTapProfile,
    this.onDismissed,
    @required this.sender,
    @required this.imgUrl,
    @required this.time,
    @required this.isMe,
  });

  final ValueKey key;
  final BuildContext context;
  final Function onTapProfile;
  final Function onDismissed;
  final String sender;
  final String imgUrl;
  final String time;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    if (!isMe) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: 5.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              child: profileImage(
                sender,
                40.0,
              ),
              onTap: onTapProfile,
            ),
            SizedBox(
              width: 10.0,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Material(
                      borderRadius: kBorderRadiusIfIsNotMe,
                      color: Colors.black54,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 5.0,
                          horizontal: 15.0,
                        ),
                        child: InkWell(
                          child: Image.network(
                            imgUrl,
                            width: 100.0,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              ViewImage.id,
                              arguments: ViewImageArgs(
                                url: imgUrl,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Text(
                      time.split(" ")[1].split(":")[0] +
                          ":" +
                          time.split(" ")[1].split(":")[1],
                      style: TextStyle(
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Dismissible(
        key: key,
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: MediaQuery.of(context).size.width * 0.05,
              ),
              child: Text(
                "삭제",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        onDismissed: onDismissed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 5.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    sender,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time.split(" ")[1].split(":")[0] +
                            ":" +
                            time.split(" ")[1].split(":")[1],
                        style: TextStyle(
                          fontSize: 12.0,
                        ),
                      ),
                      SizedBox(
                        width: 10.0,
                      ),
                      Material(
                        borderRadius: kBorderRadiusIfIsMe,
                        color: Color(kMainColor),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 15.0,
                          ),
                          child: InkWell(
                              child: Image.network(
                                imgUrl,
                                width: 100.0,
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  ViewImage.id,
                                  arguments: ViewImageArgs(
                                    url: imgUrl,
                                  ),
                                );
                              }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 10.0,
              ),
              InkWell(
                child: profileImage(
                  sender,
                  40.0,
                ),
                onTap: onTapProfile,
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _SavefileBubble extends StatelessWidget {
  _SavefileBubble({
    this.key,
    this.context,
    this.onTapProfile,
    this.onDismissed,
    @required this.sender,
    @required this.saveFileUrl,
    @required this.time,
    @required this.isMe,
  });

  final ValueKey key;
  final BuildContext context;
  final Function onTapProfile;
  final Function onDismissed;
  final String sender;
  final String saveFileUrl;
  final String time;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    if (!isMe) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: 5.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              child: profileImage(
                sender,
                40.0,
              ),
              onTap: onTapProfile,
            ),
            SizedBox(
              width: 10.0,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Material(
                      borderRadius: kBorderRadiusIfIsNotMe,
                      color: Colors.black54,
                      child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 15.0,
                          ),
                          child: InkWell(
                              child: Icon(
                                Icons.save,
                                size: 30.0,
                                color: Colors.white,
                              ),
                              onTap: () async {
                                await FlutterDownloader.enqueue(
                                  url: saveFileUrl,
                                  savedDir:
                                      '${(await getApplicationDocumentsDirectory()).path}/',
                                  showNotification: true,
                                  openFileFromNotification: true,
                                );
                              })),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Text(
                      time.split(" ")[1].split(":")[0] +
                          ":" +
                          time.split(" ")[1].split(":")[1],
                      style: TextStyle(
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Dismissible(
        key: key,
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: MediaQuery.of(context).size.width * 0.05,
              ),
              child: Text(
                "삭제",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        onDismissed: onDismissed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 5.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    sender,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time.split(" ")[1].split(":")[0] +
                            ":" +
                            time.split(" ")[1].split(":")[1],
                        style: TextStyle(
                          fontSize: 12.0,
                        ),
                      ),
                      SizedBox(
                        width: 10.0,
                      ),
                      Material(
                        borderRadius: kBorderRadiusIfIsMe,
                        color: Color(kMainColor),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 15.0,
                          ),
                          child: Container(
                            child: Icon(
                              Icons.save,
                              size: 30.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 10.0,
              ),
              InkWell(
                child: profileImage(
                  sender,
                  40.0,
                ),
                onTap: onTapProfile,
              ),
            ],
          ),
        ),
      );
    }
  }
}
