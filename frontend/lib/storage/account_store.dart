import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/authentication.dart';

class StoredAccount {
  final AuthenticatedAccount account;
  final String pinSalt;
  final String pinHash;

  const StoredAccount({
    required this.account,
    required this.pinSalt,
    required this.pinHash,
  });

  bool acceptsPin(String pin) => _hashPin(pin, pinSalt) == pinHash;

  Map<String, Object?> toJson() => {
    'account_id': account.accountId,
    'username': account.username,
    'name': account.name,
    'role': account.role.wireName,
    'preferred_language': account.preferredLanguage.wireName,
    'location': account.location,
    'age': account.age,
    'gender': account.gender?.wireName,
    'access_token': account.accessToken,
    'pin_salt': pinSalt,
    'pin_hash': pinHash,
  };

  factory StoredAccount.fromJson(Map<String, dynamic> json) => StoredAccount(
    account: AuthenticatedAccount.fromJson(json),
    pinSalt: json['pin_salt'] as String,
    pinHash: json['pin_hash'] as String,
  );

  factory StoredAccount.create(AuthenticatedAccount account, String pin) {
    final random = Random.secure();
    final salt = List<int>.generate(24, (_) => random.nextInt(256));
    final encodedSalt = base64UrlEncode(salt);
    return StoredAccount(
      account: account,
      pinSalt: encodedSalt,
      pinHash: _hashPin(pin, encodedSalt),
    );
  }
}

String _hashPin(String pin, String salt) {
  List<int> bytes = utf8.encode('$salt:$pin');
  for (var iteration = 0; iteration < 100000; iteration++) {
    bytes = sha256.convert(bytes).bytes;
  }
  return base64UrlEncode(bytes);
}

abstract interface class AccountStore {
  Future<List<StoredAccount>> loadAccounts();
  Future<void> saveAccounts(List<StoredAccount> accounts);
  Future<int?> loadActiveAccountId();
  Future<void> saveActiveAccountId(int? accountId);
}

class SharedPreferencesAccountStore implements AccountStore {
  static const _accountsKey = 'authentication_accounts_v1';
  static const _activeKey = 'authentication_active_account_v1';
  final SharedPreferencesAsync _preferences;

  SharedPreferencesAccountStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<List<StoredAccount>> loadAccounts() async {
    final encoded = await _preferences.getString(_accountsKey);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return [
        for (final item in decoded)
          StoredAccount.fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> saveAccounts(List<StoredAccount> accounts) =>
      _preferences.setString(
        _accountsKey,
        jsonEncode([for (final account in accounts) account.toJson()]),
      );

  @override
  Future<int?> loadActiveAccountId() => _preferences.getInt(_activeKey);

  @override
  Future<void> saveActiveAccountId(int? accountId) => accountId == null
      ? _preferences.remove(_activeKey)
      : _preferences.setInt(_activeKey, accountId);
}
