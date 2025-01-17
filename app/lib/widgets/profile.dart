import 'package:chronosculpt/firebase_helper.dart';
import 'package:flutter/material.dart';

class MyProfileScreen extends StatelessWidget {
  final Function refresher;
  const MyProfileScreen({super.key, required this.refresher});

  Future<void> _changePassword(String oldPassword, String newPassword, BuildContext context) async {
    await FirebaseHelper()
        .updateCurrentUserPassword(oldPassword, newPassword, context);
  }

  Future<void> _changeEmail(String newEmail, String password, BuildContext context) async {
    await FirebaseHelper().updateCurrentUserEmail(newEmail, password, context);
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var style = TextStyle(color: colorScheme.secondary);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        centerTitle: true,
        title: Text(
          'My Profile',
          style: TextStyle(color: colorScheme.secondary),
        ),
      ),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 240,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExpansionTile(
                  title: Text(
                    'Change Email',
                    style: style,
                  ),
                  children: [
                    const SizedBox(
                      height: 8.0,
                    ),
                    const Text(
                        'You will be required to verify your email before signing in again.'),
                    const SizedBox(
                      height: 8.0,
                    ),
                    TwoFieldsForm(
                      obscurefield1: false,
                      obscurefield2: true,
                      field1Text: 'New Email',
                      field2Text: 'Password',
                      onSubmit: (field1, field2) => _changeEmail(field1, field2, context),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Change Password',
                    style: style,
                  ),
                  children: [
                    TwoFieldsForm(
                      obscurefield1: true,
                      obscurefield2: true,
                      field1Text: 'Old Password',
                      field2Text: 'New Password',
                      onSubmit: (field1, field2) =>
                          _changePassword(field1, field2, context),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text(
                    'Sign Out',
                    style: style,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseHelper().signOut();
                          refresher();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Sign Out'),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TwoFieldsForm extends StatelessWidget {
  final String field1Text;
  final String field2Text;
  final bool obscurefield1;
  final bool obscurefield2;
  final Function(String field1, String field2) onSubmit;

  const TwoFieldsForm({
    super.key,
    required this.field1Text,
    required this.field2Text,
    required this.obscurefield1,
    required this.obscurefield2,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final field1Controller = TextEditingController();
    final field2Controller = TextEditingController();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16.0),
        ProfileTextField(
          obscure: obscurefield1,
          controller: field1Controller,
          hintText: field1Text,
        ),
        const SizedBox(height: 16.0),
        ProfileTextField(
          obscure: obscurefield2,
          controller: field2Controller,
          hintText: field2Text,
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
              onSubmit(field1Controller.text, field2Controller.text);
              field1Controller.text = "";
              field2Controller.text = "";
          },
          child: const Text('Submit'),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final String hintText;
  final bool obscure;
  final TextEditingController controller;

  const ProfileTextField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.obscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.black,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.black,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
