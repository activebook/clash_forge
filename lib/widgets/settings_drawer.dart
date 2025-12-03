import 'package:flutter/material.dart';
import '../themes.dart';
import '../constants.dart';

class SettingsDrawer extends StatefulWidget {
  final bool initialUseDns;
  final bool initialIsDarkMode;
  final String initialSelectedDnsProvider;
  final bool initialTunEnable;
  final int initialUrlTestInterval;
  final int initialUrlTestTolerance;
  final bool initialUrlTestLazy;

  final Function(bool useDns) onDnsChanged;
  final Function(bool isDarkMode) onThemeModeChanged;
  final Function(String selectedDnsProvider) onDnsProviderChanged;
  final Function(bool enable) onTunEnableChanged;
  final Function(int interval) onUrlTestIntervalChanged;
  final Function(int tolerance) onUrlTestToleranceChanged;
  final Function(bool lazy) onUrlTestLazyChanged;

  const SettingsDrawer({
    super.key,
    required this.initialUseDns,
    required this.initialIsDarkMode,
    required this.initialSelectedDnsProvider,
    required this.initialTunEnable,
    required this.initialUrlTestInterval,
    required this.initialUrlTestTolerance,
    required this.initialUrlTestLazy,
    required this.onDnsChanged,
    required this.onThemeModeChanged,
    required this.onDnsProviderChanged,
    required this.onTunEnableChanged,
    required this.onUrlTestIntervalChanged,
    required this.onUrlTestToleranceChanged,
    required this.onUrlTestLazyChanged,
  });

  @override
  SettingsDrawerState createState() => SettingsDrawerState();
}

class SettingsDrawerState extends State<SettingsDrawer> {
  bool _useDns = true;
  bool _isDarkMode = false;
  String _selectedDnsProvider = 'Google';
  bool _tunEnable = false;
  int _urlTestInterval = 300;
  int _urlTestTolerance = 100;
  bool _urlTestLazy = true;

  final TextEditingController _intervalController = TextEditingController();
  final TextEditingController _toleranceController = TextEditingController();

  // List of DNS providers
  final List<String> _dnsProviders = [
    'DNSPub',
    'DOHPub',
    'Tencent',
    'CNNIC',
    'Cloudflare',
    'Google',
    'Alibaba',
    'Quad9',
    'AdGuard',
    'NextDNS',
  ];

  @override
  void initState() {
    super.initState();
    _useDns = widget.initialUseDns;
    _isDarkMode = widget.initialIsDarkMode;
    _selectedDnsProvider = widget.initialSelectedDnsProvider;
    _tunEnable = widget.initialTunEnable;
    _urlTestInterval = widget.initialUrlTestInterval;
    _urlTestTolerance = widget.initialUrlTestTolerance;
    _urlTestLazy = widget.initialUrlTestLazy;

    _intervalController.text = _urlTestInterval.toString();
    _toleranceController.text = _urlTestTolerance.toString();
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _toleranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth.clamp(400.0, 600.0);

    return Drawer(
      width: drawerWidth,
      child: Column(
        children: [
          AppBar(
            toolbarHeight: 48,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tun Mode Setting
                  _buildSectionHeader('Tun Mode'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Enable Tun Mode',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Redirects all system network traffic through the proxy by simulating a virtual network device.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Switch(
                      value: _tunEnable,
                      onChanged: (value) {
                        setState(() {
                          _tunEnable = value;
                        });
                        widget.onTunEnableChanged(value);
                      },
                    ),
                  ),

                  Divider(height: 32),

                  // DNS Setting
                  _buildSectionHeader('DNS Settings'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Auto-resolve DNS',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Switch(
                      value: _useDns,
                      onChanged: (value) {
                        setState(() {
                          _useDns = value;
                        });
                        widget.onDnsChanged(value);
                      },
                    ),
                  ),

                  // DNS Info Card
                  Card(
                    color:
                        Theme.of(
                          context,
                        ).extension<AppColors>()?.cardInfoColor ??
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    elevation: 0,
                    margin: EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color:
                                    Theme.of(
                                      context,
                                    ).cardTheme.surfaceTintColor,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Why this matters:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).cardTheme.surfaceTintColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            kDnsResolveInfoMessage,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // DNS Provider Selection Chips
                  if (_useDns) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DNS Provider:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _dnsProviders.map((provider) {
                                  return ChoiceChip(
                                    label: Text(provider),
                                    selected: _selectedDnsProvider == provider,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedDnsProvider = provider;
                                        });
                                        widget.onDnsProviderChanged(provider);
                                      }
                                    },
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh
                                        .withValues(alpha: 0.5),
                                    selectedColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Divider(height: 32),

                  // Background Test Settings
                  _buildSectionHeader('Background Test (URL Test)'),
                  Text(
                    'Defines the proxy group type that automatically selects the proxy with the lowest latency.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 16),

                  // Interval
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interval (s)',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Time interval between each round of latency tests',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _intervalController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            final intVal = int.tryParse(value);
                            if (intVal != null) {
                              widget.onUrlTestIntervalChanged(intVal);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Tolerance
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tolerance (ms)',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Minimum latency difference required to trigger a proxy switch',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _toleranceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            final intVal = int.tryParse(value);
                            if (intVal != null) {
                              widget.onUrlTestToleranceChanged(intVal);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Lazy
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Lazy Mode',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Controls whether testing happens only when the group is actively used',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Switch(
                      value: _urlTestLazy,
                      onChanged: (value) {
                        setState(() {
                          _urlTestLazy = value;
                        });
                        widget.onUrlTestLazyChanged(value);
                      },
                    ),
                  ),

                  // Example Presets
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Text(
                      'Recommended Configurations:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: Text('Responsive'),
                        tooltip: 'Interval: 30s, Tolerance: 50ms, Lazy: Off',
                        onPressed: () {
                          _applyPreset(30, 50, false);
                        },
                      ),
                      ActionChip(
                        label: Text('Balanced'),
                        tooltip: 'Interval: 60s, Tolerance: 100ms, Lazy: Off',
                        onPressed: () {
                          _applyPreset(60, 100, false);
                        },
                      ),
                      ActionChip(
                        label: Text('Stable'),
                        tooltip: 'Interval: 300s, Tolerance: 150ms, Lazy: On',
                        onPressed: () {
                          _applyPreset(300, 150, true);
                        },
                      ),
                    ],
                  ),

                  Divider(height: 32),

                  // Theme Setting
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Dark Theme',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Switch(
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _isDarkMode = value;
                        });
                        widget.onThemeModeChanged(value);
                      },
                    ),
                    leading: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color:
                          _isDarkMode ? Color(0xFF78909C) : Color(0xFFFFB74D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyPreset(int interval, int tolerance, bool lazy) {
    setState(() {
      _urlTestInterval = interval;
      _urlTestTolerance = tolerance;
      _urlTestLazy = lazy;
      _intervalController.text = interval.toString();
      _toleranceController.text = tolerance.toString();
    });
    widget.onUrlTestIntervalChanged(interval);
    widget.onUrlTestToleranceChanged(tolerance);
    widget.onUrlTestLazyChanged(lazy);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
