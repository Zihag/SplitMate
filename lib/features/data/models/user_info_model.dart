class UserInfoModel {
  final String uid;
  final String email;
  final String displayName;

  UserInfoModel({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  factory UserInfoModel.fromMap(Map<String, dynamic> map) {
    return UserInfoModel(
      uid: map['uid'],
      email: map['email'],
      displayName: map['displayName'],
    );
  }
}

