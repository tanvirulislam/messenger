// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserProfile {
  final String uid;
  final String email;
  final String fullName;
  final String nickName;
  final String phone;
  final String address;
  final DateTime dateOfBirth;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.nickName,
    required this.phone,
    required this.address,
    required this.dateOfBirth,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'nickName': nickName,
      'phone': phone,
      'address': address,
      'dateOfBirth': dateOfBirth.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      nickName: map['nickName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      dateOfBirth: DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? nickName,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      nickName: nickName ?? this.nickName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, fullName: $fullName, nickName: $nickName, phone: $phone, address: $address, dateOfBirth: $dateOfBirth, createdAt: $createdAt)';
  }
}
