import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:namu_diary/arguments.dart';
import 'package:namu_diary/main.dart';
import 'package:namu_diary/screens/Chatroom.dart';
import 'package:namu_diary/screens/ViewDiary.dart';
import 'package:namu_diary/screens/ViewFeed.dart';
import 'package:namu_diary/utils.dart';
import 'package:namu_diary/materials/AlarmCard.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

final _store = FirebaseFirestore.instance;
final _storage = FirebaseStorage.instance;

class Alarm extends StatefulWidget {
  final Function callback;

  Alarm({this.callback});

  @override
  _AlarmState createState() => _AlarmState();
}

class _AlarmState extends State<Alarm> {
  final kTextSubStyle = TextStyle(
    color: Colors.black54,
    fontSize: 12.0,
  );

  final GlobalKey notificationKey = GlobalKey();

  deleteNotifcation(alarmNo) async {
    final path = '/alarm_${userProvider.currentUser}';
    final docRef = (await _store.collection(path).get()).docs;
    final deleteId =
        docRef.where((el) => el.data()['alarmNo'] == alarmNo).elementAt(0).id;
    await _store.collection(path).doc(deleteId).delete();
    for (var i = int.tryParse(alarmNo) ?? 0; i < docRef.length - 1; ++i) {
      final id = docRef
          .where((el) => el.data()['alarmNo'] == numberPad((i + 1).toString()))
          .elementAt(0)
          .id;
      // change alarmNo
      await _store.collection(path).doc(id).update({
        'alarmNo': numberPad(i.toString()),
      });
    }
  }

  @override
  void initState() {
    widget.callback(
      [
        TargetFocus(
          identify: "notification",
          keyTarget: notificationKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "알림",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "댓글 알림, 팔로우 알림, 채팅방 알림 등을 확인할 수 있습니다.",
                        style: TextStyle(
                          color: Colors.white,
                        ),
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
    return Stack(
      children: [
        StreamBuilder(
          stream: _store
              .collection('/alarm_${userProvider.currentUser}')
              .snapshots(),
          builder: (context, alarms) {
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  alignment: Alignment.bottomCenter,
                  image: Image.asset(
                    'assets/background.png',
                  ).image,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _store
                        .collection('/alarm_${userProvider.currentUser}')
                        .snapshots(),
                    builder: (context, alarms) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ListView.builder(
                          primary: false,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final len = alarms?.data?.docs?.length;
                            return StreamBuilder<QuerySnapshot>(
                              stream: _store
                                  .collection(
                                      '/alarm_${userProvider.currentUser}')
                                  .where('alarmNo',
                                      isEqualTo: numberPad(
                                          ((len - 1 ?? 0) - index).toString()))
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, alarm) {
                                dynamic field(String fieldName) {
                                  return alarm?.data?.docs?.length != 0
                                      ? (alarm?.data?.docs
                                              ?.elementAt(0)
                                              ?.data() ??
                                          {fieldName: ''})[fieldName]
                                      : '';
                                }

                                switch (field('type')) {
                                  // like, reply, chat, feed, follower_newdiary, following
                                  case 'like':
                                    return InkWell(
                                      child: AlarmCard(
                                        sender: field('alarmSender'),
                                        firstText: "",
                                        secondText: field('alarmSender'),
                                        finalText:
                                            "님이 당신의 ${field('content')}에 좋아요를 눌렀습니다.",
                                        time: field('time').toDate(),
                                      ),
                                      onTap: () async {
                                        await showBottomModal(context,
                                            field('alarmSender'), false);
                                        deleteNotifcation(numberPad(
                                            ((len - 1 ?? 0) - index)
                                                .toString()));
                                      },
                                    );
                                  case 'reply':
                                    // 피드에 남긴 경우
                                    if (field('path')
                                            .substring(1)
                                            .split('_')[0] ==
                                        'diary') {
                                      return StreamBuilder<QuerySnapshot>(
                                          stream: _store
                                              .collection(field('path'))
                                              .where('diaryNo',
                                                  isEqualTo: field('index'))
                                              .snapshots(),
                                          builder: (context, feed) {
                                            if (!feed.hasData) {
                                              return Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            }
                                            final _feed = feed?.data?.docs
                                                    ?.elementAt(0)
                                                    ?.data() ??
                                                {};
                                            return FutureBuilder(
                                                future: _storage
                                                    .ref(feed.data.docs[0]
                                                        .data()['imagePath'])
                                                    .getDownloadURL(),
                                                builder: (context, url) {
                                                  if (!url.hasData) {
                                                    return Center(
                                                        child:
                                                            CircularProgressIndicator());
                                                  }
                                                  return InkWell(
                                                    child: AlarmCard(
                                                      sender:
                                                          field('alarmSender'),
                                                      firstText: "",
                                                      secondText:
                                                          field('alarmSender'),
                                                      finalText:
                                                          "님이 당신의 ${field('content')}",
                                                      time: field('time')
                                                          .toDate(),
                                                    ),
                                                    onTap: () {
                                                      Navigator.pushNamed(
                                                        context,
                                                        ViewDiary.id,
                                                        arguments:
                                                            ViewDiaryArgs(
                                                          url: url.data,
                                                          diaryPath:
                                                              field('path'),
                                                          imagePath: _feed[
                                                              'imagePath'],
                                                          diaryNo:
                                                              field('index'),
                                                          user: field('path').substring(1).split('_')[1],
                                                          content:
                                                              _feed['content'],
                                                          date: _feed['date']
                                                              .toDate(),
                                                        ),
                                                      );
                                                      deleteNotifcation(
                                                          numberPad(
                                                              ((len - 1 ?? 0) -
                                                                      index)
                                                                  .toString()));
                                                    },
                                                  );
                                                });
                                          });
                                    } else if (field('path')
                                            .substring(1)
                                            .split('_')[0] ==
                                        'feed') {
                                      return StreamBuilder<QuerySnapshot>(
                                          stream: _store
                                              .collection(field('path'))
                                              .where('feedNo',
                                                  isEqualTo: field('index'))
                                              .snapshots(),
                                          builder: (context, feed) {
                                            if (!feed.hasData) {
                                              return Center(
                                                  child:
                                                      CircularProgressIndicator());
                                            }
                                            final _feed = feed?.data?.docs
                                                    ?.elementAt(0)
                                                    ?.data() ??
                                                {};
                                            return FutureBuilder(
                                                future: _storage
                                                    .ref(feed.data.docs[0]
                                                        .data()['imagePath'])
                                                    .getDownloadURL(),
                                                builder: (context, url) {
                                                  if (!url.hasData) {
                                                    return Center(
                                                        child:
                                                            CircularProgressIndicator());
                                                  }
                                                  return InkWell(
                                                    child: AlarmCard(
                                                      sender:
                                                          field('alarmSender'),
                                                      firstText: "",
                                                      secondText:
                                                          field('alarmSender'),
                                                      finalText:
                                                          "님이 당신의 ${field('content')}",
                                                      time: field('time')
                                                          .toDate(),
                                                    ),
                                                    onTap: () {
                                                      Navigator.pushNamed(
                                                        context,
                                                        ViewFeed.id,
                                                        arguments: ViewFeedArgs(
                                                          url: url.data,
                                                          feedPath:
                                                              field('path'),
                                                          imagePath: _feed[
                                                              'imagePath'],
                                                          feedNo:
                                                              field('index'),
                                                          user: _feed['user'],
                                                          content:
                                                              _feed['content'],
                                                          date: _feed['date']
                                                              .toDate(),
                                                        ),
                                                      );
                                                      deleteNotifcation(
                                                          numberPad(
                                                              ((len - 1 ?? 0) -
                                                                      index)
                                                                  .toString()));
                                                    },
                                                  );
                                                });
                                          });
                                    }
                                    return Container();
                                  case 'chat':
                                    return StreamBuilder<QuerySnapshot>(
                                      stream: _store
                                          .collection(
                                              '/groupchat_${userProvider.currentGarden}_chatTitle')
                                          .snapshots(),
                                      builder: (context, titles) {
                                        if (!titles.hasData) {
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        return InkWell(
                                          onTap: () async {
                                            Future enterRoom(curChatDoc) async {
                                              final result = await _store
                                                  .collection(curChatDoc)
                                                  .where('username',
                                                      isEqualTo: userProvider
                                                          .currentUser)
                                                  .limit(1)
                                                  .get();
                                              if (result.docs.length == 0) {
                                                await _store
                                                    .collection(curChatDoc)
                                                    .add({
                                                  'username':
                                                      userProvider.currentUser,
                                                });
                                              }
                                            }

                                            final chatDocPath = field('path');
                                            final chatDocPathParticipants =
                                                '${field('path')}_participants';
                                            await enterRoom(
                                                chatDocPathParticipants);
                                            Navigator.pushNamed(
                                              context,
                                              ChatRoom.id,
                                              arguments: ChatRoomArgs(
                                                chatDocPath: chatDocPath,
                                                chatDocPathParticipants:
                                                    chatDocPathParticipants,
                                                roomTitle: '채팅방',
                                                store: _store,
                                              ),
                                            );
                                            deleteNotifcation(numberPad(
                                                ((len - 1 ?? 0) - index)
                                                    .toString()));
                                          },
                                          child: AlarmCard(
                                            sender: field('alarmSender'),
                                            firstText: "",
                                            secondText: field('alarmSender'),
                                            finalText: "의 ${field('content')}",
                                            time: field('time').toDate(),
                                          ),
                                        );
                                      },
                                    );
                                  case 'feed':
                                    return StreamBuilder<QuerySnapshot>(
                                        stream: _store
                                            .collection(field('path'))
                                            .where('feedNo',
                                                isEqualTo: field('index'))
                                            .snapshots(),
                                        builder: (context, feed) {
                                          if (!feed.hasData) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                          final _feed = feed?.data?.docs
                                                  ?.elementAt(0)
                                                  ?.data() ??
                                              {};
                                          return FutureBuilder(
                                              future: _storage
                                                  .ref(feed.data.docs[0]
                                                      .data()['imagePath'])
                                                  .getDownloadURL(),
                                              builder: (context, url) {
                                                if (!url.hasData) {
                                                  return Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                }
                                                return InkWell(
                                                  child: AlarmCard(
                                                    sender:
                                                        field('alarmSender'),
                                                    firstText: "",
                                                    secondText:
                                                        field('alarmSender'),
                                                    finalText: field('content'),
                                                    time:
                                                        field('time').toDate(),
                                                  ),
                                                  onTap: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      ViewFeed.id,
                                                      arguments: ViewFeedArgs(
                                                        url: url.data,
                                                        feedPath: field('path'),
                                                        imagePath:
                                                            _feed['imagePath'],
                                                        feedNo: field('index'),
                                                        user: _feed['user'],
                                                        content:
                                                            _feed['content'],
                                                        date: _feed['date']
                                                            .toDate(),
                                                      ),
                                                    );
                                                    deleteNotifcation(numberPad(
                                                        ((len - 1 ?? 0) - index)
                                                            .toString()));
                                                  },
                                                );
                                              });
                                        });
                                  case 'follower_newdiary':
                                    return StreamBuilder<QuerySnapshot>(
                                        stream: _store
                                            .collection(field('path'))
                                            .where('diaryNo',
                                                isEqualTo: field('index'))
                                            .snapshots(),
                                        builder: (context, diary) {
                                          if (!diary.hasData) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                          final _diary = diary?.data?.docs
                                                  ?.elementAt(0)
                                                  ?.data() ??
                                              {};
                                          return FutureBuilder(
                                              future: _storage
                                                  .ref(diary.data.docs[0]
                                                      .data()['imagePath'])
                                                  .getDownloadURL(),
                                              builder: (context, url) {
                                                if (!url.hasData) {
                                                  return Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                }
                                                return InkWell(
                                                  child: AlarmCard(
                                                    sender:
                                                        field('alarmSender'),
                                                    firstText: "",
                                                    secondText:
                                                        field('alarmSender'),
                                                    finalText: field('content'),
                                                    time:
                                                        field('time').toDate(),
                                                  ),
                                                  onTap: () {
                                                    print(_diary);
                                                    Navigator.pushNamed(
                                                      context,
                                                      ViewDiary.id,
                                                      arguments: ViewDiaryArgs(
                                                        url: url.data,
                                                        diaryPath:
                                                            field('path'),
                                                        imagePath:
                                                            _diary['imagePath'],
                                                        diaryNo: field('index'),
                                                        user: field('path').substring(1).split('_')[1],
                                                        content:
                                                            _diary['content'],
                                                        date: _diary['date']
                                                            .toDate(),
                                                      ),
                                                    );
                                                    deleteNotifcation(numberPad(
                                                        ((len - 1 ?? 0) - index)
                                                            .toString()));
                                                  },
                                                );
                                              });
                                        });
                                  case 'following':
                                    return InkWell(
                                      child: AlarmCard(
                                        sender: field('alarmSender'),
                                        firstText: "",
                                        secondText: field('alarmSender'),
                                        finalText:
                                            "님이 당신을 팔로우했습니다! 눌러서 확인해주세요!",
                                        time: field('time').toDate(),
                                      ),
                                      onTap: () async {
                                        await showBottomModal(context,
                                            field('alarmSender'), false);
                                        deleteNotifcation(numberPad(
                                            ((len - 1 ?? 0) - index)
                                                .toString()));
                                      },
                                    );
                                  default:
                                    return Container();
                                }
                              },
                            );
                          },
                          itemCount: alarms?.data?.docs?.length ?? 0,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.1,
          ),
          child: Container(
            key: notificationKey,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.5,
          ),
        ),
      ],
    );
  }
}
