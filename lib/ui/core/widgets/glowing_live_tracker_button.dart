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
  bool _isHovered = false;

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
        final isDark = BeenHereThemeController.instance.isDark;
        final glowAlpha = widget.isActive
            ? 0.25 + (_pulseController.value * 0.45)
            : 0.18;

        final activeColor = widget.isActive
            ? BeenHereColors.verifiedEmerald
            : BeenHereColors.goldLeague;

        return Tooltip(
          message: widget.isActive ? 'Canlı İzleme Açık' : 'Geofence / EXIF',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onPressed,
              onHover: (hovered) {
                if (_isHovered != hovered) {
                  setState(() => _isHovered = hovered);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? BeenHereColors.surface.withValues(alpha: 0.8)
                      : BeenHereColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (widget.isActive || _isHovered)
                      BoxShadow(
                        color: activeColor.withValues(alpha: glowAlpha),
                        blurRadius: widget.isActive ? 14 : 10,
                        spreadRadius: widget.isActive ? 1.5 : 0,
                      ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.isActive
                        ? Icons.radar_rounded
                        : Icons.sensors_rounded,
                    size: 21,
                    color: activeColor,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
