import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'themes.dart';
import 'constants.dart';
import 'models/app_info.dart';

import 'widgets/log_drawer.dart';
import 'widgets/settings_drawer.dart';
import 'widgets/forge_view.dart';

import 'managers/subscription_manager.dart';
import 'managers/settings_manager.dart';
import 'managers/profile_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final packageInfo = await PackageInfo.fromPlatform();

  final appInfo = AppInfo(
    appName: packageInfo.appName,
    appVersion: packageInfo.version,
  );

  runApp(MyApp(appInfo: appInfo));
}

class MyApp extends StatefulWidget {
  final AppInfo appInfo;
  const MyApp({super.key, required this.appInfo});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late final AppInfo _appInfo;
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final SettingsManager _settingsManager = SettingsManager();
  final ProfileManager _profileManager = ProfileManager();

  // UI State
  int? _hoveredLogIndex;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _appInfo = widget.appInfo;
    _subscriptionManager.init();
    _settingsManager.init();
  }

  @override
  void dispose() {
    _subscriptionManager.dispose();
    _settingsManager.dispose();
    _profileManager.dispose();
    super.dispose();
  }

  void showNotification(
    String text, {
    NotificationStatus status = NotificationStatus.success,
  }) {
    Widget icon;
    switch (status) {
      case NotificationStatus.success:
        icon = const Icon(Icons.check_circle, color: Color(0xFF66BB6A));
        break;
      case NotificationStatus.error:
        icon = const Icon(Icons.error, color: Color(0xFFEF5350));
        break;
      case NotificationStatus.warning:
        icon = const Icon(Icons.warning, color: Color(0xFFFFA726));
        break;
      case NotificationStatus.info:
        icon = const Icon(Icons.info, color: Color(0xFF29B6F6));
        break;
    }
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
        showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsManager,
      builder: (context, _) {
        return MaterialApp(
          title: widget.appInfo.appName,
          theme: macOSLightThemeFollow(),
          darkTheme: macOSDarkThemeFollow(),
          themeMode: _settingsManager.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          scaffoldMessengerKey: _scaffoldMessengerKey,
          home: Builder(
            builder: (context) {
              return Scaffold(
                key: _scaffoldKey,
                appBar: _buildAppBar(context),
                drawer: _buildLogDrawer(context),
                endDrawer: _buildSettingsDrawer(context),
                body: ForgeView(
                  subscriptionManager: _subscriptionManager,
                  settingsManager: _settingsManager,
                  profileManager: _profileManager,
                  onShowNotification: showNotification,
                ),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('images/logo.png', height: 24),
          const SizedBox(width: 8),
          Text(_appInfo.appName, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  Theme.of(context).colorScheme.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              "v${_appInfo.appVersion}",
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      leadingWidth: 40,
      leading: Builder(
        builder:
            (context) => ListenableBuilder(
              listenable: _subscriptionManager,
              builder: (context, _) {
                return IconButton(
                  icon: Badge.count(
                    count: _subscriptionManager.logEntries.length,
                    isLabelVisible: _subscriptionManager.logEntries.isNotEmpty,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  tooltip: 'Log information',
                );
              },
            ),
      ),
      actions: [
        Builder(
          builder:
              (context) => Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildLogDrawer(BuildContext context) {
    return ListenableBuilder(
      listenable: _subscriptionManager,
      builder: (context, _) {
        return LogDrawer(
          logEntries: _subscriptionManager.logEntries,
          hoveredLogIndex: _hoveredLogIndex,
          onClearLogs: () {
            HapticFeedback.mediumImpact();
            _subscriptionManager.clearAllLogs();
          },
          onHoverChange: (index) {
            setState(() {
              _hoveredLogIndex = index;
            });
          },
          scaffoldKey: _scaffoldKey,
        );
      },
    );
  }

  Widget _buildSettingsDrawer(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsManager,
      builder: (context, _) {
        return SettingsDrawer(
          initialIsDarkMode: _settingsManager.themeMode == ThemeMode.dark,
          initialUseDns: _settingsManager.needResolveDNS,
          initialSelectedDnsProvider: _settingsManager.dnsProvider,
          onDnsChanged: _settingsManager.toggleDNS,
          onThemeModeChanged: _settingsManager.toggleTheme,
          onDnsProviderChanged: _settingsManager.toggleDnsProvider,
        );
      },
    );
  }
}
