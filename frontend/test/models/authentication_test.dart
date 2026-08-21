import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/models/authentication.dart';
import 'package:skillbuilding_game/models/interface_language.dart';

void main() {
  test('normalizes credentials and serializes account registration', () {
    final registration = AccountRegistration(
      username: 'Teacher.One',
      pin: '123456',
      name: 'Teacher One',
      role: AccountRole.teacher,
      preferredLanguage: InterfaceLanguage.hungarian,
      location: ' Budapest ',
    );

    expect(registration.toJson(), {
      'username': 'teacher.one',
      'pin': '123456',
      'name': 'Teacher One',
      'role': 'teacher',
      'preferred_language': 'hu',
      'location': 'Budapest',
      'age': null,
      'gender': null,
    });
    expect(registration.role.inactivityTimeout, const Duration(minutes: 60));
    expect(AccountRole.learner.inactivityTimeout, isNull);
  });

  test('requires age and gender only for learners', () {
    final learner = AccountRegistration(
      username: 'learner',
      pin: '123456',
      name: 'Learner One',
      role: AccountRole.learner,
      preferredLanguage: InterfaceLanguage.english,
      location: 'Kampala',
      age: 9,
      gender: LearnerGender.otherOrPreferNotToSay,
    );

    expect(learner.age, 9);
    expect(learner.gender, LearnerGender.otherOrPreferNotToSay);
    expect(
      () => AccountRegistration(
        username: 'learner',
        pin: '123456',
        name: 'Learner One',
        role: AccountRole.learner,
        preferredLanguage: InterfaceLanguage.english,
        location: 'Kampala',
      ),
      throwsArgumentError,
    );
  });

  test('requires a valid username and exactly six PIN digits', () {
    expect(
      () => AccountCredentials(username: 'ab', pin: '123456'),
      throwsArgumentError,
    );
    expect(
      () => AccountCredentials(username: 'learner', pin: '12345x'),
      throwsArgumentError,
    );
  });

  test('parses an authenticated account', () {
    final account = AuthenticatedAccount.fromJson({
      'account_id': 7,
      'username': 'learner',
      'name': 'Learner One',
      'role': 'learner',
      'preferred_language': 'en',
      'location': 'Kampala',
      'age': 10,
      'gender': 'female',
      'access_token': 'opaque-token',
    });

    expect(account.accountId, 7);
    expect(account.role, AccountRole.learner);
    expect(account.preferredLanguage, InterfaceLanguage.english);
    expect(account.age, 10);
    expect(account.gender, LearnerGender.female);
    expect(account.accessToken, 'opaque-token');
  });
}
