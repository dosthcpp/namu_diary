import 'package:flutter/material.dart';
import 'package:namu_diary/arguments.dart';

class ViewImage extends StatelessWidget {
  static const id = 'view_image';

  @override
  Widget build(BuildContext context) {
    ViewImageArgs arguments =
        ModalRoute.of(context).settings.arguments as ViewImageArgs;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(arguments.url),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
