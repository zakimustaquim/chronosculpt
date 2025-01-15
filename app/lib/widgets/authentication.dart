import 'package:chronosculpt/main.dart';
import 'package:flutter/material.dart';
import 'package:chronosculpt/firebase_helper.dart';

class AuthenticationWidget extends StatefulWidget {
  const AuthenticationWidget({super.key});

  @override
  State<AuthenticationWidget> createState() => _AuthenticationWidgetState();
}

class _AuthenticationWidgetState extends State<AuthenticationWidget> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LogoDisplay(),
            LoginSignupButtons(),
          ],
        ),
      ),
    );
  }
}

class LogoDisplay extends StatefulWidget {
  const LogoDisplay({super.key});

  @override
  State<LogoDisplay> createState() => _LogoDisplayState();
}

class _LogoDisplayState extends State<LogoDisplay> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 1000),
      child: Image.asset('images/logo.png', scale: 5),
    );
  }
}

class LoginSignupButtons extends StatefulWidget {
  const LoginSignupButtons({super.key});

  @override
  State<LoginSignupButtons> createState() => _LoginSignupButtonsState();
}

class _LoginSignupButtonsState extends State<LoginSignupButtons> {
  bool _visible = false;

  void startActivity(String type) {
    if (type == 'Sign Up') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Future.delayed(Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 250),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => startActivity('Sign Up'),
            child: Text(
              'Sign Up',
              style: TextStyle(color: colorScheme.secondary),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => startActivity('Login'),
            child: Text(
              'Login',
              style: TextStyle(color: colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class ChronosculptTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool? obscure;
  const ChronosculptTextField(
      {super.key,
      required this.controller,
      required this.hintText,
      this.obscure});

  @override
  State<ChronosculptTextField> createState() => ChronosculptTextFieldState();
}

class ChronosculptTextFieldState extends State<ChronosculptTextField> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: colorScheme.surfaceContainerHighest,
        ),
      ),
      child: TextField(
        obscureText: widget.obscure == null ? false : true,
        cursorColor: colorScheme.surface,
        controller: widget.controller,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: colorScheme.surface,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: colorScheme.surfaceContainerHighest,
              width: 2.0,
            ),
          ),
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: colorScheme.surface,
          ),
        ),
        style: TextStyle(color: colorScheme.surface),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  var emailController = TextEditingController();
  var passController = TextEditingController();
  var confPassController = TextEditingController();
  var rememberMe = false;

  Future<void> signUp(BuildContext context) async {
    if (passController.text != confPassController.text) {
      showSnackBar(context, 'The passwords do not match.');
      return;
    }

    await FirebaseHelper()
        .createUser(emailController.text, passController.text, context);

    if (getCurrentUserUid() != 'none') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainWidget()),
        (Route<dynamic> route) => false, // Removes all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 240,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sign Up',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.surface,
                  fontSize: 24.0,
                ),
              ),
              SizedBox(height: 16.0),
              ChronosculptTextField(
                controller: emailController,
                hintText: 'Email',
              ),
              SizedBox(height: 12.0),
              ChronosculptTextField(
                controller: passController,
                hintText: 'Password',
                obscure: true,
              ),
              SizedBox(height: 12.0),
              ChronosculptTextField(
                controller: confPassController,
                hintText: 'Confirm Password',
                obscure: true,
              ),
              SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Remember me?',
                      style: TextStyle(color: colorScheme.surface),
                    ),
                  ),
                  Checkbox(
                    fillColor: WidgetStateProperty.resolveWith((_) {
                      return colorScheme.secondaryContainer;
                    }),
                    checkColor: Colors.black,
                    value: rememberMe,
                    onChanged: (b) => setState(
                      () {
                        rememberMe = b ?? false;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => signUp(context),
                child: Text(
                  'Submit',
                  style: TextStyle(color: colorScheme.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
