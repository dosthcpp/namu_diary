import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _auth = FirebaseAuth.instance;
final _fireStore = FirebaseFirestore.instance;

class AuthProvider extends ChangeNotifier {
  String email, passwd, name, birth;
  User user;
  String currentUser;

  setEmail(String _email) {
    email = _email;
  }

  setPasswd(String _passwd) {
    passwd = _passwd;
  }

  setName(String _name) {
    name = _name;
  }

  setBirth(String _birth) {
    birth = _birth;
  }

  setUser(_user) {
    user = _user;
  }

  setCurrentUser(_currentUser) {
    currentUser = _currentUser;
  }

  clearAll() {
    email = null;
    passwd = null;
    name = null;
    birth = null;
    user = null;
    currentUser = null;
    notifyListeners();
  }

  sendEmail() async {
    try {
      user = (await _auth.createUserWithEmailAndPassword(
              email: email, password: passwd))
          .user;
      if (!user.emailVerified) {
        user.sendEmailVerification();
      } else {
        user = (await _auth.signInWithEmailAndPassword(
                email: email, password: passwd))
            .user;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        user = (await _auth.signInWithEmailAndPassword(
                email: email, password: passwd))
            .user;
      } else if (e.code == 'no-current-user') {
        print('no current user');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<String> login(willLoginPermanently) async {
    try {
      UserCredential uc = await _auth.signInWithEmailAndPassword(
        email: email,
        password: passwd,
      );
      if (willLoginPermanently) {
        final _storage = FlutterSecureStorage();
        await _storage.write(
          key: 'email',
          value: email,
        );
        await _storage.write(
          key: 'password',
          value: passwd,
        );
      }
      if (uc != null) {
        final info = await _fireStore
            .collection('/userInfo_${_auth.currentUser.email}')
            .limit(1)
            .get();
        await _fireStore
            .collection('/userInfo_${_auth.currentUser.email}')
            .doc(info.docs[0].id)
            .update({
          'lastLogin': Timestamp.fromDate(DateTime.now()),
        });
        currentUser = info.docs[0].data()['nickname'];
        return 'success';
      } else {
        return 'Unknown error!';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return '유저를 찾을 수 없습니다.';
      } else if (e.code == 'wrong-password') {
        return '비밀번호가 틀립니다.';
      }
    }
  }

  void logout() async {
    try {
      clearAll();
      await _auth.signOut();
      await FlutterSecureStorage().deleteAll();
      (await SharedPreferences.getInstance()).setBool('willLoginPermanently', false);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
