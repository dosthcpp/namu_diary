import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 5.0,
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: Container(
        child: OverflowBox(
          minWidth: 0.0,
          minHeight: 0.0,
          maxWidth: 20.0,
          child: Image.asset(
            'assets/icon.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(3.0),
        ),
        height: 35.0,
        child: Row(
          children: [
            Expanded(
              child: Icon(
                Icons.search,
                color: Colors.black54,
              ),
            ),
            Expanded(
              flex: 9,
              child: Transform(
                transform: Matrix4.translationValues(0, -7, 0),
                child: TextField(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Image.asset(
          'assets/settings.png',
          scale: 3.0,
        )
      ],
    );
  }
}