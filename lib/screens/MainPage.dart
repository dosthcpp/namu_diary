// TODO

// 1. 핸드폰 인증
// 2. 카카오, 네이버 로그인
// 3. es3 파일 공유기능(다이어리)
// 4. 뒤로 가기 버튼(안드로이드)

// 5. 가든 창 껐을때 완전히 죽이기

/*
가입절차
여타앱과 비교해서 어려운건 없음 다만 핸드폰번호 입력시 하이폰도 넣어야 하는것과 프사 미설정시 가입안되는것이
안내가 없으니 헤맸었음. 정원앱 특성상 나이대가 좀 있는 사람들이 사용할텐데 불편을 느낄수 있을것같음

디자인
내 정원이라는 컨셉에 맞게 초록초록한거는 좋은데   뭔가 좀 더 귀여운맛이 있는것도 나쁘지 않을듯함.

편의성
뒤로가기 버튼의 비활성화가 상당히 불편함.
메인에 여러 사람의 피드가 올라오면 좋을것같고 인스타처럼 피드에서 바로 팔로우 가능하면 좋을것같음.
추천누르면 몇개 추천 받았는지 나오면 좋을듯.
앱이 조금 느린감이 있는것같음.
피드에 글을 길게쓰면 더보기를 눌러도 ...으로 생략이돼서 아쉬움

좋은말 쓰는것보단 현실적인게 도움될것 같아서 이렇게 써봄. 앱자체는 상당히 괜찮은것 같음. 화이팅
 */

// 어떻게 디자인이 들어가고, 어떻게 디자인을 하면 좋을지, 어떤 디자인을 하면 사람들과 소통이 잘 될지, 계절별로 아름다운 정원을 만들기
// 어떻게 소통할거냐, 마을 사람들과 어떻게 소통하고 가꾸어갈거냐, 어떻게 관리할거냐
// 계절별 아름다운 나무, 꽃이 없어도 아름다운 나무

import 'package:namu_diary/main.dart';
import 'package:namu_diary/components/CustomBottomNavigationBar.dart';
import 'package:namu_diary/components/Logo.dart';
import 'package:namu_diary/constants.dart';
import 'package:namu_diary/utils.dart';
import 'package:namu_diary/mainstages/Alarm.dart';
import 'package:namu_diary/mainstages/Feed.dart';
import 'package:namu_diary/mainstages/Profile.dart';
import 'package:namu_diary/mainstages/ARGardenPrev.dart';
import 'package:namu_diary/mainstages/Chat.dart';
import 'package:namu_diary/providers/NavigationProvider.dart';
import 'package:namu_diary/screens/WriteDiaryPage.dart';
import 'package:namu_diary/screens/WriteFeedPage.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

final _fireStore = FirebaseFirestore.instance;

class MainPage extends StatefulWidget {
  static const id = 'main_page';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final feed = 0, ar = 1, alarm = 2, chat = 3, profile = 4;
  bool treeArrowVisible = true;
  static Color mainColor = Color(kMainColor);

  GlobalKey writeFeedButton = GlobalKey();
  List<TargetFocus> targetsOnFeedPage = [];
  List<TargetFocus> targetsOnARGardenPage = [];
  GlobalKey deleteAllNotiButton = GlobalKey();
  List<TargetFocus> targetsOnAlarmPage = [];
  GlobalKey addChatButton = GlobalKey();
  List<TargetFocus> targetsOnChatPage = [];
  GlobalKey writeDiaryButton = GlobalKey();
  GlobalKey logoutButton = GlobalKey();
  List<TargetFocus> targetsOnProfilePage = [];

  final TextStyle kTitleStyle = TextStyle(
    color: mainColor,
    fontSize: 25.0,
  );

  Widget renderTitle(idx) {
    switch (idx) {
      case 0: // feed
        return TreeiumLogo(
          fontSize: 13.0,
          color: mainColor,
        );
      case 1: //
        return Text(
          "AR가든 접속",
          style: kTitleStyle,
        );
      case 2: // alarm
        return Text(
          "알림",
          style: kTitleStyle,
        );
      case 3: // chat
        return Text(
          "채팅",
          style: kTitleStyle,
        );
      case 4: // profile
        return Text(
          "내 프로필",
          style: kTitleStyle,
        );
      default:
        return Container();
    }
  }

  addTargetFocusOnFeedPage(List<TargetFocus> targetFocus) {
    for (var focus in targetFocus) {
      targetsOnFeedPage.add(focus);
    }
  }

  addTargetFocusOnARGardenPage(List<TargetFocus> targetFocus) {
    for (var focus in targetFocus) {
      targetsOnARGardenPage.add(focus);
    }
  }

  addTargetFocusOnAlarmPage(List<TargetFocus> targetFocus) {
    for (var focus in targetFocus) {
      targetsOnAlarmPage.add(focus);
    }
  }

  addTargetFocusOnChatPage(List<TargetFocus> targetFocus) {
    for (var focus in targetFocus) {
      targetsOnChatPage.add(focus);
    }
  }

  addTargetFocusOnProfilePage(List<TargetFocus> targetFocus) {
    for (var focus in targetFocus) {
      targetsOnProfilePage.add(focus);
    }
  }

  Consumer renderAppbar(List<Widget> actionList, Widget _leading) {
    return Consumer<NavigationProvider>(
      builder: (_, provider, __) => AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: renderTitle(provider.mainPageIdx),
        actions: actionList,
        leading: _leading,
      ),
    );
  }

  @override
  void initState() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        if (!navigationProvider.initFlag) {
          final currentUser = authProvider.currentUser;
          final currentGarden = '우리정원';
          await userProvider.setCurrentUser(currentUser);
          userProvider.setCurrentGarden(currentGarden);
          final alarm =
              await _fireStore.collection('/alarm_$currentUser').get();
          if (alarm.docs.length == 0) {
            await _fireStore.collection('/alarm_$currentUser').add({});
          }
          await profileProvider.init();
          navigationProvider.setInitFlag();
        }

        targetsOnFeedPage.add(
          TargetFocus(
            identify: "writeFeedButton",
            keyTarget: writeFeedButton,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "피드 작성",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.0),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Text(
                          "내 정원에 속한 사람들에게 보여줄 피드를 작성합니다.",
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

        targetsOnAlarmPage.add(
          TargetFocus(
            identify: "deleteAllNotiButton",
            keyTarget: deleteAllNotiButton,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "알림 삭제",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.0),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Text(
                          "모든 알림을 삭제합니다.",
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

        targetsOnChatPage.add(
          TargetFocus(
            identify: "addChatButton",
            keyTarget: addChatButton,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "채팅방 추가",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.0),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Text(
                          "채팅방을 추가하는 버튼입니다.",
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

        targetsOnProfilePage.add(
          TargetFocus(
            identify: "writeDiaryButton",
            keyTarget: writeDiaryButton,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "다이어리 쓰기",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.0),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Text(
                          "탭하여 나의 일지를 써 봅시다.",
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

        targetsOnProfilePage.add(
          TargetFocus(
            identify: "logoutButton",
            keyTarget: logoutButton,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "로그아웃",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.0),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Text(
                          "로그아웃 버튼입니다.",
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Consumer<NavigationProvider>(
        builder: (_, provider, __) => Scaffold(
          backgroundColor: Color(0xfffefefe),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(50.0),
            child: ListView.builder(
              itemBuilder: (context, idx) {
                return [
                  Offstage(
                    offstage: navigationProvider.mainPageIdx != feed,
                    child: TickerMode(
                      enabled: navigationProvider.mainPageIdx == feed,
                      child: renderAppbar(
                        [
                          Padding(
                            child: InkWell(
                              child: Image.asset(
                                'assets/question-mark.png',
                                width: 25.0,
                              ),
                              onTap: () {
                                TutorialCoachMark(
                                  context,
                                  targets: targetsOnFeedPage,
                                  colorShadow: Color(kMainColor),
                                  // onClickTarget: (target){
                                  //   print(target);
                                  // },
                                  // onClickOverlay: (target){
                                  //   print(target);
                                  // },
                                  // onSkip: (){
                                  //   print("skip");
                                  // },
                                  // onFinish: (){
                                  //   print("finish");
                                  // },
                                )..show();
                              },
                            ),
                            padding: EdgeInsets.only(
                              right: 5.0,
                            ),
                          ),
                          Padding(
                            child: InkWell(
                              key: writeFeedButton,
                              onTap: () {
                                Navigator.pushNamed(context, WriteFeedPage.id);
                              },
                              child: Image.asset(
                                'assets/edit.png',
                                width: 25.0,
                              ),
                            ),
                            padding: EdgeInsets.only(
                              right: 5.0,
                            ),
                          ),
                        ],
                        null,
                      ),
                    ),
                  ),
                  Offstage(
                    offstage: navigationProvider.mainPageIdx != ar,
                    child: TickerMode(
                      enabled: navigationProvider.mainPageIdx == ar,
                      // child: Header(),
                      child: renderAppbar([
                        Padding(
                          child: InkWell(
                            child: Image.asset(
                              'assets/question-mark.png',
                              width: 25.0,
                            ),
                            onTap: () {
                              TutorialCoachMark(
                                context,
                                targets: targetsOnARGardenPage,
                                colorShadow: Color(kMainColor),
                              )..show();
                            },
                          ),
                          padding: EdgeInsets.only(
                            right: 5.0,
                          ),
                        ),
                      ], null),
                    ),
                  ),
                  Offstage(
                    offstage: navigationProvider.mainPageIdx != alarm,
                    child: TickerMode(
                      enabled: navigationProvider.mainPageIdx == alarm,
                      child: renderAppbar([
                        Padding(
                          child: InkWell(
                            key: deleteAllNotiButton,
                            child: Icon(
                              Icons.close,
                              color: Color(kMainColor),
                            ),
                            onTap: () async {
                              final notiPath =
                                  '/alarm_${userProvider.currentUser}';
                              final ref =
                                  await _fireStore.collection(notiPath).get();
                              for (var i = 0; i < ref.docs.length; ++i) {
                                await _fireStore
                                    .collection(notiPath)
                                    .doc(ref.docs[i].id)
                                    .delete();
                              }
                            },
                          ),
                          padding: EdgeInsets.only(
                            right: 5.0,
                          ),
                        ),
                        Padding(
                          child: InkWell(
                            child: Image.asset(
                              'assets/question-mark.png',
                              width: 25.0,
                            ),
                            onTap: () {
                              TutorialCoachMark(
                                context,
                                targets: targetsOnAlarmPage,
                                colorShadow: Color(kMainColor),
                              )..show();
                            },
                          ),
                          padding: EdgeInsets.only(
                            right: 5.0,
                          ),
                        ),
                      ], null),
                    ),
                  ),
                  Offstage(
                    offstage: navigationProvider.mainPageIdx != chat,
                    child: TickerMode(
                      enabled: navigationProvider.mainPageIdx == chat,
                      child: renderAppbar(
                        [
                          Padding(
                            child: InkWell(
                              child: Image.asset(
                                'assets/question-mark.png',
                                width: 25.0,
                              ),
                              onTap: () {
                                TutorialCoachMark(
                                  context,
                                  targets: targetsOnChatPage,
                                  colorShadow: Color(kMainColor),
                                )..show();
                              },
                            ),
                            padding: EdgeInsets.only(
                              right: 5.0,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 5.0),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _fireStore
                                  .collection(
                                      '/groupchat_${userProvider.currentGarden}_chatTitle')
                                  .snapshots(),
                              builder: (context, titles) {
                                final length = titles?.data?.docs?.length ?? 0;
                                return InkWell(
                                  key: addChatButton,
                                  onTap: () async {
                                    await _fireStore
                                        .collection(
                                            "/groupchat_${userProvider.currentGarden}_chat${numberPad((length + 1).toString())}")
                                        .add({
                                      'content': "채팅방이 생성되었습니다",
                                      'sender': "관리자",
                                      'date':
                                          Timestamp.fromDate(DateTime.now()),
                                      'type': 'chat',
                                    }).catchError((_) {
                                      print("an error occured");
                                    });
                                    print("채팅방이 생성되었습니다.");
                                    await _fireStore
                                        .collection(
                                            "/groupchat_${userProvider.currentGarden}_chat${numberPad((length + 1).toString())}_participants")
                                        .add({
                                      'username': userProvider.currentUser,
                                    }).catchError((_) {
                                      print("an error occured");
                                    });
                                    print("참여자가 생성되었습니다.");
                                    final titlePath =
                                        "/groupchat_${userProvider.currentGarden}_chatTitle";
                                    await _fireStore.collection(titlePath).add({
                                      'chat':
                                          "${userProvider.currentGarden}단톡방${numberPad((length + 1).toString())}",
                                    }).catchError((_) {
                                      print("an error occured");
                                    });
                                  },
                                  child: Icon(
                                    Icons.add,
                                    color: Color(kMainColor),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        null,
                      ),
                    ),
                  ),
                  Offstage(
                    offstage: navigationProvider.mainPageIdx != profile,
                    child: TickerMode(
                      enabled: navigationProvider.mainPageIdx == profile,
                      child: renderAppbar(
                        [
                          Padding(
                            child: InkWell(
                              child: Image.asset(
                                'assets/question-mark.png',
                                width: 25.0,
                              ),
                              onTap: () {
                                TutorialCoachMark(
                                  context,
                                  targets: targetsOnProfilePage,
                                  colorShadow: Color(kMainColor),
                                )..show();
                              },
                            ),
                            padding: EdgeInsets.only(
                              right: 5.0,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              right: 5.0,
                            ),
                            child: InkWell(
                              key: writeDiaryButton,
                              onTap: () {
                                // for upload function
                                Navigator.pushNamed(context, WriteDiaryPage.id,
                                    arguments: context);
                              },
                              child: Image.asset(
                                'assets/edit.png',
                                width: 25.0,
                              ),
                            ),
                          )
                        ],
                        InkWell(
                          key: logoutButton,
                          child: Icon(
                            Icons.logout,
                            color: Color(kMainColor),
                          ),
                          onTap: () {
                            authProvider.logout();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ),
                ][idx];
              },
              itemCount: 5,
            ),
          ),
          body: Stack(
            children: [
              Offstage(
                offstage: provider.mainPageIdx != feed,
                child: TickerMode(
                  enabled: provider.mainPageIdx == feed,
                  child: Feed(
                    callback: addTargetFocusOnFeedPage,
                  ),
                ),
              ),
              Offstage(
                offstage: provider.mainPageIdx != ar,
                child: TickerMode(
                  enabled: provider.mainPageIdx == ar,
                  child: ARGardenPrev(
                    callback: addTargetFocusOnARGardenPage,
                  ),
                ),
              ),
              Offstage(
                offstage: provider.mainPageIdx != alarm,
                child: TickerMode(
                  enabled: provider.mainPageIdx == alarm,
                  child: Alarm(
                    callback: addTargetFocusOnAlarmPage,
                  ),
                ),
              ),
              Offstage(
                offstage: provider.mainPageIdx != chat,
                child: TickerMode(
                  enabled: provider.mainPageIdx == chat,
                  child: Chat(
                    callback: addTargetFocusOnChatPage,
                  ),
                ),
              ),
              Offstage(
                offstage: provider.mainPageIdx != profile,
                child: TickerMode(
                  enabled: provider.mainPageIdx == profile,
                  child: Profile(
                    callback: addTargetFocusOnProfilePage,
                  ),
                ),
              )
            ],
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            selectedIdx: provider.mainPageIdx,
            onTap: (idx) {
              provider.setMainPageIdx(idx);
            },
          ),
        ),
      ),
    );
  }
}
