import 'package:flutter/material.dart';
import 'package:namu_diary/main.dart';

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

class CustomTextField extends StatelessWidget {
  final BuildContext ctx;
  final String label;
  final double size;
  final double height;
  final Function onChanged;
  final TextEditingController controller;
  bool useMaxline = false;
  bool init = false;
  bool disabled = false;

  CustomTextField({
    this.ctx,
    this.label,
    this.size,
    this.height,
    this.onChanged,
    this.controller,
    this.useMaxline,
    this.init,
    this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.of(ctx).size.width / 10 * 1.5,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w200,
                fontSize: 18.0,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 20.0,
        ),
        Container(
          width: MediaQuery.of(ctx).size.width / 10 * 7,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              8.0,
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(
                  0,
                  2,
                ),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 15.0,
            ),
            maxLines: useMaxline ? null : 1,
            focusNode: disabled ? AlwaysDisabledFocusNode() : null,
            initialValue: init == true ? userProvider.currentUser : null,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.0,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}