import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:namu_diary/main.dart';

final _store = FirebaseFirestore.instance;

class UserProvider extends ChangeNotifier {
  String currentUser;
  String currentEmail;
  String currentGarden;

  getEmail(user) async {
    return (await _store
        .collection('/userList')
        .where('username', isEqualTo: user)
        .limit(1)
        .get())
        .docs[0]
        .data()['email'];
  }

  setCurrentUser(user) async {
    currentUser = user;
    currentEmail = await getEmail(user);
    notifyListeners();
  }

  setCurrentGarden(garden) {
    currentGarden = garden;
    notifyListeners();
  }

  follow(followUser) async {
    try {
      final followUserEmail = (await _store
              .collection('/userList')
              .where('username', isEqualTo: followUser)
              .limit(1)
              .get())
          .docs[0]
          .data()['email'];

      final snap =
          await _store.collection('/userInfo_$currentEmail').limit(1).get();
      final followingList = List.from(snap.docs[0].data()['following']);
      final snap2 =
          await _store.collection('/userInfo_$followUserEmail').limit(1).get();
      final followerList = List.from(snap2.docs[0].data()['follower']);
      final alreadyFollowed =
          followingList.where((el) => el == followUser).toList().length == 1 &&
              followerList.where((el) => el == currentUser).toList().length == 1;
      if(alreadyFollowed) {
        followingList.removeWhere((el) => el == followUser);
        followerList.removeWhere((el) => el == currentUser);
      }
      await _store
          .collection('/userInfo_$currentEmail')
          .doc(snap.docs[0].id)
          .update({
        'following': alreadyFollowed
            ? followingList
            : [followUser, ...followingList].toSet().toList(),
      });
      await _store
          .collection('/userInfo_$followUserEmail')
          .doc(snap2.docs[0].id)
          .update({
        'follower': alreadyFollowed
            ? followerList
            : [currentUser, ...followerList].toSet().toList(),
      });
      if(alreadyFollowed) {
        return 'unfollow';
      } else {
        return 'follow';
      }
    } catch (e) {
      print(e);
    }
  }
}
