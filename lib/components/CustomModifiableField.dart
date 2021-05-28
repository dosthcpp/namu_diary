import 'package:flutter/material.dart';

class CustomModifiableField extends StatelessWidget {
  final BuildContext ctx;
  final String initVal;
  final Function onChanged;
  bool init = false;

  CustomModifiableField({
    this.ctx,
    this.initVal,
    this.onChanged,
    this.init,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.85,
            height: 200.0,
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
              onChanged: onChanged,
              initialValue: initVal,
              style: TextStyle(
                fontSize: 15.0,
              ),
              maxLines: 10,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 10.0,
                ),
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
    );
  }
}