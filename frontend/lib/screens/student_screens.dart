import 'package:flutter/material.dart';

import '../models/authentication.dart';
import '../models/student.dart';
import '../models/student_group.dart';
import '../widgets/account_menu.dart';

class StudentMenuScreen extends StatelessWidget {
  final String teacherName;
  final List<Student> ungroupedStudents;
  final List<StudentGroup> groups;
  final ValueChanged<Student> onSelect;
  final ValueChanged<Student> onEdit;
  final VoidCallback onAddStudent;
  final VoidCallback onAddGroup;
  final ValueChanged<StudentGroup> onOpenGroup;
  final VoidCallback onJoinGroup;

  const StudentMenuScreen({
    required this.teacherName,
    required this.ungroupedStudents,
    required this.groups,
    required this.onSelect,
    required this.onEdit,
    required this.onAddStudent,
    required this.onAddGroup,
    required this.onOpenGroup,
    required this.onJoinGroup,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('$teacherName’s students and groups'),
      actions: const [AccountMenuButton()],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onAddStudent,
              icon: const Icon(Icons.person_add),
              label: const Text('Create student'),
            ),
            FilledButton.tonalIcon(
              onPressed: onAddGroup,
              icon: const Icon(Icons.group_add),
              label: const Text('Create group'),
            ),
            OutlinedButton.icon(
              onPressed: onJoinGroup,
              icon: const Icon(Icons.key),
              label: const Text('Access shared group'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Groups', style: Theme.of(context).textTheme.titleLarge),
        if (groups.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No groups yet.'),
          )
        else
          for (final group in groups)
            Card(
              child: ListTile(
                key: ValueKey('group-${group.id}'),
                leading: const Icon(Icons.groups),
                title: Text(group.name),
                subtitle: Text(
                  '${group.studentIds.length} student${group.studentIds.length == 1 ? '' : 's'}'
                  '${group.isOwner ? '' : ' • Shared with you'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenGroup(group),
              ),
            ),
        const SizedBox(height: 24),
        Text(
          'Ungrouped students',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (ungroupedStudents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No ungrouped students.'),
          )
        else
          for (final student in ungroupedStudents)
            _StudentTile(student: student, onSelect: onSelect, onEdit: onEdit),
      ],
    ),
  );
}

class GroupStudentsScreen extends StatelessWidget {
  final StudentGroup group;
  final List<Student> students;
  final bool busy;
  final String? errorMessage;
  final ValueChanged<Student> onSelect;
  final ValueChanged<Student> onEditStudent;
  final ValueChanged<Student> onRemoveStudent;
  final VoidCallback onCreateStudent;
  final VoidCallback onAddExistingStudents;
  final VoidCallback onRename;
  final Future<String?> Function() onShare;
  final VoidCallback onBack;

  const GroupStudentsScreen({
    required this.group,
    required this.students,
    required this.busy,
    required this.errorMessage,
    required this.onSelect,
    required this.onEditStudent,
    required this.onRemoveStudent,
    required this.onCreateStudent,
    required this.onAddExistingStudents,
    required this.onRename,
    required this.onShare,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(group.name),
      leading: BackButton(onPressed: onBack),
      actions: [
        if (group.isOwner)
          IconButton(
            tooltip: 'Rename group',
            onPressed: onRename,
            icon: const Icon(Icons.edit),
          ),
        if (group.isOwner)
          IconButton(
            tooltip: 'Share group',
            onPressed: busy ? null : () => _showShareCode(context),
            icon: const Icon(Icons.share),
          ),
        const AccountMenuButton(),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onCreateStudent,
              icon: const Icon(Icons.person_add),
              label: const Text('Create student'),
            ),
            OutlinedButton.icon(
              onPressed: onAddExistingStudents,
              icon: const Icon(Icons.group_add),
              label: const Text('Add existing students'),
            ),
          ],
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        if (students.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('This group has no students yet.')),
          )
        else
          for (final student in students)
            _StudentTile(
              student: student,
              onSelect: onSelect,
              onEdit: onEditStudent,
              onRemove: onRemoveStudent,
            ),
      ],
    ),
  );

  Future<void> _showShareCode(BuildContext context) async {
    final code = await onShare();
    if (code == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group sharing code'),
        content: SelectableText(
          code,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Student student;
  final ValueChanged<Student> onSelect;
  final ValueChanged<Student> onEdit;
  final ValueChanged<Student>? onRemove;

  const _StudentTile({
    required this.student,
    required this.onSelect,
    required this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('student-${student.id}'),
    title: Text(student.name),
    subtitle: Text('${student.age} • ${student.location}'),
    onTap: () => onSelect(student),
    trailing: Wrap(
      spacing: 4,
      children: [
        IconButton(
          tooltip: 'Edit student',
          onPressed: () => onEdit(student),
          icon: const Icon(Icons.edit),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'Remove from group',
            onPressed: () => onRemove!(student),
            icon: const Icon(Icons.person_remove),
          ),
      ],
    ),
  );
}

class StudentFormScreen extends StatefulWidget {
  final Student? student;
  final Future<void> Function({
    required String name,
    required String location,
    required int age,
    required LearnerGender gender,
  })
  onSave;
  final VoidCallback onBack;

  const StudentFormScreen({
    required this.student,
    required this.onSave,
    required this.onBack,
    super.key,
  });

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _age;
  late LearnerGender _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    _name = TextEditingController(text: student?.name);
    _location = TextEditingController(text: student?.location);
    _age = TextEditingController(text: student?.age.toString());
    _gender = student?.gender ?? LearnerGender.otherOrPreferNotToSay;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.student == null ? 'Add student' : 'Edit student'),
      leading: BackButton(onPressed: widget.onBack),
      actions: const [AccountMenuButton()],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(_name, 'Name'),
                  _field(_location, 'Location'),
                  _field(_age, 'Age', age: true),
                  DropdownButtonFormField<LearnerGender>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(
                        value: LearnerGender.male,
                        child: Text('Male'),
                      ),
                      DropdownMenuItem(
                        value: LearnerGender.female,
                        child: Text('Female'),
                      ),
                      DropdownMenuItem(
                        value: LearnerGender.otherOrPreferNotToSay,
                        child: Text('Other / prefer not to say'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _gender = value!),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSave(
      name: _name.text,
      location: _location.text,
      age: int.parse(_age.text),
      gender: _gender,
    );
    if (mounted) setState(() => _saving = false);
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool age = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: age ? TextInputType.number : null,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        if (age) {
          final parsed = int.tryParse(value);
          if (parsed == null || parsed < 1 || parsed > 120) {
            return 'Enter a valid age';
          }
        }
        return null;
      },
    ),
  );

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _age.dispose();
    super.dispose();
  }
}

class GroupFormScreen extends StatefulWidget {
  final StudentGroup? group;
  final Future<void> Function(String name) onSave;
  final VoidCallback onBack;

  const GroupFormScreen({
    required this.group,
    required this.onSave,
    required this.onBack,
    super.key,
  });

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.group?.name,
  );
  bool _saving = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.group == null ? 'Create group' : 'Rename group'),
      leading: BackButton(onPressed: widget.onBack),
      actions: const [AccountMenuButton()],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Group name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Group name is required'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSave(_name.text);
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }
}

class GroupStudentPickerScreen extends StatefulWidget {
  final String groupName;
  final List<Student> students;
  final Future<void> Function(Set<String> studentIds) onAdd;
  final VoidCallback onBack;

  const GroupStudentPickerScreen({
    required this.groupName,
    required this.students,
    required this.onAdd,
    required this.onBack,
    super.key,
  });

  @override
  State<GroupStudentPickerScreen> createState() =>
      _GroupStudentPickerScreenState();
}

class _GroupStudentPickerScreenState extends State<GroupStudentPickerScreen> {
  final Set<String> _selectedIds = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Add students to ${widget.groupName}'),
      leading: BackButton(onPressed: widget.onBack),
      actions: const [AccountMenuButton()],
    ),
    body: widget.students.isEmpty
        ? const Center(child: Text('All available students are in this group.'))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final student in widget.students)
                CheckboxListTile(
                  key: ValueKey('group-picker-${student.id}'),
                  title: Text(student.name),
                  subtitle: Text('${student.age} • ${student.location}'),
                  value: _selectedIds.contains(student.id),
                  onChanged: (selected) => setState(() {
                    if (selected == true) {
                      _selectedIds.add(student.id);
                    } else {
                      _selectedIds.remove(student.id);
                    }
                  }),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _selectedIds.isEmpty || _saving ? null : _add,
                child: Text(_saving ? 'Adding…' : 'Add selected students'),
              ),
            ],
          ),
  );

  Future<void> _add() async {
    setState(() => _saving = true);
    await widget.onAdd(_selectedIds);
    if (mounted) setState(() => _saving = false);
  }
}

class JoinGroupScreen extends StatefulWidget {
  final bool busy;
  final String? errorMessage;
  final Future<bool> Function(String code) onJoin;
  final VoidCallback onBack;

  const JoinGroupScreen({
    required this.busy,
    required this.errorMessage,
    required this.onJoin,
    required this.onBack,
    super.key,
  });

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Access shared group'),
      leading: BackButton(onPressed: widget.onBack),
      actions: const [AccountMenuButton()],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _code,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: '8-character sharing code',
                    ),
                    validator: (value) => value?.trim().length == 8
                        ? null
                        : 'Enter the 8-character code',
                  ),
                  if (widget.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        widget.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: widget.busy ? null : _join,
                    child: Text(widget.busy ? 'Joining…' : 'Access group'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onJoin(_code.text);
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }
}
