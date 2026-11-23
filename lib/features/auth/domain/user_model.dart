/// Domain representation of an authenticated user profile.
class UserModel {
  final String uid;
  final String email;
  final DateTime createdAt;
  final String? displayName;

  const UserModel({
    required this.uid,
    required this.email,
    required this.createdAt,
    this.displayName,
  });

  /// Factory constructor to deserialize a Firestore document map.
  factory UserModel.fromMap(Map<String, dynamic> map, {required String uid}) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      createdAt: parsedCreatedAt,
      displayName: map['displayName'] as String?,
    );
  }

  /// Converts the domain user model into a Firestore map representation.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'displayName': displayName,
    };
  }

  /// Creates a copy of [UserModel] with specified properties replaced.
  UserModel copyWith({
    String? uid,
    String? email,
    DateTime? createdAt,
    String? displayName,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          createdAt == other.createdAt &&
          displayName == other.displayName;

  @override
  int get hashCode =>
      uid.hashCode ^ email.hashCode ^ createdAt.hashCode ^ displayName.hashCode;

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, createdAt: $createdAt, displayName: $displayName)';
}
