import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:namu_diary/main.dart';
import 'package:namu_diary/constants.dart';
import 'package:namu_diary/arguments.dart';
import 'package:namu_diary/screens/MainPage.dart';
import 'package:namu_diary/screens/ViewImage.dart';
import 'package:namu_diary/screens/ViewDiary.dart';
import 'package:namu_diary/screens/ViewList.dart';
import 'package:namu_diary/screens/Chatroom.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _store = FirebaseFirestore.instance;
final _storage = FirebaseStorage.instance;

String numberPad(String n) {
  return n.length >= 3 ? n : '${List.filled(3 - n.length, '0').join('')}$n';
}

String getRandomString() {
  const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();
  return String.fromCharCodes(Iterable.generate(
      15, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
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

Future uploadImageToFirebase(String docName, File imageFile) async {
  final fileRef = FirebaseStorage.instance.ref().child(docName);
  if (fileRef != null) {
    fileRef.delete();
  }
  await fileRef.putFile(imageFile);
}

notify(String alarmSender, String targetUser, String type, DateTime _timestamp,
    String content,
    {String path, String index, bool isPrivateChat}) async {
  final userEmail = (await _store
          .collection('/userList')
          .where('username', isEqualTo: targetUser)
          .limit(1)
          .get())
      .docs[0]
      .data()['email'];
  final DateTime timestamp =
      (await _store.collection('/userInfo_$userEmail').limit(1).get())
          .docs[0]
          .data()['lastLogin']
          .toDate();
  final len = (await _store.collection('/alarm_$targetUser').get()).docs.length;
  if (timestamp.isBefore(_timestamp)) {
    Map<String, dynamic> notificationContent;
    // 로그인 시간이 알람시간보다 이르다면 이미 로그아웃 했거나 로그인중으로 간주하고 알림을 준다
    if (type == 'like' || type == 'following') {
      notificationContent = {
        // 알림기능
        // 내 피드나 다이어리에 달린 댓글 / 채팅 / 좋아요 / 새로 올라온 피드 / 팔로잉의 새 다이어리 / 팔로워 알림
        'alarmNo': numberPad(len.toString()),
        'alarmSender': alarmSender,
        'targetUser': targetUser,
        'type': type,
        'time': Timestamp.fromDate(_timestamp),
        'content': content,
      };
    } else if (type == 'chat') {
      notificationContent = {
        // 알림기능
        // 내 피드나 다이어리에 달린 댓글 / 채팅 / 좋아요 / 새로 올라온 피드 / 팔로잉의 새 다이어리 / 팔로워 알림
        'alarmNo': numberPad(len.toString()),
        'alarmSender': alarmSender,
        'targetUser': targetUser,
        'type': type,
        'time': Timestamp.fromDate(_timestamp),
        'content': content,
        'path': path,
        'isPrivateChat': isPrivateChat,
      };
    } else {
      notificationContent = {
        // 알림기능
        // 내 피드나 다이어리에 달린 댓글 / 채팅 / 좋아요 / 새로 올라온 피드 / 팔로잉의 새 다이어리 / 팔로워 알림
        'alarmNo': numberPad(len.toString()),
        'alarmSender': alarmSender,
        'targetUser': targetUser,
        'type': type,
        'time': Timestamp.fromDate(_timestamp),
        'content': content,
        'path': path,
        'index': index,
      };
    }
    await _store.collection('/alarm_$targetUser').add(notificationContent);
  }
}

showAlert(context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Platform.isAndroid
          ? AlertDialog(
              title: Text('Alert!'),
              content: Text("지원 예정입니다."),
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
              content: Text("지원 예정입니다."),
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

showBottomModal(BuildContext context, String user, bool isPrivateChat) async {
  String email = await userProvider.getEmail(user);

  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('/diary_$user').snapshots(),
        builder: (context, diaries) {
          if (!diaries.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width - 30,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 10.0,
                        ),
                        FutureBuilder(
                          future: _storage
                              .ref('uploads/userProfile/$user')
                              .getDownloadURL(),
                          builder: (context, profileUrl) {
                            if (!profileUrl.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            return InkWell(
                              child: Container(
                                width: 80.0,
                                height: 80.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(profileUrl.data),
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  ViewImage.id,
                                  arguments: ViewImageArgs(
                                    url: profileUrl.data,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  user,
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(
                                  height: 10.0,
                                ),
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('/userInfo_$email')
                                      .limit(1)
                                      .snapshots(),
                                  builder: (_, userInfo) {
                                    if (!userInfo.hasData)
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    final length =
                                        diaries?.data?.docs?.length ?? 0;

                                    final follower = List.from(userInfo
                                        .data.docs[0]
                                        .data()['follower']);
                                    final following = List.from(userInfo
                                        .data.docs[0]
                                        .data()['following']);
                                    return Container(
                                      width: MediaQuery.of(context).size.width /
                                          10 *
                                          6,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "일지 $length 개",
                                            style: kTextSubStyle,
                                          ),
                                          InkWell(
                                              child: Text(
                                                "팔로워 ${follower.length}명",
                                                style: kTextSubStyle,
                                              ),
                                              onTap: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  ViewList.id,
                                                  arguments: ViewListArgs(
                                                    title: "팔로워",
                                                    list: follower,
                                                  ),
                                                );
                                              }),
                                          InkWell(
                                              child: Text(
                                                "팔로잉 ${following.length}명",
                                                style: kTextSubStyle,
                                              ),
                                              onTap: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  ViewList.id,
                                                  arguments: ViewListArgs(
                                                    title: "팔로잉",
                                                    list: following,
                                                  ),
                                                );
                                              }),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            isPrivateChat || user == userProvider.currentUser
                                ? Container()
                                : SizedBox(
                                    width: MediaQuery.of(context).size.width /
                                        10 *
                                        4.0,
                                    child: Material(
                                      borderRadius: BorderRadius.circular(
                                        5.0,
                                      ),
                                      color: Color(kMainColor),
                                      child: MaterialButton(
                                        child: Text(
                                          "개인채팅",
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        onPressed: () async {
                                          final _fireStore =
                                              FirebaseFirestore.instance;
                                          var docpath =
                                              '/privatechat_${userProvider.currentUser}_$user';
                                          final snap = await _fireStore
                                              .collection(docpath)
                                              .get();
                                          if (snap.docs.length == 0) {
                                            docpath =
                                                '/privatechat_${user}_${userProvider.currentUser}';
                                          }
                                          Navigator.pushReplacementNamed(
                                            context,
                                            ChatRoom.id,
                                            arguments: ChatRoomArgs(
                                              chatDocPath: docpath,
                                              roomTitle: '개인채팅',
                                              store: _fireStore,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                            isPrivateChat || user == userProvider.currentUser
                                ? Container()
                                : SizedBox(
                                    width: MediaQuery.of(context).size.width /
                                        10 *
                                        0.5,
                                  ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width /
                                  10 *
                                  (isPrivateChat ||
                                          user == userProvider.currentUser
                                      ? 9.0
                                      : 4.0),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('/userInfo_$email')
                                    .limit(1)
                                    .snapshots(),
                                builder: (context, userInfo) {
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('/alarm_$user')
                                        .where('alarmSender',
                                            isEqualTo: userProvider.currentUser)
                                        .where('targetUser', isEqualTo: user)
                                        .where('type', isEqualTo: 'following')
                                        .where('content',
                                            isEqualTo:
                                                '${userProvider.currentUser}님이 팔로우했습니다!')
                                        .limit(1)
                                        .snapshots(),
                                    builder: (context, followDoc) {
                                      final followed = List.from((userInfo
                                                      ?.data?.docs
                                                      ?.elementAt(0)
                                                      ?.data() ??
                                                  {'follower': []})['follower'])
                                              ?.where((el) =>
                                                  el ==
                                                  userProvider.currentUser)
                                              ?.toList()
                                              ?.length ==
                                          1;
                                      return Material(
                                        borderRadius: BorderRadius.circular(
                                          5.0,
                                        ),
                                        color: Color(kMainColor),
                                        child: MaterialButton(
                                          child: Text(
                                            user == userProvider.currentUser
                                                ? "내 프로필 보기"
                                                : followed ?? true
                                                    ? '언팔로우'
                                                    : '팔로우',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          onPressed: () async {
                                            if (user ==
                                                userProvider.currentUser) {
                                              navigationProvider
                                                  .setMainPageIdx(4);
                                              Navigator.popAndPushNamed(
                                                  context, MainPage.id);
                                            } else {
                                              // follow
                                              if (!followed &&
                                                  followDoc.data.docs.length ==
                                                      0) {
                                                await notify(
                                                  userProvider.currentUser,
                                                  user,
                                                  'following',
                                                  DateTime.now(),
                                                  '${userProvider.currentUser}님이 팔로우했습니다!',
                                                );
                                              }
                                              await userProvider.follow(user);
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.0,
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: 20.0,
                    ),
                    height: MediaQuery.of(context).size.height / 10 * 1.5,
                    child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) {
                        return SizedBox(
                          width: 10.0,
                        );
                      },
                      scrollDirection: Axis.horizontal,
                      itemCount: diaries?.data?.docs?.length ?? 0,
                      itemBuilder: (context, index) {
                        final diary = diaries.data.docs
                            .where((el) =>
                                el.data()['diaryNo'] ==
                                numberPad(index.toString()))
                            .elementAt(0)
                            .data();
                        return AspectRatio(
                          aspectRatio: 1,
                          child: FutureBuilder(
                            future: FirebaseStorage.instance
                                .ref(diary['imagePath'])
                                .getDownloadURL(),
                            builder: (context, url) {
                              if (!url.hasData) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                              return InkWell(
                                child: Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(url.data),
                                      fit: BoxFit.fitHeight,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    ViewDiary.id,
                                    arguments: ViewDiaryArgs(
                                      url: url.data,
                                      diaryPath: '/diary_$user',
                                      imagePath: diary['imagePath'],
                                      diaryNo: diary['diaryNo'],
                                      user: user,
                                      content: diary['content'],
                                      date: diary['date'].toDate(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
