import 'package:flutter/material.dart';

import 'package:namu_diary/materials/DiaryCard.dart';
import 'package:namu_diary/materials/FeedCard.dart';
import 'package:namu_diary/utils.dart';
import 'package:namu_diary/main.dart';
import 'package:namu_diary/dummy/Dummy.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

final _store = FirebaseFirestore.instance;
final _fireStorage = FirebaseStorage.instance;

class Feed extends StatefulWidget {
  final Function callback;

  Feed({this.callback});

  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  GlobalKey feedKey = GlobalKey();

  @override
  void initState() {
    widget.callback(
      [
        TargetFocus(
          identify: "feed",
          keyTarget: feedKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "피드 페이지",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "내 다이어리, 내가 팔로우한 유저의 다이어리 또는 내 정원의 유저들이 올린 다이어리들이 실시간으로 업로드됩니다. AR정원 사진 뿐 아니라 나의 일상이나 나의 일상도 공유할 수 있습니다. 다른사람들의 댓글과 좋아요 등을 확인할 수 있습니다.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
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
    return SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      child: Stack(
        children: [
          Column(
            children: [
              StreamBuilder(
                stream: _store
                    .collection('/userInfo_${userProvider.currentEmail}')
                    .limit(1)
                    .snapshots(),
                builder: (context, info) {
                  if (!info.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  List<String> followings = List.from(
                    ((info?.data?.docs?.length != 0
                                ? info?.data?.docs
                                : [Dummy()])
                            ?.elementAt(0)
                            ?.data() ??
                        {'following': []})['following'],
                  );
                  followings.add(userProvider.currentUser); // 나도 포함

                  return ListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    itemBuilder: (context, i) {
                      final name = followings[i];
                      return StreamBuilder(
                        stream: _store.collection('/diary_$name').snapshots(),
                        builder: (context, diaries) {
                          if (!diaries.hasData) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final length = diaries?.data?.docs?.length ?? 0;
                          return ListView.builder(
                            shrinkWrap: true,
                            primary: false,
                            physics: ClampingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final diary = (diaries?.data?.docs
                                      ?.where((el) =>
                                          el.data()['diaryNo'] ==
                                          numberPad(index.toString()))
                                      ?.elementAt(0)
                                      ?.data()) ??
                                  {};
                              final imagePath = diary['imagePath'];
                              return FutureBuilder(
                                future: _fireStorage
                                    .ref(imagePath)
                                    .getDownloadURL(),
                                builder: (context, url) {
                                  if (!url.hasData) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  return StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .collection('/diary_$name')
                                        .snapshots(),
                                    builder: (context, diaries) {
                                      if (!diaries.hasData) {
                                        return Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      return DiaryCard(
                                        diaryPath: '/diary_$name',
                                        imagePath: diary['imagePath'],
                                        user: name,
                                        content: diary['content'],
                                        url: url.data,
                                        diaryNo: numberPad(index.toString()),
                                        date: diary['date'].toDate(),
                                        onPressProfile: () {
                                          showBottomModal(context, name, false);
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            itemCount: length,
                          );
                        },
                      );
                    },
                    itemCount: followings?.length ?? 0,
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _store
                    .collection('/feed_${userProvider.currentGarden}')
                    .snapshots(),
                builder: (context, feeds) {
                  return ListView.builder(
                    primary: false,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final feed = List.from(feeds?.data?.docs?.where((el) =>
                                  (el?.data() ?? {'feedNo': "0"})['feedNo'] ==
                                  numberPad(index.toString())))
                              ?.elementAt(0)
                              ?.data() ??
                          {};
                      return FutureBuilder(
                        future: _fireStorage
                            .ref()
                            .child(feed['imagePath'])
                            .getDownloadURL(),
                        builder: (context, url) {
                          if (!url.hasData) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return FeedCard(
                            feedPath: '/feed_${userProvider.currentGarden}',
                            feedNo: feed['feedNo'],
                            user: feed['user'],
                            content: feed['content'],
                            imagePath: feed['imagePath'],
                            url: url.data,
                            date: feed['date'].toDate(),
                          );
                        },
                      );
                    },
                    itemCount: feeds?.data?.docs?.length ?? 0,
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.1,
            ),
            child: Container(
              key: feedKey,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
