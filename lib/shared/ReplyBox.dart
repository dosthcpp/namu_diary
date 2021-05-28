import 'package:flutter/material.dart';
import 'package:namu_diary/shared/ProfileImage.dart';
import 'package:namu_diary/utils.dart';

class ReplyBox extends StatefulWidget {
  final String content, type, user;
  final Function onTapReply;
  final DateTime date;
  bool isInside = false;
  bool isMyReply = false;
  final Function onTapDelete;

  ReplyBox(
      {this.content,
      this.onTapReply,
      this.isInside,
      this.type,
      this.user,
      this.date,
      this.isMyReply,
      this.onTapDelete});

  @override
  _ReplyBoxState createState() => _ReplyBoxState();
}

class _ReplyBoxState extends State<ReplyBox> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 35.0,
              height: 35.0,
              child: InkWell(
                child: profileImage(
                  widget.user,
                  100.0,
                ),
                onTap: () {
                  showBottomModal(context, widget.user, false);
                },
              ),
            ),
            SizedBox(
              width: 10.0,
            ),
            Text(
              widget.user,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
            SizedBox(
              width: 15.0,
            ),
            Text(
              widget.content,
              style: TextStyle(
                fontSize: 12.0,
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 5.0,
            left: 45.0,
          ),
          child: Row(
            children: [
              Text(
                "${widget.date.month}.${widget.date.day}",
                style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.black54,
                ),
              ),
              SizedBox(
                width: 25.0,
              ),
              widget.isInside
                  ? Container()
                  : InkWell(
                      child: Text(
                        "답글",
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.black54,
                        ),
                      ),
                      onTap: () {
                        widget.onTapReply(widget.user, widget.content);
                      },
                    ),
              widget.isMyReply
                  ? Row(
                      children: [
                        SizedBox(
                          width: 25.0,
                        ),
                        InkWell(
                          child: Text(
                            "삭제",
                            style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.black54,
                            ),
                          ),
                          onTap: widget.onTapDelete,
                        )
                      ],
                    )
                  : Container()
            ],
          ),
        ),
      ],
    );
  }
}
