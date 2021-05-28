import 'package:flutter/material.dart';

import 'package:namu_diary/arguments.dart';
import 'package:namu_diary/materials/DiaryCard.dart';

class ViewDiary extends StatelessWidget {
  static const id = 'view_diary';

  @override
  Widget build(BuildContext context) {
    final ViewDiaryArgs arguments =
        ModalRoute.of(context).settings.arguments as ViewDiaryArgs;

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: DiaryCard(
            diaryPath: arguments.diaryPath,
            diaryNo: arguments.diaryNo,
            imagePath: arguments.imagePath,
            url: arguments.url,
            user: arguments.user,
            content: arguments.content,
            date: arguments.date,
          ),
        ),
      ),
    );
  }
}
