import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:namu_diary/main.dart';
import 'package:namu_diary/utils.dart';
import 'package:namu_diary/arguments.dart';
import 'package:namu_diary/screens/Chatroom.dart';

final _fireStore = FirebaseFirestore.instance;

class Chat extends StatefulWidget {
  final Function callback;

  Chat({this.callback});

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  int len = 0;
  GlobalKey chatKey = GlobalKey();

  void initState() {
    widget.callback(
      [
        TargetFocus(
          identify: "feed",
          keyTarget: chatKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "채팅 페이지",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "나의 정원에 속한 사람들과 대화를 나눌 수 있습니다.",
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

  Future enterRoom(curChatDoc) async {
    final result = await _fireStore
        .collection(curChatDoc)
        .where('username', isEqualTo: userProvider.currentUser)
        .limit(1)
        .get();
    if (result.docs.length == 0) {
      await _fireStore.collection(curChatDoc).add({
        'username': userProvider.currentUser,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _fireStore
              .collection('/groupchat_${userProvider.currentGarden}_chatTitle')
              .snapshots(),
          builder: (context, titles) {
            final length = titles?.data?.docs?.length ?? 0;
            if (!titles.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView.builder(
              itemBuilder: (context, idx) {
                final String chatTitle = titles.data.docs[idx].data()['chat'];
                return InkWell(
                  onTap: () async {
                    final chatDocPath =
                        '/groupchat_${userProvider.currentGarden}_chat${numberPad((idx + 1).toString())}';
                    final chatDocPathParticipants =
                        '/groupchat_${userProvider.currentGarden}_chat${numberPad((idx + 1).toString())}_participants';
                    await enterRoom(chatDocPathParticipants);
                    Navigator.pushNamed(
                      context,
                      ChatRoom.id,
                      arguments: ChatRoomArgs(
                        chatDocPath: chatDocPath,
                        chatDocPathParticipants: chatDocPathParticipants,
                        roomTitle: chatTitle,
                        store: _fireStore,
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(
                      chatTitle,
                    ),
                  ),
                );
              },
              itemCount: length,
            );
          },
        ),
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.1,
          ),
          child: Container(
            key: chatKey,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.5,
          ),
        ),
      ],
    );
  }
}
