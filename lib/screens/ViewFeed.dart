import 'package:flutter/material.dart';

import 'package:namu_diary/arguments.dart';
import 'package:namu_diary/materials/FeedCard.dart';

class ViewFeed extends StatelessWidget {
  static const id = 'view_feed';

  @override
  Widget build(BuildContext context) {
    final ViewFeedArgs arguments =
    ModalRoute.of(context).settings.arguments as ViewFeedArgs;

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: FeedCard(
            feedPath: arguments.feedPath,
            feedNo: arguments.feedNo,
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
