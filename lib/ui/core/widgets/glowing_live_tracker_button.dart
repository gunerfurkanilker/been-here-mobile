import 'package:flutter/material.dart';
import '../theme/been_here_theme.dart';

class GlowingLiveTrackerButton extends StatefulWidget {
  const GlowingLiveTrackerButton({
    super.key,
    required this.isActive,
    required this.isPremiumUser,
    required this.onPressed,
  });

  final bool isActive;
  final bool isPremiumUser;
  final VoidCallback onPressed;

  @override
  State<GlowingLiveTrackerButton> createState() =>
      _GlowingLiveTrackerButtonState();
}

class _GlowingLiveTrackerButtonState extends State<GlowingLiveTrackerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glowAlpha = widget.isActive
            ? 0.25 + (_pulseController.value * 0.45)
            : 0.12 + (_pulseController.value * 0.15);

        final activeColor = widget.isActive
            ? BeenHereColors.verifiedEmerald
            : BeenHereColors.goldLeague;

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: BeenHereColors.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: activeColor.withValues(alpha: 0.75),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: glowAlpha),
                  blurRadius: widget.isActive ? 16 : 8,
                  spreadRadius: widget.isActive ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isActive
                      ? Icons.radar_rounded
                      : Icons.sensors_rounded,
                  size: 18,
                  color: activeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isActive ? 'Canlı İzleme Açık' : 'Geofence / EXIF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
                if (!widget.isPremiumUser) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 14,
                    color: BeenHereColors.goldLeague,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
