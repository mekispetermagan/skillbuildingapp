import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/authentication_api_client.dart';
import '../api/gameplay_api_client.dart';
import '../api/student_api_client.dart';
import '../api/student_group_api_client.dart';
import '../models/authentication.dart';
import '../models/interface_language.dart';
import '../models/student.dart';
import '../models/student_group.dart';
import '../storage/account_store.dart';
import '../storage/student_store.dart';
import '../storage/student_group_store.dart';

enum AccountFlowPage {
  opening,
  welcome,
  login,
  register,
  students,
  studentForm,
  groupForm,
  groupStudents,
  groupAddStudents,
  groupJoin,
  language,
  games,
}

class AccountFlowController extends ChangeNotifier {
  final AuthenticationApi _api;
  final AccountStore _accountStore;
  final StudentStore _studentStore;
  final StudentGroupStore _groupStore;
  final StudentApi? _studentApi;
  final StudentGroupApi? _groupApi;
  final DateTime Function() _now;

  AccountFlowPage page = AccountFlowPage.opening;
  AuthenticatedAccount? account;
  List<Student> students = const [];
  List<StudentGroup> groups = const [];
  Student? editingStudent;
  StudentGroup? editingGroup;
  StudentGroup? selectedGroup;
  Student? selectedStudent;
  String? errorMessage;
  bool busy = false;
  DateTime? _lastTeacherActivity;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  AccountFlowPage? _pageBeforeLanguage;
  AccountFlowPage _studentFormReturnPage = AccountFlowPage.students;
  String? _studentCreationGroupId;
  AccountFlowPage _gamesReturnPage = AccountFlowPage.students;

  factory AccountFlowController(
    AuthenticationApi api, {
    AccountStore? accountStore,
    StudentStore? studentStore,
    StudentApi? studentApi,
    StudentGroupStore? groupStore,
    StudentGroupApi? groupApi,
    DateTime Function()? now,
  }) => AccountFlowController._(
    api,
    studentApi,
    groupApi,
    accountStore: accountStore,
    studentStore: studentStore,
    groupStore: groupStore,
    now: now,
  );

  AccountFlowController._(
    this._api,
    this._studentApi,
    this._groupApi, {
    AccountStore? accountStore,
    StudentStore? studentStore,
    StudentGroupStore? groupStore,
    DateTime Function()? now,
  }) : _accountStore = accountStore ?? SharedPreferencesAccountStore(),
       _studentStore = studentStore ?? SharedPreferencesStudentStore(),
       _groupStore = groupStore ?? SharedPreferencesStudentGroupStore(),
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

  void showLanguage() {
    _pageBeforeLanguage = page;
    _open(AccountFlowPage.language);
  }

  Future<void> changeLanguage(InterfaceLanguage language) async {
    final current = account;
    if (current == null) return;
    final updated = current.withPreferredLanguage(language);
    account = updated;
    final accounts = [...await _accountStore.loadAccounts()];
    final index = accounts.indexWhere(
      (stored) => stored.account.accountId == updated.accountId,
    );
    if (index >= 0) {
      final stored = accounts[index];
      accounts[index] = StoredAccount(
        account: updated,
        pinSalt: stored.pinSalt,
        pinHash: stored.pinHash,
      );
      await _accountStore.saveAccounts(accounts);
    }
    try {
      await _api.updatePreferredLanguage(updated.accessToken, language);
    } on Object {
      // The local preference remains authoritative while offline.
    }
    final destination = _pageBeforeLanguage ?? _homePageFor(updated);
    _pageBeforeLanguage = null;
    _open(destination);
  }

  void closeLanguage() {
    final current = account;
    final destination =
        _pageBeforeLanguage ??
        (current == null ? AccountFlowPage.welcome : _homePageFor(current));
    _pageBeforeLanguage = null;
    _open(destination);
  }

  AccountFlowPage _homePageFor(AuthenticatedAccount value) =>
      value.role == AccountRole.learner
      ? AccountFlowPage.games
      : AccountFlowPage.students;

  Future<void> synchronizeAccountPreferences() async {
    final current = account;
    if (current == null) return;
    try {
      await _api.updatePreferredLanguage(
        current.accessToken,
        current.preferredLanguage,
      );
    } on Object {
      // Retry during the next periodic synchronization.
    }
  }

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
      students = [
        for (final student in students)
          student.withOwnerAccountId(authenticated.accountId),
      ];
      groups = await _groupStore.load(authenticated.accountId);
      await _synchronizeTeacherData(authenticated);
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

  List<Student> get ungroupedStudents {
    final groupedIds = {for (final group in groups) ...group.studentIds};
    return List.unmodifiable(
      students.where((student) => !groupedIds.contains(student.id)),
    );
  }

  List<Student> get selectedGroupStudents {
    final memberIds = selectedGroup?.studentIds.toSet() ?? const <String>{};
    return List.unmodifiable(
      students.where((student) => memberIds.contains(student.id)),
    );
  }

  List<Student> get studentsOutsideSelectedGroup {
    final memberIds = selectedGroup?.studentIds.toSet() ?? const <String>{};
    return List.unmodifiable(
      students.where((student) => !memberIds.contains(student.id)),
    );
  }

  void addStudent({String? groupId}) {
    editingStudent = null;
    _studentCreationGroupId = groupId;
    _studentFormReturnPage = groupId == null
        ? AccountFlowPage.students
        : AccountFlowPage.groupStudents;
    _touchTeacher();
    _open(AccountFlowPage.studentForm);
  }

  void editStudent(Student student) {
    editingStudent = student;
    _studentCreationGroupId = null;
    _studentFormReturnPage = selectedGroup == null
        ? AccountFlowPage.students
        : AccountFlowPage.groupStudents;
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
            ownerAccountId: teacher.accountId,
          )
        : Student(
            id: editingStudent!.id,
            name: name,
            location: location,
            age: age,
            gender: gender,
            ownerAccountId: editingStudent!.ownerAccountId,
            pendingChanges: true,
          );
    final updated = [...students];
    final index = updated.indexWhere((item) => item.id == student.id);
    if (index < 0) {
      updated.add(student);
    } else {
      updated[index] = student;
    }
    students = List.unmodifiable(updated);
    final creationGroupId = _studentCreationGroupId;
    if (editingStudent == null && creationGroupId != null) {
      groups = List.unmodifiable([
        for (final group in groups)
          group.id == creationGroupId
              ? group.copyWith(studentIds: [...group.studentIds, student.id])
              : group,
      ]);
      selectedGroup = groups.singleWhere(
        (group) => group.id == creationGroupId,
      );
      await _groupStore.save(teacher.accountId, groups);
    }
    await _studentStore.save(teacher.accountId, students);
    await _synchronizeTeacherData(teacher);
    editingStudent = null;
    _studentCreationGroupId = null;
    _touchTeacher();
    _open(_studentFormReturnPage);
  }

  Future<void> _synchronizeStudents(AuthenticatedAccount teacher) async {
    final api = _studentApi;
    if (api == null) return;
    try {
      final pending = students
          .where((student) => student.pendingChanges)
          .toList();
      final remote = pending.isEmpty
          ? await api.list(teacher.accessToken)
          : await api.synchronize(teacher.accessToken, pending);
      students = List.unmodifiable(remote);
      await _studentStore.save(teacher.accountId, students);
    } on Object {
      // Local student management remains available while offline.
    }
  }

  Future<void> _synchronizeGroups(AuthenticatedAccount teacher) async {
    final api = _groupApi;
    if (api == null) return;
    try {
      final pending = groups.where((group) => group.pendingChanges).toList();
      final remote = pending.isEmpty
          ? await api.list(teacher.accessToken)
          : await api.synchronize(teacher.accessToken, pending);
      groups = List.unmodifiable(remote);
      final selectedId = selectedGroup?.id;
      selectedGroup = selectedId == null
          ? null
          : groups.where((group) => group.id == selectedId).firstOrNull;
      await _groupStore.save(teacher.accountId, groups);
    } on Object {
      // Local group management remains available while offline.
    }
  }

  Future<void> _synchronizeTeacherData(AuthenticatedAccount teacher) async {
    await _synchronizeStudents(teacher);
    await _synchronizeGroups(teacher);
    await _synchronizeStudents(teacher);
  }

  Future<void> synchronizeStudents() async {
    final current = account;
    if (current?.role == AccountRole.teacher) {
      await _synchronizeTeacherData(current!);
    }
  }

  void selectStudent(Student student) {
    selectedStudent = student;
    _gamesReturnPage = selectedGroup == null
        ? AccountFlowPage.students
        : AccountFlowPage.groupStudents;
    _touchTeacher();
    _open(AccountFlowPage.games);
  }

  void leaveGames() {
    if (account?.role == AccountRole.teacher) {
      selectedStudent = null;
      _touchTeacher();
      _open(_gamesReturnPage);
    }
  }

  void addGroup() {
    editingGroup = null;
    selectedGroup = null;
    _touchTeacher();
    _open(AccountFlowPage.groupForm);
  }

  void editSelectedGroup() {
    editingGroup = selectedGroup;
    _touchTeacher();
    _open(AccountFlowPage.groupForm);
  }

  Future<void> saveGroup(String name) async {
    final teacher = account;
    if (teacher == null || teacher.role != AccountRole.teacher) return;
    final group = editingGroup == null
        ? StudentGroup.create(name: name, ownerAccountId: teacher.accountId)
        : editingGroup!.copyWith(name: name);
    final updated = [...groups];
    final index = updated.indexWhere((item) => item.id == group.id);
    if (index < 0) {
      updated.add(group);
    } else {
      updated[index] = group;
    }
    groups = List.unmodifiable(updated);
    selectedGroup = group;
    await _groupStore.save(teacher.accountId, groups);
    await _synchronizeGroups(teacher);
    editingGroup = null;
    _touchTeacher();
    _open(AccountFlowPage.groupStudents);
  }

  void openGroup(StudentGroup group) {
    selectedGroup = group;
    _touchTeacher();
    _open(AccountFlowPage.groupStudents);
  }

  void showAddStudentsToGroup() {
    _touchTeacher();
    _open(AccountFlowPage.groupAddStudents);
  }

  Future<void> addStudentsToSelectedGroup(Set<String> studentIds) async {
    final teacher = account;
    final group = selectedGroup;
    if (teacher == null || group == null) return;
    await _replaceGroup(
      teacher,
      group.copyWith(studentIds: {...group.studentIds, ...studentIds}),
    );
    _open(AccountFlowPage.groupStudents);
  }

  Future<void> removeStudentFromSelectedGroup(Student student) async {
    final teacher = account;
    final group = selectedGroup;
    if (teacher == null || group == null) return;
    await _replaceGroup(
      teacher,
      group.copyWith(
        studentIds: group.studentIds.where((id) => id != student.id),
      ),
    );
  }

  Future<void> _replaceGroup(
    AuthenticatedAccount teacher,
    StudentGroup updatedGroup,
  ) async {
    groups = List.unmodifiable([
      for (final group in groups)
        if (group.id == updatedGroup.id) updatedGroup else group,
    ]);
    selectedGroup = updatedGroup;
    await _groupStore.save(teacher.accountId, groups);
    await _synchronizeGroups(teacher);
    await _synchronizeStudents(teacher);
    _touchTeacher();
    notifyListeners();
  }

  void showJoinGroup() => _open(AccountFlowPage.groupJoin);

  Future<bool> joinGroup(String code) async {
    final teacher = account;
    final api = _groupApi;
    if (teacher == null || api == null) {
      errorMessage = 'Connecting to the server is required to join a group.';
      notifyListeners();
      return false;
    }
    return _run(() async {
      final joined = await api.join(teacher.accessToken, code.trim());
      groups = List.unmodifiable([
        ...groups.where((group) => group.id != joined.id),
        joined,
      ]);
      selectedGroup = joined;
      await _groupStore.save(teacher.accountId, groups);
      await _synchronizeTeacherData(teacher);
      page = AccountFlowPage.groupStudents;
    });
  }

  Future<String?> generateSelectedGroupShareCode() async {
    final teacher = account;
    final group = selectedGroup;
    final api = _groupApi;
    if (teacher == null || group == null || api == null || !group.isOwner) {
      errorMessage = 'Only the group owner can generate a sharing code.';
      notifyListeners();
      return null;
    }
    String? code;
    final succeeded = await _run(() async {
      await _synchronizeGroups(teacher);
      code = await api.generateShareCode(teacher.accessToken, group.id);
    });
    return succeeded ? code : null;
  }

  Future<void> logout() async {
    account = null;
    selectedStudent = null;
    students = const [];
    groups = const [];
    selectedGroup = null;
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
        _studentCreationGroupId = null;
        _open(_studentFormReturnPage);
      case AccountFlowPage.groupForm:
        editingGroup = null;
        _open(
          selectedGroup == null
              ? AccountFlowPage.students
              : AccountFlowPage.groupStudents,
        );
      case AccountFlowPage.groupStudents:
        selectedGroup = null;
        _open(AccountFlowPage.students);
      case AccountFlowPage.groupAddStudents:
        _open(AccountFlowPage.groupStudents);
      case AccountFlowPage.groupJoin:
        _open(AccountFlowPage.students);
      case AccountFlowPage.language:
        closeLanguage();
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
