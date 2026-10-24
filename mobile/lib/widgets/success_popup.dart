import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SuccessPopupItem {
  final IconData icon;
  final String label;
  final String value;

  const SuccessPopupItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class CalifncoSuccessDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? referenceId;
  final String referenceLabel;
  final List<SuccessPopupItem> details;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final Color primaryColor;

  const CalifncoSuccessDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.referenceId,
    this.referenceLabel = 'Reference ID',
    this.details = const [],
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.primaryColor = const Color(0xff087f8c),
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? referenceId,
    String referenceLabel = 'Reference ID',
    List<SuccessPopupItem> details = const [],
    required String primaryButtonText,
    required VoidCallback onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    Color primaryColor = const Color(0xff087f8c),
  }) {
    HapticFeedback.mediumImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CalifncoSuccessDialog(
        title: title,
        subtitle: subtitle,
        referenceId: referenceId,
        referenceLabel: referenceLabel,
        details: details,
        primaryButtonText: primaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        secondaryButtonText: secondaryButtonText,
        onSecondaryPressed: onSecondaryPressed,
        primaryColor: primaryColor,
      ),
    );
  }

  @override
  State<CalifncoSuccessDialog> createState() => _CalifncoSuccessDialogState();
}

class _CalifncoSuccessDialogState extends State<CalifncoSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _scaleFade;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.elasticOut);
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = widget.primaryColor;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.7, end: 1.0).animate(_scaleFade),
      child: FadeTransition(
        opacity: _enterCtrl,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: isDark ? const Color(0xff18222c) : Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          elevation: 16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Native animated success checkmark ──────────────
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: _AnimatedSuccessCheckmark(color: primary),
                  ),
                  const SizedBox(height: 14),

                  // ── Title ─────────────────────────────────────────
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle ──────────────────────────────────────
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Reference Badge with Copy Button ──────────────
                  if (widget.referenceId != null &&
                      widget.referenceId!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${widget.referenceLabel}: ${widget.referenceId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                  text: widget.referenceId!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${widget.referenceLabel} copied to clipboard!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Icon(Icons.copy_rounded,
                                size: 15, color: primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Details Card ──────────────────────────────────
                  if (widget.details.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xff222e3a)
                            : const Color(0xfff5f8fa),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: widget.details.map((item) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 5.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(item.icon, size: 16, color: primary),
                                const SizedBox(width: 10),
                                Text(
                                  '${item.label}: ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item.value,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Primary Action Button (Gradient) ──────────────
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [primary, const Color(0xff024950)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: widget.onPrimaryPressed,
                      child: Text(
                        widget.primaryButtonText,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // ── Secondary Button (Optional) ───────────────────
                  if (widget.secondaryButtonText != null &&
                      widget.onSecondaryPressed != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: widget.onSecondaryPressed,
                      child: Text(
                        widget.secondaryButtonText!,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Native animated success checkmark with expanding ripple and bounce effect.
class _AnimatedSuccessCheckmark extends StatefulWidget {
  final Color color;
  const _AnimatedSuccessCheckmark({required this.color});

  @override
  State<_AnimatedSuccessCheckmark> createState() => _AnimatedSuccessCheckmarkState();
}

class _AnimatedSuccessCheckmarkState extends State<_AnimatedSuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rippleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _rippleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer expanding ripple ring
            Transform.scale(
              scale: _rippleAnim.value,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: (1.0 - _rippleAnim.value) * 0.35 + 0.08),
                ),
              ),
            ),
            // Middle ring
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
              ),
            ),
            // Inner vibrant success badge with bouncing checkmark
            Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xff10b981), Color(0xff059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff10b981).withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
              ),
            ),
          ],
        );
      },
    );
  }
}
