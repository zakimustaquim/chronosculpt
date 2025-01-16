import 'package:chronosculpt/main.dart';
import 'package:chronosculpt/shared_preferences_helper.dart';
import 'package:flutter/material.dart';
import 'package:chronosculpt/firebase_helper.dart';

/// Main splash screen for the app, shown on first launch
/// and whenever unauthenticated.
class SplashWidget extends StatefulWidget {
  const SplashWidget({super.key});

  @override
  State<SplashWidget> createState() => _SplashWidgetState();
}

class _SplashWidgetState extends State<SplashWidget> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LogoDisplay(),
            SizedBox(height: 72.0),
            LoginSignupButtons(),
          ],
        ),
      ),
    );
  }
}

/// Displays an animation showing the logo
/// fade in after a delay.
class LogoDisplay extends StatefulWidget {
  const LogoDisplay({super.key});

  @override
  State<LogoDisplay> createState() => _LogoDisplayState();
}

class _LogoDisplayState extends State<LogoDisplay> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeIn,
      child: Column(
        children: [
          Image.asset('images/logo.png', scale: 5),
          Text(
            'Chronosculpt',
            style: TextStyle(
              fontSize: 36.0,
              color: colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Contains the login and signup buttons and
/// also displays an animated fade-in after
/// a delay.
class LoginSignupButtons extends StatefulWidget {
  const LoginSignupButtons({super.key});

  @override
  State<LoginSignupButtons> createState() => _LoginSignupButtonsState();
}

class _LoginSignupButtonsState extends State<LoginSignupButtons> {
  bool _visible = false;

  void _startActivity(String type) {
    if (type == 'Sign Up') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SignupScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeIn,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _startActivity('Sign Up'),
            child: Text(
              'Sign Up',
              style: TextStyle(color: colorScheme.secondary),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _startActivity('Login'),
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

/// Text field used in the login/signup forms.
class ChronosculptTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool? obscure;
  final Function(String)? onSubmit;

  const ChronosculptTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscure,
    this.onSubmit,
  });

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
        onSubmitted: widget.onSubmit,
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

/// Main screen enabling registering of new accounts.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confPassController = TextEditingController();
  var _rememberMe = false;

  Future<void> _signUp(BuildContext context) async {
    if (_passController.text != _confPassController.text) {
      showSnackBar(context, 'The passwords do not match.');
      return;
    }

    await FirebaseHelper()
        .createUser(_emailController.text, _passController.text, context);

    if (getCurrentUserUid() != 'none') {
      if (!_rememberMe) SharedPreferencesHelper().setToForget();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainWidget()),
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
          constraints: const BoxConstraints(
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
              const SizedBox(height: 16.0),
              ChronosculptTextField(
                controller: _emailController,
                hintText: 'Email',
                onSubmit: (_) => _signUp(context),
              ),
              const SizedBox(height: 12.0),
              ChronosculptTextField(
                controller: _passController,
                hintText: 'Password',
                obscure: true,
                onSubmit: (_) => _signUp(context),
              ),
              const SizedBox(height: 12.0),
              ChronosculptTextField(
                controller: _confPassController,
                hintText: 'Confirm Password',
                obscure: true,
                onSubmit: (_) => _signUp(context),
              ),
              const SizedBox(height: 12.0),
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
                    value: _rememberMe,
                    onChanged: (b) => setState(
                      () {
                        _rememberMe = b ?? false;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => _signUp(context),
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

/// Main screen enabling authentication of existing accounts.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var _rememberMe = false;
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  Future<void> _logIn(BuildContext context) async {
    await FirebaseHelper()
        .logIn(_emailController.text, _passController.text, context);

    if (getCurrentUserUid() != 'none') {
      if (!_rememberMe) SharedPreferencesHelper().setToForget();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainWidget()),
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
          constraints: const BoxConstraints(
            maxWidth: 240,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Log In',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.surface,
                  fontSize: 24.0,
                ),
              ),
              const SizedBox(height: 16.0),
              ChronosculptTextField(
                controller: _emailController,
                hintText: 'Email',
                onSubmit: (_) => _logIn(context),
              ),
              const SizedBox(height: 12.0),
              ChronosculptTextField(
                controller: _passController,
                hintText: 'Password',
                obscure: true,
                onSubmit: (_) => _logIn(context),
              ),
              const SizedBox(height: 12.0),
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
                    value: _rememberMe,
                    onChanged: (b) => setState(
                      () {
                        _rememberMe = b ?? false;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => _logIn(context),
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
