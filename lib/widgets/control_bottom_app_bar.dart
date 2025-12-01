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
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, //a maximum height limit of approximately 60% of the screen height. If you need a taller sheet, you can use the isScrollControlled: true parameter
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use',
                //style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('Import Subscriptions'),
                subtitle: Text(
                  'Load subscription URLs from a file, where each line contains a single URL.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Export Subscriptions'),
                subtitle: Text(
                  'Save all added subscription URLs to a file, with each URL on a separate line.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.fast_forward),
                title: const Text('Process All Subscriptions'),
                subtitle: Text(
                  'Retrieve and format all protocols from all added subscription URLs.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Subscriptions Target Path'),
                subtitle: Text(
                  'Process all subscription protocols in YAML format and save them in the specified folder.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Logs of processing'),
                subtitle: Text(
                  'Logs record all subscription processing results, hover over each log to see the detail.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.format_align_center),
                title: const Text('Supported Formats'),
                subtitle: Text(
                  'Includes VMess, VLess, Trojan, Shadowsocks(R), Hysteria2, TUIC, and AnyTLS protocols. VMess provides secure, efficient data transmission; VLess offers similar benefits with enhanced performance; Trojan is optimized for stealth and reliability; Shadowsocks is renowned for its simplicity and strong encryption; Hysteria2 delivers excellent obfuscation with top performance; TUIC uses QUIC for low latency; and AnyTLS offers versatile TLS wrapping.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
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
                    // Show speedtest dialog
                    showDialog(
                      context: buttonContext,
                      barrierDismissible: false,
                      builder: (context) => const SpeedTestDialog(),
                    );
                  },
                  icon: Icon(
                    Icons.speed_outlined,
                    color:
                        Theme.of(context).extension<AppColors>()?.forwardAction,
                    size: 24,
                  ),
                  tooltip: 'Network Speed Test',
                ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Import Subscriptions',
            child: ElevatedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_outlined, size: 20),
              label: const Text('Import'),
            ),
          ),

          if (centerLocations.contains(fabLocation)) const Spacer(),

          Tooltip(
            message: 'Export Subscriptions',
            child: ElevatedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.share_outlined, size: 20),
              label: const Text('Export'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              _showBottomSheet(context);
            },
            icon: Icon(
              Icons.help_outline,
              color: Theme.of(context).extension<AppColors>()?.folderAction,
              size: 24,
            ),
            tooltip: 'How to use',
          ),
        ],
      ),
    );
  }
}
