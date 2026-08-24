import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillbuilding_game/models/authentication.dart';
import 'package:skillbuilding_game/models/student.dart';
import 'package:skillbuilding_game/models/student_group.dart';
import 'package:skillbuilding_game/screens/student_screens.dart';

void main() {
  final student = Student(
    id: 'student-1',
    name: 'Student One',
    location: 'Kampala',
    age: 9,
    gender: LearnerGender.female,
    ownerAccountId: 2,
  );
  final group = StudentGroup(
    id: 'group-1',
    name: 'Primary One',
    studentIds: const ['student-1'],
    ownerAccountId: 2,
    isOwner: true,
  );

  testWidgets('teacher menu separates groups and ungrouped students', (
    tester,
  ) async {
    StudentGroup? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: StudentMenuScreen(
          teacherName: 'Teacher One',
          ungroupedStudents: [student],
          groups: [group],
          onSelect: (_) {},
          onEdit: (_) {},
          onAddStudent: () {},
          onAddGroup: () {},
          onOpenGroup: (group) => opened = group,
          onJoinGroup: () {},
        ),
      ),
    );

    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Ungrouped students'), findsOneWidget);
    await tester.tap(find.text('Primary One'));
    expect(opened, group);
  });

  testWidgets('group screen exposes owner sharing and membership actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupStudentsScreen(
          group: group,
          students: [student],
          busy: false,
          errorMessage: null,
          onSelect: (_) {},
          onEditStudent: (_) {},
          onRemoveStudent: (_) {},
          onCreateStudent: () {},
          onAddExistingStudents: () {},
          onRename: () {},
          onShare: () async => 'ABCD2345',
          onBack: () {},
        ),
      ),
    );

    expect(find.byTooltip('Rename group'), findsOneWidget);
    expect(find.byTooltip('Remove from group'), findsOneWidget);
    await tester.tap(find.byTooltip('Share group'));
    await tester.pumpAndSettle();
    expect(find.text('ABCD2345'), findsOneWidget);
  });
}
