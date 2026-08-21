import 'interface_language.dart';

enum AccountRole {
  learner('learner'),
  teacher('teacher');

  final String wireName;

  const AccountRole(this.wireName);

  Duration? get inactivityTimeout => switch (this) {
    AccountRole.learner => null,
    AccountRole.teacher => const Duration(minutes: 60),
  };

  static AccountRole fromWireName(String value) => values.firstWhere(
    (role) => role.wireName == value,
    orElse: () => throw FormatException('Unknown account role: $value'),
  );
}

enum LearnerGender {
  male('male'),
  female('female'),
  otherOrPreferNotToSay('other_or_prefer_not_to_say');

  final String wireName;

  const LearnerGender(this.wireName);

  static LearnerGender fromWireName(String value) => values.firstWhere(
    (gender) => gender.wireName == value,
    orElse: () => throw FormatException('Unknown learner gender: $value'),
  );
}

class AccountCredentials {
  final String username;
  final String pin;

  AccountCredentials({required String username, required this.pin})
    : username = username.toLowerCase() {
    if (!RegExp(r'^[A-Za-z0-9_.-]{3,32}$').hasMatch(username)) {
      throw ArgumentError.value(username, 'username', 'Invalid username');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError.value(pin, 'pin', 'Must contain exactly six digits');
    }
  }

  Map<String, Object?> toJson() => {'username': username, 'pin': pin};
}

class AccountRegistration extends AccountCredentials {
  final String name;
  final AccountRole role;
  final InterfaceLanguage preferredLanguage;
  final String location;
  final int? age;
  final LearnerGender? gender;

  AccountRegistration({
    required super.username,
    required super.pin,
    required String name,
    required this.role,
    required this.preferredLanguage,
    required String location,
    this.age,
    this.gender,
  }) : name = name.trim(),
       location = location.trim() {
    if (this.name.isEmpty || this.name.length > 100) {
      throw ArgumentError.value(name, 'name', 'Must be 1–100 characters');
    }
    if (this.location.isEmpty || this.location.length > 100) {
      throw ArgumentError.value(
        location,
        'location',
        'Must be 1–100 characters',
      );
    }
    if (role == AccountRole.learner) {
      if (age == null || age! < 1 || age! > 120 || gender == null) {
        throw ArgumentError('Learner accounts require valid age and gender.');
      }
    } else if (age != null || gender != null) {
      throw ArgumentError('Teacher accounts must not include age or gender.');
    }
  }

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'name': name,
    'role': role.wireName,
    'preferred_language': preferredLanguage.wireName,
    'location': location,
    'age': age,
    'gender': gender?.wireName,
  };
}

class AuthenticatedAccount {
  final int accountId;
  final String username;
  final String name;
  final AccountRole role;
  final InterfaceLanguage preferredLanguage;
  final String location;
  final int? age;
  final LearnerGender? gender;
  final String accessToken;

  const AuthenticatedAccount({
    required this.accountId,
    required this.username,
    required this.name,
    required this.role,
    required this.preferredLanguage,
    required this.location,
    required this.age,
    required this.gender,
    required this.accessToken,
  });

  factory AuthenticatedAccount.fromJson(Map<String, dynamic> json) {
    final accountId = json['account_id'];
    final username = json['username'];
    final name = json['name'];
    final role = json['role'];
    final preferredLanguage = json['preferred_language'];
    final location = json['location'];
    final age = json['age'];
    final gender = json['gender'];
    final accessToken = json['access_token'];
    if (accountId is! int || accountId <= 0) {
      throw const FormatException('account_id must be a positive integer.');
    }
    if (username is! String ||
        username.isEmpty ||
        name is! String ||
        name.isEmpty) {
      throw const FormatException(
        'username and name must be non-empty strings.',
      );
    }
    if (role is! String ||
        preferredLanguage is! String ||
        location is! String ||
        location.isEmpty ||
        (age != null && age is! int) ||
        (gender != null && gender is! String) ||
        accessToken is! String ||
        accessToken.isEmpty) {
      throw const FormatException('Invalid authentication response.');
    }
    return AuthenticatedAccount(
      accountId: accountId,
      username: username,
      name: name,
      role: AccountRole.fromWireName(role),
      preferredLanguage: InterfaceLanguage.fromWireName(preferredLanguage),
      location: location,
      age: age as int?,
      gender: gender == null ? null : LearnerGender.fromWireName(gender),
      accessToken: accessToken,
    );
  }
}
