import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;
  AuthBloc(this._firebaseAuth, this._firebaseFirestore)
      : super(AuthInitial()) {

    on<GoogleSignInEvent>(_onGoogleSignIn);
    on<GoogleSignOutEvent>(_onGoogleSignOut);
  }



  FutureOr<void> _onGoogleSignIn(
      GoogleSignInEvent event, Emitter<AuthState> emit) async {
    emit(GoogleSignInLoading());
    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(GoogleSignInError('Google Sign-In was cancelled'));
        return;
      }
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await _firebaseAuth.signInWithCredential(authCredential);
      User? user = userCredential.user;
      _createUserInFireStore(user!);
      await _firebaseAuth.signInWithCredential(authCredential);

      emit(GoogleAuthAuthenticated());
    } catch (e) {
      emit(GoogleSignInError(e.toString()));
    }
  }

  Future<void> _createUserInFireStore(User user) async {
    final userRef =
    FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userRef.set(({
      'uid': user.uid,
      'email': user.email,
      'created_at': FieldValue.serverTimestamp(),
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
    }));
  }

  FutureOr<void> _onGoogleSignOut(GoogleSignOutEvent event, Emitter<AuthState> emit) async {
    try {
      await GoogleSignIn().signOut(); // Sign out Google
      await _firebaseAuth.signOut();  // Sign out Firebase
      emit(AuthInitial());      // Về trạng thái ban đầu
    } catch (e) {
      emit(GoogleSignInError('Logout failed: ${e.toString()}'));
    }
  }
}