import 'package:flutter/material.dart';

const kMainColor = 0xff62b27c;

final kTextSubStyle = TextStyle(
  color: Colors.black54,
  fontSize: 12.0,
);

const kBorderRadiusIfIsMe = BorderRadius.only(
  topLeft: Radius.circular(20.0),
  topRight: Radius.circular(20.0),
  bottomLeft: Radius.circular(20.0),
);

const kBorderRadiusIfIsNotMe = BorderRadius.only(
  topRight: Radius.circular(20.0),
  topLeft: Radius.circular(20.0),
  bottomRight: Radius.circular(20.0),
);

const kMessageTextFieldDecoration = InputDecoration(
    contentPadding: EdgeInsets.symmetric(
      vertical: 5.0,
      horizontal: 10.0,
    ),
    hintText: 'Type your message here...',
    border: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.blue,
        )
    )
);