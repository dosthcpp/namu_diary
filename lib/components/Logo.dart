import 'package:flutter/material.dart';

class TreeiumLogo extends StatelessWidget {

  final double fontSize;
  final Color color;

  TreeiumLogo({this.fontSize, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 5.0,
          horizontal: 8.0,
        ),
        child: Text(
          "treeium".toUpperCase(),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
