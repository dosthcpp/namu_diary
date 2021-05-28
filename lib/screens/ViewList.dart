import 'package:flutter/material.dart';
import 'package:namu_diary/arguments.dart';
import 'package:namu_diary/constants.dart';
import 'package:namu_diary/shared/ProfileImage.dart';
import 'package:namu_diary/utils.dart';

class ViewList extends StatelessWidget {
  static const id = 'view_list';

  @override
  Widget build(BuildContext context) {
    ViewListArgs arguments =
        ModalRoute.of(context).settings.arguments as ViewListArgs;
    return Scaffold(
      appBar: AppBar(
        title: Text(arguments.title),
        backgroundColor: Color(kMainColor),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          final name = arguments.list[index];
          return InkWell(
            child: ListTile(
              leading: profileImage(name, 40.0),
              title: Text(
                name,
              ),
            ),
            onTap: () {
              showBottomModal(context, name, false);
            },
          );
        },
        itemCount: arguments.list.length,
      ),
    );
  }
}
