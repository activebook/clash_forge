import 'package:flutter/material.dart';
import '../themes.dart';
import '../constants.dart';

class SettingsDrawer extends StatefulWidget {
  final bool initialUseDns;
  final bool initialIsDarkMode;
  final String initialSelectedDnsProvider;
  final Function(bool useDns) onDnsChanged;
  final Function(bool isDarkMode) onThemeModeChanged;
  final Function(String selectedDnsProvider) onDnsProviderChanged;

  const SettingsDrawer({
    super.key,
    required this.initialUseDns,
    required this.initialIsDarkMode,
    required this.initialSelectedDnsProvider,
    required this.onDnsChanged,
    required this.onThemeModeChanged,
    required this.onDnsProviderChanged,
  });

  @override
  SettingsDrawerState createState() => SettingsDrawerState();
}

class SettingsDrawerState extends State<SettingsDrawer> {
  bool _useDns = true;
  bool _isDarkMode = false;
  String _selectedDnsProvider = 'Google'; // Default selection

  // List of DNS providers
  final List<String> _dnsProviders = [
    'DNSPub', // China-friendly, returns global IPs
    'DOHPub', // China-friendly, returns global IPs
    'Tencent', // China-friendly, returns global IPs
    'CNNIC', // China-friendly, returns global IPs
    'Cloudflare', // Global provider
    'Google', // Global provider
    'Alibaba', // May censor results
    'Quad9', // Global provider
    'AdGuard', // Global provider
    'NextDNS', // Global provider
  ];

  @override
  void initState() {
    super.initState();
    _useDns = widget.initialUseDns;
    _isDarkMode = widget.initialIsDarkMode;
    _selectedDnsProvider = widget.initialSelectedDnsProvider;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 380, // Wider for better readability
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
                  // DNS Setting with explanation
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
                        // Add your DNS toggle logic here
                        widget.onDnsChanged(value); // Notify the parent
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
                                        // Handle provider change
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

                  Divider(),

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
                        // Add your theme toggle logic here
                        widget.onThemeModeChanged(value);
                      },
                    ),
                    leading: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color:
                          _isDarkMode
                              ? Color(0xFF78909C)
                              : Color(
                                0xFFFFB74D,
                              ), // Soft Blue Grey : Soft Amber
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
}
