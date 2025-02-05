import 'dart:io';

import 'package:flutter/foundation.dart';

/// the link to the server hosting the backend
const String backendPath = "https://zm68526.pythonanywhere.com";

bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);