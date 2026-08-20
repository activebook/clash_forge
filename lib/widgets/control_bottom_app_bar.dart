import 'package:flutter/material.dart';
import '../themes.dart';
import 'speedtest_dialog.dart';

class ControlBottomAppBar extends StatelessWidget {
  const ControlBottomAppBar({
    super.key,
    this.fabLocation = FloatingActionButtonLocation.endDocked,
    this.shape = const CircularNotchedRectangle(),
    this.onImport,
    this.onExport,
  });

  final FloatingActionButtonLocation fabLocation;
  final NotchedShape? shape;
  // Using separate callbacks instead of a list
  final VoidCallback? onImport;
  final VoidCallback? onExport;

  static final List<FloatingActionButtonLocation> centerLocations =
      <FloatingActionButtonLocation>[
        FloatingActionButtonLocation.centerDocked,
        FloatingActionButtonLocation.centerFloat,
      ];

  void _showBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Clash Forge User Guide',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildGuideItem(
                      icon: Icons.file_upload_outlined,
                      color: const Color(0xFF6366F1),
                      title: 'Import & Batch Management',
                      subtitle:
                          'Load subscription URLs from a file (one URL per line) or drag & drop configuration files directly into the window.',
                      context: context,
                    ),
                    _buildGuideItem(
                      icon: Icons.file_download_outlined,
                      color: const Color(0xFF10B981),
                      title: 'Export Subscriptions',
                      subtitle:
                          'Backup and save all configured subscription links and custom paths to an export file.',
                      context: context,
                    ),
                    _buildGuideItem(
                      icon: Icons.toggle_on_outlined,
                      color: const Color(0xFF0EA5E9),
                      title: 'Profile Activation & Switching',
                      subtitle:
                          'Toggle the switch beside any profile to activate it in Clash. Includes automatic real-time latency ping badges.',
                      context: context,
                    ),
                    _buildGuideItem(
                      icon: Icons.speed_rounded,
                      color: const Color(0xFF8B5CF6),
                      title: 'Multi-threaded Speed & WebRTC Audit',
                      subtitle:
                          'Run multi-stream speed testing and WebRTC leak prevention checks with live telemetry cards.',
                      context: context,
                    ),
                    _buildGuideItem(
                      icon: Icons.dns_outlined,
                      color: const Color(0xFFF59E0B),
                      title: 'DNS Resolution Engine',
                      subtitle:
                          'Pre-resolve domains using DNSPub, Tencent, Cloudflare, Google, or CNNIC to circumvent DNS poisoning.',
                      context: context,
                    ),
                    _buildGuideItem(
                      icon: Icons.hub_outlined,
                      color: const Color(0xFFEC4899),
                      title: 'All Modern Protocols Supported',
                      subtitle:
                          'Full support for VLESS, VMess, Trojan, Shadowsocks, ShadowsocksR, Hysteria2, TUIC, AnyTLS, and WireGuard.',
                      context: context,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: shape,
      child: Row(
        children: <Widget>[
          Builder(
            builder:
                (buttonContext) => IconButton(
                  onPressed: () {
                    showDialog(
                      context: buttonContext,
                      barrierDismissible: false,
                      builder: (context) => const SpeedTestDialog(),
                    );
                  },
                  icon: Icon(
                    Icons.speed_rounded,
                    color:
                        Theme.of(context).extension<AppColors>()?.forwardAction,
                    size: 22,
                  ),
                  tooltip: 'Network Speed Test',
                ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Import Subscriptions',
            child: OutlinedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.file_upload_outlined, size: 16),
              label: const Text('Import'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),

          if (centerLocations.contains(fabLocation)) const Spacer(),

          Tooltip(
            message: 'Export Subscriptions',
            child: OutlinedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Export'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _showBottomSheet(context),
            icon: Icon(
              Icons.help_outline_rounded,
              color: Theme.of(context).extension<AppColors>()?.folderAction,
              size: 22,
            ),
            tooltip: 'User Guide',
          ),
        ],
      ),
    );
  }
}
