import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int selectedIdx;
  final Function onTap;

  CustomBottomNavigationBar({this.selectedIdx, this.onTap});

  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: widget.selectedIdx,
      onTap: widget.onTap,
      items: [
        BottomNavigationBarItem(
          activeIcon: Image.asset(
            'assets/feed.png',
            width: 25.0,
          ),
          icon: Image.asset(
            'assets/feed_unselected.png',
            width: 25.0,
          ),
          label: '피드',
        ),
        BottomNavigationBarItem(
          activeIcon: Image.asset(
            'assets/bottom_plus.png',
            width: 25.0,
          ),
          icon: Image.asset(
            'assets/bottom_plus_unselected.png',
            width: 25.0,
          ),
          label: '업로드',
        ),
        BottomNavigationBarItem(
          activeIcon: Image.asset(
            'assets/bottom_alarm.png',
            width: 27.0,
          ),
          icon: Image.asset(
            'assets/bottom_alarm_unselected.png',
            width: 25.0,
          ),
          label: '알림',
        ),
        BottomNavigationBarItem(
          activeIcon: Image.asset(
            'assets/chat.png',
            width: 25.0,
          ),
          icon: Image.asset(
            'assets/chat_unselected.png',
            width: 25.0,
          ),
          label: '채팅',
        ),
        BottomNavigationBarItem(
          activeIcon: Image.asset(
            'assets/bottom_profile.png',
            width: 23.0,
          ),
          icon: Image.asset(
            'assets/bottom_profile_unselected.png',
            width: 23.0,
          ),
          label: '프로필',
        ),
      ],
    );
  }
}
