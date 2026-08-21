import 'package:flutter/material.dart';

import '../models/authentication.dart';
import '../models/student.dart';

class StudentMenuScreen extends StatelessWidget {
  final String teacherName;
  final List<Student> students;
  final ValueChanged<Student> onSelect;
  final ValueChanged<Student> onEdit;
  final VoidCallback onAdd;
  final VoidCallback onLogout;

  const StudentMenuScreen({
    required this.teacherName,
    required this.students,
    required this.onSelect,
    required this.onEdit,
    required this.onAdd,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('$teacherName’s students'),
      actions: [
        IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: onAdd,
      icon: const Icon(Icons.person_add),
      label: const Text('Add student'),
    ),
    body: students.isEmpty
        ? const Center(child: Text('Add a student to begin a playing session.'))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: students.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                key: ValueKey('student-${student.id}'),
                title: Text(student.name),
                subtitle: Text('${student.age} • ${student.location}'),
                onTap: () => onSelect(student),
                trailing: IconButton(
                  tooltip: 'Edit student',
                  onPressed: () => onEdit(student),
                  icon: const Icon(Icons.edit),
                ),
              );
            },
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
