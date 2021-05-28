import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  static const id = 'test_screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Builder(
        builder: (context) => Align(
          alignment: Alignment.center,
          child: FloatingActionButton(
            onPressed: () {

            },
          ),
        ),
      ),
    );
  }
}
