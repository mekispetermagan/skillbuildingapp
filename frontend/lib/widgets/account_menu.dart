import 'package:flutter/material.dart';

enum AccountMenuAction { language, changeStudent, logout }

class AccountMenuScope extends InheritedWidget {
  final VoidCallback onChangeLanguage;
  final VoidCallback? onChangeStudent;
  final VoidCallback onLogout;

  const AccountMenuScope({
    required this.onChangeLanguage,
    required this.onChangeStudent,
    required this.onLogout,
    required super.child,
    super.key,
  });

  static AccountMenuScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccountMenuScope>();

  @override
  bool updateShouldNotify(AccountMenuScope oldWidget) =>
      onChangeLanguage != oldWidget.onChangeLanguage ||
      onChangeStudent != oldWidget.onChangeStudent ||
      onLogout != oldWidget.onLogout;
}

class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AccountMenuScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();
    return PopupMenuButton<AccountMenuAction>(
      tooltip: 'Account menu',
      onSelected: (action) {
        switch (action) {
          case AccountMenuAction.language:
            scope.onChangeLanguage();
          case AccountMenuAction.changeStudent:
            scope.onChangeStudent?.call();
          case AccountMenuAction.logout:
            scope.onLogout();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: AccountMenuAction.language,
          child: Text('Change language'),
        ),
        if (scope.onChangeStudent != null)
          const PopupMenuItem(
            value: AccountMenuAction.changeStudent,
            child: Text('Change student'),
          ),
        const PopupMenuItem(
          value: AccountMenuAction.logout,
          child: Text('Log out'),
        ),
      ],
    );
  }
}
