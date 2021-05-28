import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:namu_diary/components/CustomModifiableField.dart';
import 'package:namu_diary/screens/MainPage.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';

import 'package:namu_diary/arguments.dart';
import 'package:namu_diary/screens/ViewList.dart';
import 'package:namu_diary/screens/ViewImage.dart';
import 'package:namu_diary/main.dart';
import 'package:namu_diary/utils.dart';
import 'package:namu_diary/constants.dart';
import 'package:namu_diary/shared/ReplyBox.dart';
import 'package:namu_diary/shared/ProfileImage.dart';

final _fireStore = FirebaseFirestore.instance;
final _storage = FirebaseStorage.instance;

extension DateFormat on DateTime {
  String toLocaleString() {
    if (DateTime.now().difference(this).inMinutes < 5) {
      return "방금 전";
    } else if (DateTime.now().difference(this).inMinutes < 60) {
      return '${DateTime.now().difference(this).inMinutes}분 전';
    } else if (DateTime.now().difference(this).inHours <= 6) {
      return '${DateTime.now().difference(this).inHours}시간 전';
    } else {
      return '${this.year}년 ${this.month}월 ${this.day}일 ${this.hour}시 ${this.minute}분';
    }
  }
}

class DiaryCard extends StatefulWidget {
  final String diaryPath, user, content, diaryNo, imagePath;
  final Function onPressProfile;
  final DateTime date;
  final DocumentReference ref;
  final url;

  DiaryCard({
    this.imagePath,
    this.diaryPath,
    this.user,
    this.content,
    this.diaryNo,
    this.date,
    this.ref,
    this.url,
    this.onPressProfile,
  });

  @override
  _DiaryCardState createState() => _DiaryCardState();
}

class _DiaryCardState extends State<DiaryCard> {
  bool showMessage = false;
  bool showDetail = false;
  bool disabled = true;
  TextEditingController replyEditingController = TextEditingController();

  String updatedContent = '';
  bool hasImageModified = false;
  File _modifiedImageFile = File('');
  bool update = false;

  bool replyMode = false;
  String replyingUser = '';
  String replyingContent = '';
  int replyingIndex = 0;

  delete(diaries) async {
    final docRef = diaries.data.docs;
    final deleteId = docRef
        .where((el) => el.data()['diaryNo'] == widget.diaryNo)
        .elementAt(0)
        .id;
    final imagePath =
        (await _fireStore.collection(widget.diaryPath).doc(deleteId).get())
            .data()['imagePath'];
    final fileRef = FirebaseStorage.instance.ref().child(imagePath);
    if (fileRef != null) {
      fileRef.delete();
    }
    await _fireStore.collection(widget.diaryPath).doc(deleteId).delete();
    for (var i = int.tryParse(widget.diaryNo) ?? 0;
        i < docRef.length - 1;
        ++i) {
      final id = docRef
          .where((el) => el.data()['diaryNo'] == numberPad((i + 1).toString()))
          .elementAt(0)
          .id;
      // change diaryNo
      await _fireStore.collection(widget.diaryPath).doc(id).update({
        'diaryNo': numberPad(i.toString()),
      });
    }
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, MainPage.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 20.0,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _fireStore
            .collection(widget.diaryPath)
            .where('diaryNo', isEqualTo: widget.diaryNo)
            .limit(1)
            .snapshots(),
        builder: (context, diary) {
          final _diary = diary?.data?.docs?.elementAt(0)?.data() ?? {};
          final likeList = List.from(_diary['like'] ?? []);
          final temp = likeList;
          var like = false;
          var i = 0;
          for (;
              i < likeList.length && !(likeList[i] == userProvider.currentUser);
              ++i);
          if (i < likeList.length) {
            like = true;
          } else {
            like = false;
          }
          final reply = _diary['reply'] ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 50.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              child: profileImage(
                                widget.user,
                                60.0,
                              ),
                              onTap: () {
                                widget.onPressProfile();
                              },
                            ),
                            SizedBox(
                              width: 10.0,
                            ),
                            Text(
                              widget.user,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        update
                            ? Container()
                            : MaterialButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  showAdaptiveActionSheet(
                                    context: context,
                                    title: Text('메뉴'),
                                    actions: [
                                      widget.user == userProvider.currentUser
                                          ? BottomSheetAction(
                                              title: Text(
                                                '삭제',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Platform.isAndroid
                                                        ? AlertDialog(
                                                            title:
                                                                Text('Alert!'),
                                                            content: Text(
                                                                "정말 삭제하겠습니까?"),
                                                            actions: [
                                                              TextButton(
                                                                child:
                                                                    Text('예'),
                                                                onPressed:
                                                                    () async {
                                                                  await delete(
                                                                      diary);
                                                                },
                                                              ),
                                                              TextButton(
                                                                child:
                                                                    Text('아니오'),
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                              ),
                                                            ],
                                                          )
                                                        : CupertinoAlertDialog(
                                                            title:
                                                                Text('Alert!'),
                                                            content: Text(
                                                                "정말 삭제하겠습니까?"),
                                                            actions: [
                                                              TextButton(
                                                                child:
                                                                    Text('예'),
                                                                onPressed:
                                                                    () async {
                                                                  await delete(
                                                                      diary);
                                                                },
                                                              ),
                                                              TextButton(
                                                                child:
                                                                    Text('아니오'),
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                              ),
                                                            ],
                                                          );
                                                  },
                                                );
                                              },
                                            )
                                          : BottomSheetAction(
                                              title: Text(
                                                '신고',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              onPressed: () {},
                                            ),
                                      BottomSheetAction(
                                        title: Text(
                                          '수정',
                                          style: TextStyle(
                                            color: widget.user ==
                                                    userProvider.currentUser
                                                ? Colors.black
                                                : Colors.black54,
                                          ),
                                        ),
                                        onPressed: widget.user ==
                                                userProvider.currentUser
                                            ? () {
                                                updatedContent = widget.content;
                                                setState(() {
                                                  update = !update;
                                                });
                                                Navigator.pop(context);
                                              }
                                            : () {},
                                      )
                                    ],
                                    cancelAction: CancelAction(
                                      title: Text(
                                        '닫기',
                                      ),
                                    ), // onPressed parameter is optional by default will dismiss the ActionSheet
                                  );
                                },
                                child: Image.asset(
                                  'assets/submenu.png',
                                  scale: 2.5,
                                ),
                              ),
                      ],
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        update
                            ? CustomModifiableField(
                                ctx: context,
                                initVal: widget.content,
                                onChanged: (str) {
                                  updatedContent = str;
                                },
                                init: true,
                              )
                            : showDetail
                                ? Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: Text(
                                      widget.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: TextStyle(
                                        letterSpacing: -1.1,
                                      ),
                                    ),
                                  )
                                : Text(
                                    widget.content.length > 12
                                        ? '${widget.content.substring(0, 12)}...'
                                        : widget.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: TextStyle(
                                      letterSpacing: -1.1,
                                    ),
                                  ),
                        update
                            ? Container()
                            : Align(
                                alignment: Alignment.bottomRight,
                                child: GestureDetector(
                                  child: Text(
                                    showDetail ? "< 간략히 보기" : "> 더보기",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10.0,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      showDetail = !showDetail;
                                    });
                                  },
                                ),
                              ),
                      ],
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              InkWell(
                child: hasImageModified
                    ? Image.file(_modifiedImageFile)
                    : CachedNetworkImage(
                        imageUrl: widget.url,
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) =>
                                JumpingDotsProgressIndicator(
                          fontSize: 25.0,
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                onTap: update
                    ? () async {
                        _modifiedImageFile = await pickImage();
                        if (_modifiedImageFile != null) {
                          setState(() {
                            hasImageModified = true;
                          });
                        } else {
                          setState(() {
                            hasImageModified = false;
                          });
                        }
                      }
                    : () {
                        Navigator.pushNamed(
                          context,
                          ViewImage.id,
                          arguments: ViewImageArgs(
                            url: widget.url,
                          ),
                        );
                      },
              ),
              update
                  ? Container()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 10.0,
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: 20.0,
                          ),
                          child: Text(
                            widget.date.toLocaleString(),
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 10.0,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                          ),
                          child: Row(
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: _fireStore
                                    .collection('/alarm_${widget.user}')
                                    .where('alarmSender',
                                        isEqualTo: userProvider.currentUser)
                                    .where('targetUser', isEqualTo: widget.user)
                                    .where('type', isEqualTo: 'like')
                                    .where('content',
                                        isEqualTo:
                                            '${(int.tryParse(widget.diaryNo) + 1) ?? 1}번째 다이어리에 좋아요를 눌렀습니다.')
                                    .limit(1)
                                    .snapshots(),
                                builder: (context, alarmDoc) {
                                  return InkWell(
                                    child: Image.asset(
                                      like
                                          ? 'assets/like.png'
                                          : 'assets/like_unselected.png',
                                      width: 28.0,
                                    ),
                                    onTap: () async {
                                      final updateWhere = _fireStore
                                          .collection(widget.diaryPath)
                                          .doc((await _fireStore
                                                  .collection(widget.diaryPath)
                                                  .where('diaryNo',
                                                      isEqualTo: widget.diaryNo)
                                                  .limit(1)
                                                  .get())
                                              .docs[0]
                                              .id);
                                      if (like) {
                                        temp.removeWhere((el) =>
                                            el == userProvider.currentUser);
                                        updateWhere.update(
                                          {'like': temp},
                                        );
                                      } else {
                                        if (widget.user !=
                                                userProvider.currentUser &&
                                            alarmDoc.data.docs.length == 0) {
                                          // 같은 알림이 가지 않게 한다
                                          await notify(
                                            userProvider.currentUser,
                                            widget.user,
                                            'like',
                                            DateTime.now(),
                                            '${(int.tryParse(widget.diaryNo) + 1) ?? 1}번째 다이어리에 좋아요를 눌렀습니다.',
                                          );
                                        }
                                        temp.removeWhere((el) =>
                                            el == userProvider.currentUser);
                                        updateWhere.update(
                                          {
                                            'like': [
                                              userProvider.currentUser,
                                              ...temp
                                            ],
                                          },
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                              SizedBox(
                                width: 20.0,
                              ),
                              GestureDetector(
                                child: Image.asset(
                                  showMessage
                                      ? 'assets/reply.png'
                                      : 'assets/reply_unselected.png',
                                  width: 28.0,
                                ),
                                onTap: () {
                                  setState(() {
                                    showMessage = !showMessage;
                                  });
                                },
                              ),
                              SizedBox(
                                width: 20.0,
                              ),
                              InkWell(
                                child: Image.asset(
                                  'assets/share.png',
                                  width: 28.0,
                                ),
                                onTap: () {
                                  showAlert(context);
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.0),
                        Visibility(
                          visible: likeList.length != 0,
                          child: InkWell(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.05,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/like.png',
                                    width: 18.0,
                                  ),
                                  SizedBox(
                                    width: 10.0,
                                  ),
                                  Text("${likeList.length}개",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12.0,
                                      )),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                ViewList.id,
                                arguments: ViewListArgs(
                                  title: "좋아요",
                                  list: likeList,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Visibility(
                          visible: showMessage,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 20.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "댓글 ${reply.length}개",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12.0,
                                  ),
                                ),
                                SizedBox(
                                  height: 10.0,
                                ),
                                ListView.builder(
                                  reverse: true,
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        ReplyBox(
                                          isInside: false,
                                          content: reply[index]['content'],
                                          date: reply[index]['date'].toDate(),
                                          type: "reply",
                                          user: reply[index]['user'],
                                          onTapReply: (user, content) {
                                            replyingIndex = index;
                                            setState(() {
                                              replyMode = true;
                                              replyingUser = user;
                                              replyingContent = content;
                                            });
                                          },
                                          isMyReply: reply[index]['user'] ==
                                              userProvider.currentUser,
                                          onTapDelete: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Platform.isAndroid
                                                    ? AlertDialog(
                                                        title: Text('Alert!'),
                                                        content: Text(
                                                            "정말 댓글을 삭제하시겠습니까?"),
                                                        actions: [
                                                          TextButton(
                                                            child: Text('예'),
                                                            onPressed:
                                                                () async {
                                                              reply.removeAt(
                                                                  index);
                                                              final info = await _fireStore
                                                                  .collection(widget
                                                                      .diaryPath)
                                                                  .where(
                                                                      'diaryNo',
                                                                      isEqualTo:
                                                                          widget
                                                                              .diaryNo)
                                                                  .limit(1)
                                                                  .get();
                                                              print(info
                                                                  .docs[0].id);
                                                              await _fireStore
                                                                  .collection(widget
                                                                      .diaryPath)
                                                                  .doc(info
                                                                      .docs[0]
                                                                      .id)
                                                                  .update({
                                                                'reply': reply,
                                                              });
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          TextButton(
                                                            child: Text('아니오'),
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ],
                                                      )
                                                    : CupertinoAlertDialog(
                                                        title: Text('Alert!'),
                                                        content: Text(
                                                            "정말 댓글을 삭제하시겠습니까?"),
                                                        actions: [
                                                          TextButton(
                                                            child: Text('예'),
                                                            onPressed:
                                                                () async {
                                                              reply.removeAt(
                                                                  index);
                                                              final info = await _fireStore
                                                                  .collection(widget
                                                                      .diaryPath)
                                                                  .where(
                                                                      'diaryNo',
                                                                      isEqualTo:
                                                                          widget
                                                                              .diaryNo)
                                                                  .limit(1)
                                                                  .get();
                                                              print(info
                                                                  .docs[0].id);
                                                              await _fireStore
                                                                  .collection(widget
                                                                      .diaryPath)
                                                                  .doc(info
                                                                      .docs[0]
                                                                      .id)
                                                                  .update({
                                                                'reply': reply,
                                                              });
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                          TextButton(
                                                            child: Text('아니오'),
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ],
                                                      );
                                              },
                                            );
                                          },
                                        ),
                                        reply[index]['reply'].length == 0
                                            ? Container()
                                            : ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                itemBuilder: (context, i) {
                                                  final replyin =
                                                      reply[index]['reply'][i];
                                                  return Row(
                                                    children: [
                                                      Transform(
                                                        child: Icon(
                                                          Icons
                                                              .subdirectory_arrow_right_sharp,
                                                          color:
                                                              Color(kMainColor),
                                                        ),
                                                        transform: Matrix4
                                                            .translationValues(
                                                                0, -10.0, 0),
                                                      ),
                                                      Row(
                                                        children: [
                                                          ReplyBox(
                                                            isInside: true,
                                                            content:
                                                            replyin
                                                                    ['content'],
                                                            date: replyin
                                                                    ['date']
                                                                .toDate(),
                                                            type: "reply",
                                                            user: replyin
                                                                ['user'],
                                                            onTapReply: (user,
                                                                content) {
                                                              replyingIndex =
                                                                  index;
                                                              setState(() {
                                                                replyMode =
                                                                    true;
                                                                replyingUser =
                                                                    user;
                                                                replyingContent =
                                                                    content;
                                                              });
                                                            },
                                                            isMyReply: replyin[
                                                                    'user'] ==
                                                                userProvider
                                                                    .currentUser,
                                                            onTapDelete: () {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
                                                                  return Platform
                                                                          .isAndroid
                                                                      ? AlertDialog(
                                                                          title:
                                                                              Text('Alert!'),
                                                                          content:
                                                                              Text("정말 댓글을 삭제하시겠습니까?"),
                                                                          actions: [
                                                                            TextButton(
                                                                              child: Text('예'),
                                                                              onPressed: () async {
                                                                                List willUpdateReply = reply[index]['reply'];
                                                                                willUpdateReply.removeAt(i);
                                                                                reply[index]['reply'] = willUpdateReply;
                                                                                final info = await _fireStore.collection(widget.diaryPath).where('diaryNo', isEqualTo: widget.diaryNo).limit(1).get();
                                                                                await _fireStore.collection(widget.diaryPath).doc(info.docs[0].id).update(
                                                                                  {
                                                                                    'reply': reply,
                                                                                  },
                                                                                );
                                                                                Navigator.pop(context);
                                                                              },
                                                                            ),
                                                                            TextButton(
                                                                              child: Text('아니오'),
                                                                              onPressed: () {
                                                                                Navigator.pop(context);
                                                                              },
                                                                            ),
                                                                          ],
                                                                        )
                                                                      : CupertinoAlertDialog(
                                                                          title:
                                                                              Text('Alert!'),
                                                                          content:
                                                                              Text("정말 댓글을 삭제하시겠습니까?"),
                                                                          actions: [
                                                                            TextButton(
                                                                              child: Text('예'),
                                                                              onPressed: () async {
                                                                                List willUpdateReply = reply[index]['reply'];
                                                                                willUpdateReply.removeAt(i);
                                                                                reply[index]['reply'] = willUpdateReply;
                                                                                final info = await _fireStore.collection(widget.diaryPath).where('diaryNo', isEqualTo: widget.diaryNo).limit(1).get();
                                                                                await _fireStore.collection(widget.diaryPath).doc(info.docs[0].id).update(
                                                                                  {
                                                                                    'reply': reply,
                                                                                  },
                                                                                );
                                                                                Navigator.pop(context);
                                                                              },
                                                                            ),
                                                                            TextButton(
                                                                              child: Text('아니오'),
                                                                              onPressed: () {
                                                                                Navigator.pop(context);
                                                                              },
                                                                            ),
                                                                          ],
                                                                        );
                                                                },
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                },
                                                itemCount: reply[index]['reply']
                                                    .length,
                                              ),
                                      ],
                                    );
                                  },
                                  itemCount: reply?.length ?? 0,
                                ),
                                Visibility(
                                  visible: replyMode,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 20.0,
                                      ),
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.8,
                                                height: 30.0,
                                                color: Colors.white,
                                                child: Text(
                                                  '$replyingUser에게 답장',
                                                  style: TextStyle(
                                                      color: Color(kMainColor)),
                                                ),
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.8,
                                                height: 30.0,
                                                color: Colors.white,
                                                child: Text(
                                                  replyingContent,
                                                ),
                                              ),
                                            ],
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                replyMode = false;
                                              });
                                            },
                                            child: Icon(
                                              Icons.close,
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        child: profileImage(
                                          userProvider.currentUser,
                                          100.0,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10.0,
                                    ),
                                    Expanded(
                                      flex: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200].withOpacity(
                                            0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30.0,
                                          ),
                                        ),
                                        child: TextFormField(
                                          style: TextStyle(
                                            fontSize: 14.0,
                                          ),
                                          controller: replyEditingController,
                                          decoration: InputDecoration(
                                            hintText: "답변을 입력하세요...",
                                            hintStyle: TextStyle(
                                              fontSize: 14.0,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 20.0,
                                            ),
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                          ),
                                          onChanged: (val) {
                                            if (val.trim().length == 0) {
                                              setState(() {
                                                disabled = true;
                                              });
                                            } else {
                                              setState(() {
                                                disabled = false;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10.0,
                                    ),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: disabled
                                              ? Colors.grey
                                              : Color(kMainColor),
                                        ),
                                        child: MaterialButton(
                                          padding: EdgeInsets.zero,
                                          child: Icon(
                                            Icons.arrow_upward,
                                            color: Colors.white,
                                          ),
                                          onPressed: disabled
                                              ? null
                                              : () async {
                                                  if (replyEditingController
                                                              .text.length !=
                                                          0 &&
                                                      replyEditingController
                                                          .text.isNotEmpty) {
                                                    if (replyMode) {
                                                      if (replyingUser !=
                                                          userProvider
                                                              .currentUser) {
                                                        await notify(
                                                          userProvider
                                                              .currentUser,
                                                          replyingUser,
                                                          'reply',
                                                          DateTime.now(),
                                                          "${int.tryParse(widget.diaryNo) + 1?? 1}번째 피드의 댓글 $replyingContent에 ${replyEditingController.text}(이)라고 남겼습니다!",
                                                          path:
                                                              widget.diaryPath,
                                                          index: widget.diaryNo,
                                                        );
                                                      }
                                                      final ref = await _fireStore
                                                          .collection(
                                                              widget.diaryPath)
                                                          .where('diaryNo',
                                                              isEqualTo: widget
                                                                  .diaryNo)
                                                          .limit(1)
                                                          .get();
                                                      reply[replyingIndex]
                                                              ['reply']
                                                          .add({
                                                        'content':
                                                            replyEditingController
                                                                .text,
                                                        'date':
                                                            Timestamp.fromDate(
                                                                DateTime.now()),
                                                        'like': [],
                                                        'type': 'reply',
                                                        'user': userProvider
                                                            .currentUser,
                                                      });
                                                      await _fireStore
                                                          .collection(
                                                              widget.diaryPath)
                                                          .doc(ref.docs[0].id)
                                                          .update(
                                                        {'reply': reply},
                                                      );
                                                      setState(
                                                        () {
                                                          replyEditingController
                                                              .clear();
                                                          disabled = true;
                                                          replyMode = false;
                                                        },
                                                      );
                                                    } else {
                                                      if (widget.user !=
                                                          userProvider
                                                              .currentUser) {
                                                        await notify(
                                                            userProvider
                                                                .currentUser,
                                                            widget.user,
                                                            'reply',
                                                            DateTime.now(),
                                                            "${int.tryParse(widget.diaryNo) + 1?? 1}번째 피드에 ${replyEditingController.text}(이)라고 남겼습니다!",
                                                            path: widget
                                                                .diaryPath,
                                                            index:
                                                                widget.diaryNo);
                                                      }
                                                      final ref = await _fireStore
                                                          .collection(
                                                              widget.diaryPath)
                                                          .where('diaryNo',
                                                              isEqualTo: widget
                                                                  .diaryNo)
                                                          .limit(1)
                                                          .get();
                                                      await _fireStore
                                                          .collection(
                                                              widget.diaryPath)
                                                          .doc(ref.docs[0].id)
                                                          .update({
                                                        'reply': [
                                                          {
                                                            'content':
                                                                replyEditingController
                                                                    .text,
                                                            'date': Timestamp
                                                                .fromDate(
                                                                    DateTime
                                                                        .now()),
                                                            'like': [],
                                                            'reply': [],
                                                            'type': 'reply',
                                                            'user': userProvider
                                                                .currentUser,
                                                          },
                                                          ...reply
                                                        ]
                                                      });
                                                      setState(
                                                        () {
                                                          replyEditingController
                                                              .clear();
                                                          disabled = true;
                                                        },
                                                      );
                                                    }
                                                  }
                                                },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: 10.0),
              !update
                  ? Container()
                  : Padding(
                      padding: EdgeInsets.only(
                        right: 10.0,
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 10 * 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              5.0,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Color(0xff40c149),
                                Color(0xff30a69a),
                              ],
                            ),
                          ),
                          child: MaterialButton(
                            onPressed: () async {
                              await _fireStore
                                  .collection(widget.diaryPath)
                                  .doc((await _fireStore
                                          .collection(widget.diaryPath)
                                          .get())
                                      .docs
                                      .where((el) =>
                                          el.data()['diaryNo'] ==
                                          widget.diaryNo)
                                      .elementAt(0)
                                      .id)
                                  .update({'content': updatedContent});
                              if (hasImageModified) {
                                final fileRef =
                                    _storage.ref().child(widget.imagePath);
                                if (fileRef != null) {
                                  fileRef.delete();
                                }
                                await fileRef.putFile(_modifiedImageFile);
                              }
                              setState(() {
                                update = false;
                              });
                            },
                            child: Text(
                              "확인",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
            ],
          );
        },
      ),
    );
  }
}
