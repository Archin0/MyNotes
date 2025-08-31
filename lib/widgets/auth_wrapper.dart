import 'package:flutter/material.dart';
import '../services/security_service.dart';
import '../pages/pin_page.dart';
import '../pages/notes_list_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final SecurityService _securityService = SecurityService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _securityService.onAppResume();
        break;
      case AppLifecycleState.paused:
        _securityService.onAppPause();
        break;
      case AppLifecycleState.inactive:
        // Do nothing for inactive state
        break;
      case AppLifecycleState.detached:
        _securityService.logout();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _handlePinResult(bool? result) async {
    if (result == true) {
      _securityService.authenticate();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _securityService.authStream,
      initialData: _securityService.isAuthenticated,
      builder: (context, snapshot) {
        final isAuthenticated = snapshot.data ?? false;

        if (!isAuthenticated) {
          return PinPage(onPinEntered: _handlePinResult);
        }

        return const NotesListPage();
      },
    );
  }
}
