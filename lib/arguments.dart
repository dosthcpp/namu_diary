import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomArgs {
  final String chatDocPath;
  final String chatDocPathParticipants;
  final String roomTitle;
  final Function onPressBackButton;
  final FirebaseFirestore store;

  ChatRoomArgs({
    this.chatDocPath,
    this.chatDocPathParticipants,
    this.roomTitle,
    this.onPressBackButton,
    this.store,
  });
}

class ViewDiaryArgs {
  final String url, diaryPath, diaryNo, user, content, imagePath;
  final DateTime date;

  ViewDiaryArgs({
    this.diaryPath,
    this.diaryNo,
    this.url,
    this.imagePath,
    this.user,
    this.content,
    this.date,
  });
}

class ViewFeedArgs {
  final String url, feedPath, feedNo, user, content, imagePath;
  final DateTime date;

  ViewFeedArgs({
    this.feedPath,
    this.feedNo,
    this.url,
    this.imagePath,
    this.user,
    this.content,
    this.date,
  });
}

class ViewListArgs {
  final String title;
  final List list;

  ViewListArgs({
    this.title,
    this.list,
  });
}

class ViewImageArgs {
  final String url;

  ViewImageArgs({
    this.url,
  });
}
