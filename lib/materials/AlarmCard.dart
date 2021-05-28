import 'package:flutter/material.dart';
import 'package:namu_diary/shared/ProfileImage.dart';

class AlarmCard extends StatelessWidget {
  final firstText, secondText, finalText, sender;
  final DateTime time;

  AlarmCard(
      {this.firstText,
        this.secondText,
        this.finalText,
        this.time,
        this.sender});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              profileImage(
                sender,
                40.0,
              ),
              SizedBox(
                width: 10.0,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 10 * 7.5,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text.rich(
                    TextSpan(
                      text: firstText,
                      style: TextStyle(
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: secondText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: finalText,
                          style: TextStyle(
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 60.0,
            ),
            child: Text(
              "${time.year}년 ${time.month}월 ${time.day}일 ${time.hour >= 12 ? "오후 ${time.hour == 12 ? time.hour : time.hour - 12}시" : "오전 ${time.hour}시"} ${time.minute}분",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 10.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}