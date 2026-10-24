import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Full-screen animated splash shown once at app startup before [AuthGate].
class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _scaleCtrl;
  late final AnimationController _taglineCtrl;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // Logo fade + scale in
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _taglineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut));
    _taglineFade = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeCtrl.forward();
    _scaleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _taglineCtrl.forward();
    // Navigate after total splash duration
    await Future.delayed(const Duration(milliseconds: 2400));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => widget.nextScreen,
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff024950), Color(0xff087f8c), Color(0xff5aaaa5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top decorative bubbles ──────────────────────────
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    Positioned(
                      top: -30, right: -30,
                      child: _Bubble(size: 140, opacity: 0.08),
                    ),
                    Positioned(
                      top: 40, left: -20,
                      child: _Bubble(size: 80, opacity: 0.06),
                    ),
                  ],
                ),
              ),

              // ── Centre: Lottie + Logo + Name ────────────────────
              Expanded(
                flex: 5,
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Lottie water-drop animation (network)
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: Lottie.network(
                              'https://assets10.lottiefiles.com/packages/lf20_jbb7xfdr.json',
                              fit: BoxFit.contain,
                              repeat: true,
                              frameBuilder: (ctx, child, composition) {
                                if (composition == null) {
                                  return const SizedBox(
                                    width: 200, height: 200,
                                    child: Center(
                                      child: Icon(Icons.water_drop, size: 100, color: Colors.white70),
                                    ),
                                  );
                                }
                                return child;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // App name
                          const Text(
                            'CALIFNCO',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Tagline fade in slightly later
                          FadeTransition(
                            opacity: _taglineFade,
                            child: const Text(
                              'Purifiers · Spares · Services',
                              style: TextStyle(
                                fontSize: 13,
                                letterSpacing: 2,
                                color: Colors.white60,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom loader bar ────────────────────────────────
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white54),
                            minHeight: 3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'v1.0.0',
                      style: TextStyle(fontSize: 11, color: Colors.white30),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final double opacity;
  const _Bubble({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
