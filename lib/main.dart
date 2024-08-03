import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Key? key;
  const MyApp({this.key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CMS Party',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  final String initialUrl = 'https://sparrowsofttech.in/dev/party/#/';

  @override
  void initState() {
    super.initState();
    checkAndRequestLocationPermission();
    _timer = Timer.periodic(Duration(seconds: 10), (_) {
      checkAndRequestLocationPermission();
    });
  }

  @override
  void dispose() {
    super.dispose();
    // Cancel the timer when the widget is disposed
    _timer.cancel();
  }

  Future<void> checkAndRequestLocationPermission() async {
    LocationPermission _permission;

    // Check if location permission is granted
    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
      if (_permission != LocationPermission.whileInUse &&
          _permission != LocationPermission.always) {
        return;
      }
    }

    // Get the current location
    Position _position;
    try {
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("Location: ${_position.latitude}, ${_position.longitude}");
    } catch (e) {
      print("Error getting location: $e");
      return;
    }

    // Start listening to location updates
    StreamSubscription<Position> _positionStream;
    _positionStream = Geolocator.getPositionStream(
            // Minimum distance (in meters) before a new position update is triggered.
            )
        .listen((Position currentLocation) {
      print(
          "Updated Location: ${currentLocation.latitude}, ${currentLocation.longitude}");
    });

    // Dispose of the stream subscription when no longer needed
    _positionStream.cancel();
  }

  InAppWebViewController? _webViewController;
  bool _isLoggedIn =
      false; // You can initialize this based on saved login state.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            if (_webViewController!.canGoBack != null &&
                await _webViewController!.canGoBack()) {
              _webViewController!.goBack();
              return false;
            }
            SystemNavigator.pop();
            return true;
          },
          child: InAppWebView(
            androidOnGeolocationPermissionsShowPrompt:
                (InAppWebViewController controller, String origin) async {
              return GeolocationPermissionShowPromptResponse(
                  origin: origin, allow: true, retain: true);
            },
            initialUrlRequest: URLRequest(
                url: Uri.parse('https://sparrowsofttech.in/dev/ruby-party')),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                useShouldOverrideUrlLoading: true,
                useOnLoadResource: true,
                javaScriptEnabled: true,
              ),
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              // You can add any additional setup code here.
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              if (!_isLoggedIn &&
                  navigationAction.request.url
                      .toString()
                      .contains('successful_login_url')) {
                // Handle the successful login URL, e.g., extract tokens and login information.
                setState(() {
                  _isLoggedIn = true;
                });
                // Save login state using shared_preferences or flutter_secure_storage.
                // Redirect to the main content page or do any other desired actions.
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
        ),
      ),
    );
  }
}
