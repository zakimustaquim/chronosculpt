import 'dart:io';
import 'package:flutter/foundation.dart';

/// the link to the server hosting the backend
const String backendPath = "https://zm68526.pythonanywhere.com";
// const String backendPath = "http://127.0.0.1:5000";

bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS) ||
    kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);
