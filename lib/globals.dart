import 'package:flutter/material.dart';

/// Global key untuk akses SnackBar dari mana saja (dipakai di ScanVideo)
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// 🔔 RouteObserver untuk mendengar event navigasi (didPopNext/didPush).
/// PENTING: daftarkan di MaterialApp:
/// MaterialApp(
///   navigatorObservers: [routeObserver],
///   scaffoldMessengerKey: rootScaffoldMessengerKey,
///   ...
/// )
/// 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
