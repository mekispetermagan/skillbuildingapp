import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/api/authentication_api_client.dart';
import 'package:skillbuilding_game/controllers/account_flow_controller.dart';
import 'package:skillbuilding_game/models/authentication.dart';
import 'package:skillbuilding_game/models/interface_language.dart';
import 'package:skillbuilding_game/models/student.dart';
import 'package:skillbuilding_game/storage/account_store.dart';
import 'package:skillbuilding_game/storage/student_store.dart';

void main() {
  test('keeps an active learner signed in and opens games', () async {
    final account = _account(AccountRole.learner);
    final accountStore = _MemoryAccountStore(
      accounts: [StoredAccount.create(account, '123456')],
      activeId: account.accountId,
    );
    final controller = AccountFlowController(
      _FakeAuthenticationApi(account),
      accountStore: accountStore,
      studentStore: _MemoryStudentStore(),
    );

    await controller.initialize();

    expect(controller.account, account);
    expect(controller.page, AccountFlowPage.games);
  });

  test('logs in a teacher offline and persists selected students', () async {
    final account = _account(AccountRole.teacher);
    final accountStore = _MemoryAccountStore(
      accounts: [StoredAccount.create(account, '123456')],
    );
    final students = _MemoryStudentStore();
    final controller = AccountFlowController(
      _FakeAuthenticationApi(account, failIfCalled: true),
      accountStore: accountStore,
      studentStore: students,
    );

    final loggedIn = await controller.login(
      AccountCredentials(username: 'teacher', pin: '123456'),
    );
    await controller.saveStudent(
      name: 'Student One',
      location: 'Kampala',
      age: 10,
      gender: LearnerGender.female,
    );
    controller.selectStudent(controller.students.single);

    expect(loggedIn, isTrue);
    expect(controller.page, AccountFlowPage.games);
    expect(students.saved.single.name, 'Student One');
    controller.leaveGames();
    expect(controller.page, AccountFlowPage.students);
  });

  test('logs a teacher out after 60 minutes without activity', () async {
    var now = DateTime(2026, 8, 21, 10);
    final account = _account(AccountRole.teacher);
    final controller = AccountFlowController(
      _FakeAuthenticationApi(account),
      accountStore: _MemoryAccountStore(),
      studentStore: _MemoryStudentStore(),
      now: () => now,
    );
    await controller.login(
      AccountCredentials(username: 'teacher', pin: '123456'),
    );

    now = now.add(const Duration(minutes: 60));
    expect(controller.checkTeacherTimeout(), isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(controller.account, isNull);
    expect(controller.page, AccountFlowPage.welcome);
  });
}

AuthenticatedAccount _account(AccountRole role) => AuthenticatedAccount(
  accountId: role == AccountRole.learner ? 1 : 2,
  username: role.name,
  name: role == AccountRole.learner ? 'Learner One' : 'Teacher One',
  role: role,
  preferredLanguage: InterfaceLanguage.english,
  location: 'Kampala',
  age: role == AccountRole.learner ? 10 : null,
  gender: role == AccountRole.learner ? LearnerGender.male : null,
  accessToken: 'token',
);

class _FakeAuthenticationApi implements AuthenticationApi {
  final AuthenticatedAccount account;
  final bool failIfCalled;
  _FakeAuthenticationApi(this.account, {this.failIfCalled = false});

  @override
  Future<AuthenticatedAccount> login(AccountCredentials credentials) async {
    if (failIfCalled) throw StateError('API must not be called');
    return account;
  }

  @override
  Future<AuthenticatedAccount> register(
    AccountRegistration registration,
  ) async => account;

  @override
  Future<void> updatePreferredLanguage(
    String accessToken,
    InterfaceLanguage language,
  ) async {}
}

class _MemoryAccountStore implements AccountStore {
  List<StoredAccount> accounts;
  int? activeId;
  _MemoryAccountStore({this.accounts = const [], this.activeId});

  @override
  Future<List<StoredAccount>> loadAccounts() async => accounts;

  @override
  Future<void> saveAccounts(List<StoredAccount> value) async =>
      accounts = value;

  @override
  Future<int?> loadActiveAccountId() async => activeId;

  @override
  Future<void> saveActiveAccountId(int? accountId) async =>
      activeId = accountId;
}

class _MemoryStudentStore implements StudentStore {
  List<Student> saved = const [];

  @override
  Future<List<Student>> load(int teacherAccountId) async => saved;

  @override
  Future<void> save(int teacherAccountId, List<Student> students) async =>
      saved = students;
}
