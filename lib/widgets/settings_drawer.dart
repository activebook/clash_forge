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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.45).clamp(380.0, 520.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Preferences & Engine',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                IconButton(
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close settings',
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Appearance Section
                  _buildSectionContainer(
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
                    context: context,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'Dark Mode',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        subtitle: Text(
                          _isDarkMode ? 'OLED Slate dark mode active' : 'Clean light mode active',
                          style: theme.textTheme.bodySmall,
                        ),
                        secondary: Icon(
                          _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: _isDarkMode ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
                          size: 20,
                        ),
                        value: _isDarkMode,
                        onChanged: (value) {
                          setState(() => _isDarkMode = value);
                          widget.onThemeModeChanged(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. DNS & Resolution Section
                  _buildSectionContainer(
                    title: 'DNS & Resolution',
                    icon: Icons.dns_outlined,
                    context: context,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'Auto-Resolve DNS',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        subtitle: Text(
                          'Pre-resolve domains to IPs to prevent local DNS poisoning',
                          style: theme.textTheme.bodySmall,
                        ),
                        value: _useDns,
                        onChanged: (value) {
                          setState(() => _useDns = value);
                          widget.onDnsChanged(value);
                        },
                      ),
                      if (_useDns) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Select DNS Provider',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _dnsProviders.map((provider) {
                            final isSelected = _selectedDnsProvider == provider;
                            return ChoiceChip(
                              label: Text(provider),
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Colors.white : null,
                              ),
                              selected: isSelected,
                              selectedColor: theme.colorScheme.primary,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedDnsProvider = provider);
                                  widget.onDnsProviderChanged(provider);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Clash TUN & Performance Tuning
                  _buildSectionContainer(
                    title: 'Clash & TUN Tuning',
                    icon: Icons.speed_rounded,
                    context: context,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'Enable TUN Mode',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        subtitle: Text(
                          'Route all operating system traffic via virtual adapter',
                          style: theme.textTheme.bodySmall,
                        ),
                        value: _tunEnable,
                        onChanged: (value) {
                          setState(() => _tunEnable = value);
                          widget.onTunEnableChanged(value);
                        },
                      ),
                      const Divider(height: 20),
                      Text(
                        'URL-Test Presets',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPresetButton('Responsive', 30, 50, false, context),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildPresetButton('Balanced', 60, 100, false, context),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildPresetButton('Stable', 300, 150, true, context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Test Interval (s)',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _intervalController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    suffixText: 's',
                                  ),
                                  onChanged: (value) {
                                    final intVal = int.tryParse(value);
                                    if (intVal != null) {
                                      widget.onUrlTestIntervalChanged(intVal);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tolerance (ms)',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _toleranceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    suffixText: 'ms',
                                  ),
                                  onChanged: (value) {
                                    final intVal = int.tryParse(value);
                                    if (intVal != null) {
                                      widget.onUrlTestToleranceChanged(intVal);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          'Lazy URL-Test',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        subtitle: Text(
                          'Test latency only when node group is accessed',
                          style: theme.textTheme.bodySmall,
                        ),
                        value: _urlTestLazy,
                        onChanged: (value) {
                          setState(() => _urlTestLazy = value);
                          widget.onUrlTestLazyChanged(value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, int interval, int tolerance, bool lazy, BuildContext context) {
    final isCurrent = _urlTestInterval == interval && _urlTestTolerance == tolerance && _urlTestLazy == lazy;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _applyPreset(interval, tolerance, lazy),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent ? theme.colorScheme.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent ? theme.colorScheme.primary : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
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
}
