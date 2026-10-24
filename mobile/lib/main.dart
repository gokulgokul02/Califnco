import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/common/splash_screen.dart';
import 'screens/customer/catalog_screen.dart';
import 'screens/customer/order_history_screen.dart';
import 'screens/customer/profile_screen.dart';
import 'screens/customer/service_booking_screen.dart';
import 'screens/dealer/dealer_dashboard_screen.dart';
import 'screens/technician/technician_home_screen.dart';
import 'services/cart_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseService.registerBackgroundHandler();
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase init note: $e (running in local demonstration mode)');
  }
  runApp(const CalifncoApp());
}

class CalifncoApp extends StatelessWidget {
  const CalifncoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primarySeed = Color(0xff087f8c);
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          scaffoldMessengerKey: FirebaseService.scaffoldMessengerKey,
          title: 'Califnco',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeService.instance.themeMode,
          theme: ThemeData(
            colorSchemeSeed: primarySeed,
            brightness: Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xfff8fafb),
            appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0.5, centerTitle: false),
            cardTheme: CardThemeData(color: Colors.white, elevation: 1.5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: primarySeed,
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xff11171d),
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xff182028), elevation: 0.5, centerTitle: false),
            cardTheme: CardThemeData(color: const Color(0xff1c252f), elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xff1c252f), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          home: SplashScreen(nextScreen: const AuthGate()),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService.instance.authStateChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const _LoadingScreen();
        if (snap.data == null) return const SignInScreen();
        return FutureBuilder<Map<String, String>>(
          future: FirebaseService.instance.getFullProfile(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) return const _LoadingScreen();
            final role = roleSnap.data?['role'] ?? 'customer';
            final dealerStatus = roleSnap.data?['dealerStatus'] ?? '';
            final technicianStatus = roleSnap.data?['technicianStatus'] ?? '';

            if (role == 'technician') {
              if (technicianStatus != 'approved') {
                return _TechnicianPendingScreen(status: technicianStatus);
              }
              return const TechnicianHomeScreen();
            }

            if (role == 'dealer' && dealerStatus != 'approved') {
              return _DealerPendingScreen(dealerStatus: dealerStatus);
            }
            final isApprovedDealer = role == 'dealer' && dealerStatus == 'approved';
            return MainNavigationScaffold(isDealer: isApprovedDealer);
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xff087f8c))));
}

class _DealerPendingScreen extends StatelessWidget {
  final String dealerStatus;
  const _DealerPendingScreen({required this.dealerStatus});
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);
    final isRejected = dealerStatus == 'rejected';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: isRejected ? Colors.red.shade50 : const Color(0xffe6f6f8), shape: BoxShape.circle),
                child: Icon(isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded, size: 52, color: isRejected ? Colors.red.shade400 : primary),
              ),
              const SizedBox(height: 28),
              Text(
                isRejected ? 'Application Not Approved' : 'Pending Admin Review',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: isRejected ? Colors.red.shade700 : const Color(0xff024950)),
              ),
              const SizedBox(height: 12),
              Text(
                isRejected
                    ? 'Your dealer application was not approved. Please contact Califnco support.'
                    : 'Your wholesale dealer application has been submitted.\n\nAdmin will review your GSTIN & business details and approve shortly. You will be notified once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.55),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isRejected ? Colors.red.shade50 : Colors.amber.shade50,
                  border: Border.all(color: isRejected ? Colors.red.shade200 : Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isRejected ? Icons.close_rounded : Icons.schedule_rounded, size: 16, color: isRejected ? Colors.red.shade600 : Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Text(isRejected ? 'Status: Rejected' : 'Status: Pending Approval',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isRejected ? Colors.red.shade700 : Colors.amber.shade800)),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async => FirebaseService.instance.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out & Back to Login'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechnicianPendingScreen extends StatelessWidget {
  final String status;
  const _TechnicianPendingScreen({required this.status});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);
    final isRejected = status == 'rejected';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isRejected ? Colors.red.shade50 : const Color(0xffe6f6f8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.cancel_outlined : Icons.engineering_outlined,
                  size: 52,
                  color: isRejected ? Colors.red.shade400 : primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                isRejected ? 'Application Not Approved' : 'Pending Admin Verification',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isRejected ? Colors.red.shade700 : const Color(0xff024950),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                isRejected
                    ? 'Your Field Service Engineer registration was not approved. Please contact Califnco operations desk.'
                    : 'Your Field Service Engineer registration has been submitted.\n\nCalifnco Operations verifies field certifications and technical regions. Once approved in the Admin Console, field service assignments and job dispatch will unlock automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.55),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isRejected ? Colors.red.shade50 : Colors.amber.shade50,
                  border: Border.all(color: isRejected ? Colors.red.shade200 : Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRejected ? Icons.close_rounded : Icons.schedule_rounded,
                      size: 16,
                      color: isRejected ? Colors.red.shade600 : Colors.amber.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isRejected ? 'Status: Rejected' : 'Status: Pending Admin Approval',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isRejected ? Colors.red.shade700 : Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async => FirebaseService.instance.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out & Back to Login'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  final bool isDealer;
  const MainNavigationScaffold({super.key, this.isDealer = false});
  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CartService.instance.setDealerMode(widget.isDealer);
      FirebaseService.instance.setupFCM();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);

    final List<Widget> pages = widget.isDealer
        ? [CatalogScreen(isDealerMode: true), const OrderHistoryScreen(), const ServiceBookingScreen(), const DealerDashboardScreen(), const ProfileScreen()]
        : [const CatalogScreen(isDealerMode: false), const OrderHistoryScreen(), const ServiceBookingScreen(), const ProfileScreen()];

    final List<NavigationDestination> destinations = widget.isDealer
        ? const [
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront, color: primary), label: 'Store'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: primary), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle, color: primary), label: 'Service'),
            NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business, color: primary), label: 'Dealer'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: primary), label: 'Profile'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront, color: primary), label: 'Store'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: primary), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle, color: primary), label: 'Service'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: primary), label: 'Profile'),
          ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: primary.withValues(alpha: 0.18),
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: destinations,
      ),
    );
  }
}
