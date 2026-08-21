import 'package:flutter/material.dart';

import '../models/authentication.dart';
import '../models/interface_language.dart';

class AuthenticationWelcomeScreen extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  const AuthenticationWelcomeScreen({
    required this.onLogin,
    required this.onRegister,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: BackButton(onPressed: onBack)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(onPressed: onLogin, child: const Text('Login')),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRegister,
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  final bool busy;
  final String? errorMessage;
  final Future<bool> Function(AccountCredentials) onSubmit;
  final VoidCallback onBack;

  const LoginScreen({
    required this.busy,
    required this.errorMessage,
    required this.onSubmit,
    required this.onBack,
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _pin = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Login'),
      leading: BackButton(onPressed: widget.onBack),
    ),
    body: _FormBody(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _textField(_username, 'Username'),
            _textField(_pin, '6-digit PIN', pin: true),
            if (widget.errorMessage != null) _ErrorText(widget.errorMessage!),
            FilledButton(
              onPressed: widget.busy ? null : _submit,
              child: Text(widget.busy ? 'Logging in…' : 'Login'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(
      AccountCredentials(username: _username.text, pin: _pin.text),
    );
  }

  @override
  void dispose() {
    _username.dispose();
    _pin.dispose();
    super.dispose();
  }
}

class RegistrationScreen extends StatefulWidget {
  final bool busy;
  final String? errorMessage;
  final Future<bool> Function(AccountRegistration) onSubmit;
  final VoidCallback onBack;

  const RegistrationScreen({
    required this.busy,
    required this.errorMessage,
    required this.onSubmit,
    required this.onBack,
    super.key,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();
  final _location = TextEditingController();
  final _age = TextEditingController();
  AccountRole _role = AccountRole.learner;
  InterfaceLanguage _language = InterfaceLanguage.english;
  LearnerGender _gender = LearnerGender.otherOrPreferNotToSay;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Register'),
      leading: BackButton(onPressed: widget.onBack),
    ),
    body: _FormBody(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<AccountRole>(
              segments: const [
                ButtonSegment(
                  value: AccountRole.learner,
                  label: Text('Learner'),
                ),
                ButtonSegment(
                  value: AccountRole.teacher,
                  label: Text('Teacher'),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (value) =>
                  setState(() => _role = value.single),
            ),
            const SizedBox(height: 16),
            _textField(_name, 'Name'),
            _textField(_username, 'Username'),
            _textField(_pin, '6-digit PIN', pin: true),
            _textField(
              _confirmPin,
              'Confirm PIN',
              pin: true,
              validator: (value) =>
                  value == _pin.text ? null : 'PINs do not match',
            ),
            DropdownButtonFormField<InterfaceLanguage>(
              initialValue: _language,
              decoration: const InputDecoration(
                labelText: 'Preferred language',
              ),
              items: [
                for (final language in InterfaceLanguage.values)
                  DropdownMenuItem(
                    value: language,
                    child: Text(language.nativeName),
                  ),
              ],
              onChanged: (value) => setState(() => _language = value!),
            ),
            _textField(_location, 'Location'),
            if (_role == AccountRole.learner) ...[
              _textField(_age, 'Age', numeric: true),
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
            ],
            if (widget.errorMessage != null) _ErrorText(widget.errorMessage!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: widget.busy ? null : _submit,
              child: Text(widget.busy ? 'Registering…' : 'Register'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(
      AccountRegistration(
        username: _username.text,
        pin: _pin.text,
        name: _name.text,
        role: _role,
        preferredLanguage: _language,
        location: _location.text,
        age: _role == AccountRole.learner ? int.parse(_age.text) : null,
        gender: _role == AccountRole.learner ? _gender : null,
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _username,
      _pin,
      _confirmPin,
      _location,
      _age,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}

Widget _textField(
  TextEditingController controller,
  String label, {
  bool pin = false,
  bool numeric = false,
  String? Function(String?)? validator,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    obscureText: pin,
    keyboardType: numeric ? TextInputType.number : null,
    decoration: InputDecoration(labelText: label),
    validator:
        validator ??
        (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          if (pin && !RegExp(r'^\d{6}$').hasMatch(value)) {
            return 'Enter exactly 6 digits';
          }
          if (numeric) {
            final age = int.tryParse(value);
            if (age == null || age < 1 || age > 120) {
              return 'Enter a valid age';
            }
          }
          return null;
        },
  ),
);

class _FormBody extends StatelessWidget {
  final Widget child;
  const _FormBody({required this.child});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  );
}

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
