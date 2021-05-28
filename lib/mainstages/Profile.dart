import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:namu_diary/arguments.dart';
import 'package:namu_diary/screens/ViewDiary.dart';
import 'package:namu_diary/main.dart';
import 'package:namu_diary/materials/GradientText.dart';
import 'package:namu_diary/constants.dart';
import 'package:namu_diary/screens/ViewList.dart';
import 'package:namu_diary/shared/ProfileImage.dart';
import 'package:namu_diary/utils.dart';

final _store = FirebaseFirestore.instance;
final _storage = FirebaseStorage.instance;

class Profile extends StatefulWidget {
  final Function callback;

  Profile({this.callback});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  File _imageFile;
  bool showMore = false;
  GlobalKey profileSection = GlobalKey();
  GlobalKey myGarden = GlobalKey();

  Future pickImage() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      String filePath = result?.files?.single?.path ?? '';

      setState(() {
        if (filePath != null) {
          _imageFile = File(filePath);
        } else {
          print('No image selected.');
        }
      });
    } else {
      // User canceled the picker
    }
  }

  @override
  void initState() {
    widget.callback(
      [
        TargetFocus(
          identify: "profileSection",
          keyTarget: profileSection,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Transform(
                transform: Matrix4.translationValues(0, 150.0, 0),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "프로필 섹션",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.0),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Text(
                          "내 프로필 사진을 변경할 수 있고, 탭하여 나의 팔로워나 팔로잉을 확인할 수 있습니다.",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
        TargetFocus(
          identify: "myGarden",
          keyTarget: myGarden,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Transform(
                transform: Matrix4.translationValues(0, 20.0, 0),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "내 다이어리",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20.0),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Text(
                          "탭하여 내가 올린 다이어리들을 확인합니다. 다른사람들의 댓글과 좋아요 등을 확인할 수 있습니다.",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 30.0,
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width - 30,
                child: Row(
                  key: profileSection,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        child: profileImage(
                          userProvider.currentUser,
                          100.0,
                        ),
                        onTap: () {
                          showAdaptiveActionSheet(
                            context: context,
                            title: Text('Menu'),
                            actions: [
                              BottomSheetAction(
                                title: Text('프로필 변경'),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await pickImage().then(
                                    (_) {
                                      uploadImageToFirebase(
                                              'uploads/userProfile/${userProvider.currentUser}',
                                              _imageFile)
                                          .then(
                                        (value) => profileProvider.init(),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                            cancelAction: CancelAction(
                              title: Text(
                                'Cancel',
                              ),
                            ), // onPressed parameter is optional by default will dismiss the ActionSheet
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 10.0,
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                userProvider?.currentUser ?? '',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              userProvider.currentEmail != null
                                  ? StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection(
                                              '/userInfo_${userProvider.currentEmail}')
                                          .limit(1)
                                          .snapshots(),
                                      builder: (_, snapshot) {
                                        if (!snapshot.hasData)
                                          return Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        final follower = List.from(snapshot
                                            .data.docs[0]
                                            .data()['follower']);
                                        final following = List.from(snapshot
                                            .data.docs[0]
                                            .data()['following']);
                                        return Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              10 *
                                              6,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              StreamBuilder<QuerySnapshot>(
                                                  stream: FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          '/diary_${userProvider.currentUser}')
                                                      .snapshots(),
                                                  builder: (context, diaries) {
                                                    final length = diaries?.data
                                                            ?.docs?.length ??
                                                        0;
                                                    return Text(
                                                      "일지 $length개",
                                                      style: kTextSubStyle,
                                                    );
                                                  }),
                                              InkWell(
                                                child: Text(
                                                  "팔로워 ${follower?.length ?? 0}명",
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
                                                },
                                              ),
                                              InkWell(
                                                child: Text(
                                                  "팔로잉 ${following?.length ?? 0}명",
                                                  style: kTextSubStyle,
                                                ),
                                                onTap: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    ViewList.id,
                                                    arguments: ViewListArgs(
                                                      title: "팔로워",
                                                      list: following,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      })
                                  : Center(child: CircularProgressIndicator()),
                            ],
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          Transform(
                            transform: Matrix4.translationValues(0, -10, 0),
                            child: InkWell(
                              onTap: () {
                                showAdaptiveActionSheet(
                                  context: context,
                                  title: Text('Menu'),
                                  actions: [
                                    BottomSheetAction(
                                      title: Text('프로필 변경'),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await pickImage().then(
                                          (_) {
                                            uploadImageToFirebase(
                                                    'uploads/userProfile/${userProvider.currentUser}',
                                                    _imageFile)
                                                .then(
                                              (value) => profileProvider.init(),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                  cancelAction: CancelAction(
                                    title: Text(
                                      'Cancel',
                                    ),
                                  ), // onPressed parameter is optional by default will dismiss the ActionSheet
                                );
                              },
                              child: Image.asset(
                                'assets/submenu.png',
                                scale: 2.5,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.ideographic,
                children: [
                  GradientText(
                    "내 다이어리",
                    gradient: LinearGradient(
                      colors: [
                        Color(0xff40c149),
                        Color(0xff30a69a),
                      ],
                    ),
                    size: 25.0,
                  ),
                  TextButton(
                    child: Text(
                      showMore ? "< 간략히 보기" : "> 더보기",
                      style: TextStyle(
                        fontSize: 10.0,
                        color: Colors.black54,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        showMore = !showMore;
                      });
                    },
                  )
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.0,
                    ),
                    sliver: StreamBuilder<QuerySnapshot>(
                        stream: _store
                            .collection('/diary_${userProvider.currentUser}')
                            .snapshots(),
                        builder: (context, diaries) {
                          final length = diaries?.data?.docs?.length ?? 0;
                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.0,
                              mainAxisSpacing: 10.0,
                              crossAxisSpacing: 10.0,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final diary = List.from((diaries
                                                    ?.data?.docs?.length !=
                                                0
                                            ? diaries?.data?.docs?.where((el) =>
                                                el.data()['diaryNo'] ==
                                                numberPad(index.toString()))
                                            : [{}]))
                                        ?.elementAt(0)
                                        ?.data() ??
                                    {};
                                return FutureBuilder(
                                    future: _storage
                                        .ref(diary['imagePath'])
                                        .getDownloadURL(),
                                    builder: (context, url) {
                                      if (!url.hasData) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }
                                      return InkWell(
                                        child: Image.network(
                                          url.data,
                                          errorBuilder:
                                              (context, exception, stackTrace) {
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          },
                                        ),
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            ViewDiary.id,
                                            arguments: ViewDiaryArgs(
                                              url: url.data,
                                              diaryPath:
                                                  '/diary_${userProvider.currentUser}',
                                              imagePath: diary['imagePath'],
                                              diaryNo: diary['diaryNo'],
                                              user: userProvider.currentUser,
                                              content: diary['content'],
                                              date: diary['date'].toDate(),
                                            ),
                                          );
                                        },
                                      );
                                    });
                              },
                              childCount: showMore
                                  ? length
                                  : length > 9
                                      ? 9
                                      : length,
                            ),
                          );
                        }),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.1,
          ),
          child: Container(
            key: myGarden,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.5,
          ),
        ),
      ],
    );
  }
}
