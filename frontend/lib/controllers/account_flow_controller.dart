import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/authentication_api_client.dart';
import '../api/gameplay_api_client.dart';
import '../api/student_api_client.dart';
import '../models/authentication.dart';
import '../models/student.dart';
import '../storage/account_store.dart';
import '../storage/student_store.dart';

enum AccountFlowPage {
  opening,
  welcome,
  login,
  register,
  students,
  studentForm,
  games,
}

class AccountFlowController extends ChangeNotifier {
  final AuthenticationApi _api;
  final AccountStore _accountStore;
  final StudentStore _studentStore;
  final StudentApi? _studentApi;
  final DateTime Function() _now;

  AccountFlowPage page = AccountFlowPage.opening;
  AuthenticatedAccount? account;
  List<Student> students = const [];
  Student? editingStudent;
  Student? selectedStudent;
  String? errorMessage;
  bool busy = false;
  DateTime? _lastTeacherActivity;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  factory AccountFlowController(
    AuthenticationApi api, {
    AccountStore? accountStore,
    StudentStore? studentStore,
    StudentApi? studentApi,
    DateTime Function()? now,
  }) => AccountFlowController._(
    api,
    studentApi,
    accountStore: accountStore,
    studentStore: studentStore,
    now: now,
  );

  AccountFlowController._(
    this._api,
    this._studentApi, {
    AccountStore? accountStore,
    StudentStore? studentStore,
    DateTime Function()? now,
  }) : _accountStore = accountStore ?? SharedPreferencesAccountStore(),
       _studentStore = studentStore ?? SharedPreferencesStudentStore(),
       _now = now ?? DateTime.now;

  Future<void> initialize() async {
    final accounts = await _accountStore.loadAccounts();
    final activeId = await _accountStore.loadActiveAccountId();
    StoredAccount? active;
    for (final candidate in accounts) {
      if (candidate.account.accountId == activeId) active = candidate;
    }
    if (active?.account.role == AccountRole.learner) {
      account = active!.account;
      page = AccountFlowPage.games;
    }
    notifyListeners();
  }

  void start() => _open(AccountFlowPage.welcome);
  void showLogin() => _open(AccountFlowPage.login);
  void showRegistration() => _open(AccountFlowPage.register);

  Future<bool> register(AccountRegistration registration) async {
    return _run(() async {
      final authenticated = await _api.register(registration);
      await _cacheAccount(authenticated, registration.pin);
      await _enterAccount(authenticated);
    });
  }

  Future<bool> login(AccountCredentials credentials) async {
    final lockedUntil = _lockedUntil;
    if (lockedUntil != null && _now().isBefore(lockedUntil)) {
      errorMessage = 'Too many incorrect attempts. Please try again later.';
      notifyListeners();
      return false;
    }
    return _run(() async {
      final cached = await _accountStore.loadAccounts();
      StoredAccount? local;
      for (final candidate in cached) {
        if (candidate.account.username == credentials.username) {
          local = candidate;
        }
      }
      final authenticated = local?.acceptsPin(credentials.pin) == true
          ? local!.account
          : await _api.login(credentials);
      await _cacheAccount(authenticated, credentials.pin);
      _failedAttempts = 0;
      _lockedUntil = null;
      await _enterAccount(authenticated);
    }, onFailure: _recordFailedAttempt);
  }

  Future<void> _enterAccount(AuthenticatedAccount authenticated) async {
    account = authenticated;
    await _accountStore.saveActiveAccountId(authenticated.accountId);
    if (authenticated.role == AccountRole.learner) {
      page = AccountFlowPage.games;
    } else {
      _lastTeacherActivity = _now();
      students = await _studentStore.load(authenticated.accountId);
      await _synchronizeStudents(authenticated);
      page = AccountFlowPage.students;
    }
  }

  Future<void> _cacheAccount(
    AuthenticatedAccount authenticated,
    String pin,
  ) async {
    final accounts = [...await _accountStore.loadAccounts()]
      ..removeWhere(
        (stored) => stored.account.accountId == authenticated.accountId,
      )
      ..add(StoredAccount.create(authenticated, pin));
    await _accountStore.saveAccounts(accounts);
  }

  Future<bool> _run(
    Future<void> Function() action, {
    VoidCallback? onFailure,
  }) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on Object catch (error) {
      if (error is GameplayApiException && error.statusCode == 401) {
        onFailure?.call();
      }
      errorMessage = error is GameplayApiException
          ? error.message
          : 'Unable to complete authentication.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _recordFailedAttempt() {
    _failedAttempts++;
    final delay = switch (_failedAttempts) {
      <= 3 => Duration.zero,
      4 => const Duration(seconds: 30),
      5 => const Duration(minutes: 2),
      _ => const Duration(minutes: 10),
    };
    _lockedUntil = delay == Duration.zero ? null : _now().add(delay);
  }

  void addStudent() {
    editingStudent = null;
    _touchTeacher();
    _open(AccountFlowPage.studentForm);
  }

  void editStudent(Student student) {
    editingStudent = student;
    _touchTeacher();
    _open(AccountFlowPage.studentForm);
  }

  Future<void> saveStudent({
    required String name,
    required String location,
    required int age,
    required LearnerGender gender,
  }) async {
    final teacher = account;
    if (teacher == null || teacher.role != AccountRole.teacher) return;
    final student = editingStudent == null
        ? Student.create(
            name: name,
            location: location,
            age: age,
            gender: gender,
          )
        : Student(
            id: editingStudent!.id,
            name: name,
            location: location,
            age: age,
            gender: gender,
          );
    final updated = [...students];
    final index = updated.indexWhere((item) => item.id == student.id);
    if (index < 0) {
      updated.add(student);
    } else {
      updated[index] = student;
    }
    students = List.unmodifiable(updated);
    await _studentStore.save(teacher.accountId, students);
    await _synchronizeStudents(teacher);
    editingStudent = null;
    _touchTeacher();
    _open(AccountFlowPage.students);
  }

  Future<void> _synchronizeStudents(AuthenticatedAccount teacher) async {
    final api = _studentApi;
    if (api == null) return;
    try {
      final remote = students.isEmpty
          ? await api.list(teacher.accessToken)
          : await api.synchronize(teacher.accessToken, students);
      students = List.unmodifiable(remote);
      await _studentStore.save(teacher.accountId, students);
    } on Object {
      // Local student management remains available while offline.
    }
  }

  Future<void> synchronizeStudents() async {
    final current = account;
    if (current?.role == AccountRole.teacher) {
      await _synchronizeStudents(current!);
    }
  }

  void selectStudent(Student student) {
    selectedStudent = student;
    _touchTeacher();
    _open(AccountFlowPage.games);
  }

  void leaveGames() {
    if (account?.role == AccountRole.teacher) {
      selectedStudent = null;
      _touchTeacher();
      _open(AccountFlowPage.students);
    }
  }

  Future<void> logout() async {
    account = null;
    selectedStudent = null;
    students = const [];
    _lastTeacherActivity = null;
    await _accountStore.saveActiveAccountId(null);
    _open(AccountFlowPage.welcome);
  }

  bool checkTeacherTimeout() {
    final last = _lastTeacherActivity;
    if (account?.role != AccountRole.teacher || last == null) return false;
    if (_now().difference(last) < const Duration(minutes: 60)) return false;
    unawaited(logout());
    return true;
  }

  void recordActivity() => _touchTeacher();

  void back() {
    switch (page) {
      case AccountFlowPage.login || AccountFlowPage.register:
        _open(AccountFlowPage.welcome);
      case AccountFlowPage.studentForm:
        editingStudent = null;
        _open(AccountFlowPage.students);
      case AccountFlowPage.welcome:
        _open(AccountFlowPage.opening);
      default:
        break;
    }
  }

  void _touchTeacher() {
    if (account?.role == AccountRole.teacher) _lastTeacherActivity = _now();
  }

  void _open(AccountFlowPage value) {
    page = value;
    errorMessage = null;
    notifyListeners();
  }
}
