import 'package:flutter/material.dart';
import '../managers/profile_manager.dart';

/// An overlay widget that displays the current profile switching status.
///
/// Shows a semi-transparent overlay with a progress indicator and status message
/// during the profile switching process.
class SwitchingOverlay extends StatelessWidget {
  final ProfileManager profileManager;
  final Widget child;

  const SwitchingOverlay({
    super.key,
    required this.profileManager,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: profileManager,
      builder: (context, _) {
        return Stack(
          children: [
            child,
            if (profileManager.switchingState != SwitchingState.idle)
              _buildOverlay(context),
          ],
        );
      },
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final state = profileManager.switchingState;
    final message = profileManager.switchingMessage;

    // Determine icon and color based on state
    IconData icon;
    Color iconColor;
    bool showSpinner;

    switch (state) {
      case SwitchingState.writingConfig:
        icon = Icons.settings;
        iconColor = Colors.blue;
        showSpinner = true;
        break;
      case SwitchingState.restarting:
        icon = Icons.refresh;
        iconColor = Colors.orange;
        showSpinner = true;
        break;
      case SwitchingState.waitingForApi:
        icon = Icons.cloud_sync;
        iconColor = Colors.purple;
        showSpinner = true;
        break;
      case SwitchingState.testingDelay:
        icon = Icons.speed;
        iconColor = Colors.cyan;
        showSpinner = true;
        break;
      case SwitchingState.completed:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        showSpinner = false;
        break;
      case SwitchingState.completedWithWarning:
        icon = Icons.check_box;
        iconColor = Colors.lime;
        showSpinner = false;
        break;
      case SwitchingState.failed:
        icon = Icons.error;
        iconColor = Colors.red;
        showSpinner = false;
        break;
      default:
        icon = Icons.hourglass_empty;
        iconColor = Colors.grey;
        showSpinner = true;
    }

    return AnimatedOpacity(
      opacity: state == SwitchingState.idle ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with optional spinner
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (showSpinner)
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              iconColor,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      Icon(icon, size: showSpinner ? 28 : 48, color: iconColor),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Status message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                // Step indicator
                _buildStepIndicator(context, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, SwitchingState state) {
    final steps = [
      ('Config', SwitchingState.writingConfig),
      ('Restart', SwitchingState.restarting),
      ('Test', SwitchingState.testingDelay),
    ];

    int currentStep = 0;
    switch (state) {
      case SwitchingState.writingConfig:
        currentStep = 0;
        break;
      case SwitchingState.restarting:
      case SwitchingState.waitingForApi:
        currentStep = 1;
        break;
      case SwitchingState.testingDelay:
        currentStep = 2;
        break;
      case SwitchingState.completed:
        currentStep = 3;
        break;
      case SwitchingState.completedWithWarning:
        currentStep = 3;
        break;
      case SwitchingState.failed:
        currentStep = -1; // Show all as failed
        break;
      default:
        currentStep = 0;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          steps.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value.$1;

            Color dotColor;
            if (state == SwitchingState.failed) {
              dotColor = Colors.red.withValues(alpha: 0.5);
            } else if (index < currentStep) {
              dotColor = Colors.green;
            } else if (index == currentStep) {
              dotColor = Colors.blue;
            } else {
              dotColor = Colors.grey.withValues(alpha: 0.3);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(fontSize: 10, color: dotColor)),
                ],
              ),
            );
          }).toList(),
    );
  }
}
