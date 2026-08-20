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

  static const channelFocus = MethodChannel('com.activebook.clash_forge/focus');

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await channelFocus.invokeMethod('activateWindow');
      } catch (_) {}
    });
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
    final IconData iconData;
    final Color iconColor;
    switch (status) {
      case NotificationStatus.success:
        iconData = Icons.check_circle_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case NotificationStatus.error:
        iconData = Icons.error_rounded;
        iconColor = const Color(0xFFEF4444);
        break;
      case NotificationStatus.warning:
        iconData = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
      case NotificationStatus.info:
        iconData = Icons.info_rounded;
        iconColor = const Color(0xFF0EA5E9);
        break;
    }

    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        content: Row(
          children: [
            Icon(iconData, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('images/logo.png', height: 22),
          const SizedBox(width: 8),
          Text(
            _appInfo.appName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withValues(alpha: 0.85), primary],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              "v${_appInfo.appVersion}",
              style: const TextStyle(
                fontSize: 10.5,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
      leadingWidth: 46,
      leading: Builder(
        builder:
            (context) => ListenableBuilder(
              listenable: _subscriptionManager,
              builder: (context, _) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    iconSize: 20,
                    icon: Badge.count(
                      count: _subscriptionManager.logEntries.length,
                      isLabelVisible:
                          _subscriptionManager.logEntries.isNotEmpty,
                      backgroundColor: const Color(0xFF6366F1),
                      child: const Icon(Icons.terminal_rounded),
                    ),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    tooltip: 'Event Logs',
                  ),
                );
              },
            ),
      ),
      actions: [
        Builder(
          builder:
              (context) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  iconSize: 20,
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Preferences & Settings',
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
          initialTunEnable: _settingsManager.tunEnable,
          initialUrlTestInterval: _settingsManager.urlTestInterval,
          initialUrlTestTolerance: _settingsManager.urlTestTolerance,
          initialUrlTestLazy: _settingsManager.urlTestLazy,
          onDnsChanged: _settingsManager.toggleDNS,
          onThemeModeChanged: _settingsManager.toggleTheme,
          onDnsProviderChanged: _settingsManager.toggleDnsProvider,
          onTunEnableChanged: _settingsManager.setTunEnable,
          onUrlTestIntervalChanged: _settingsManager.setUrlTestInterval,
          onUrlTestToleranceChanged: _settingsManager.setUrlTestTolerance,
          onUrlTestLazyChanged: _settingsManager.setUrlTestLazy,
        );
      },
    );
  }
}
