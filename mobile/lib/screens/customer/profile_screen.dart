import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/user_profile.dart';
import '../../services/firebase_service.dart';
import '../../services/theme_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);
    final user = FirebaseService.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: Text('Sign in to view your profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseService.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: FirebaseService.instance.streamUserProfile(user.uid),
        builder: (context, snap) {
          final profile = snap.data ??
              UserProfile(
                uid: user.uid,
                email: user.email ?? '',
                name: user.displayName ?? 'Califnco Member',
                referralCode: 'CALIF${user.uid.substring(0, user.uid.length > 5 ? 5 : user.uid.length).toUpperCase()}',
                referralCredits: 200.0,
                role: 'customer',
              );

          final isDealer = profile.role == 'dealer';
          final isTechnician = profile.role == 'technician';
          final displayName = profile.businessName.isNotEmpty
              ? profile.businessName
              : (profile.name.isNotEmpty ? profile.name : (user.displayName ?? 'Califnco Partner'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User / Dealer Avatar & Identity Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: primary,
                          child: isDealer
                              ? const Icon(Icons.storefront_rounded, size: 36, color: Colors.white)
                              : isTechnician
                                  ? const Icon(Icons.engineering_rounded, size: 36, color: Colors.white)
                                  : Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (profile.contactPerson.isNotEmpty && profile.contactPerson != displayName) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Contact: ${profile.contactPerson}',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                profile.email.isNotEmpty ? profile.email : (user.email ?? ''),
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDealer ? Colors.teal.shade50 : primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDealer ? Colors.teal.shade300 : primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  isDealer
                                      ? '✓ APPROVED WHOLESALE DEALER'
                                      : isTechnician
                                          ? '✓ FIELD SERVICE TECHNICIAN'
                                          : 'RETAIL CUSTOMER',
                                  style: TextStyle(
                                    color: isDealer ? Colors.teal.shade800 : primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Refer & Earn Rewards Card ───────────────────
                _buildReferralCard(context, profile, primary),

                const SizedBox(height: 16),

                // Dealer Business Details Section (Wholesale Account)
                if (isDealer) ...[
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified_outlined, color: primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Wholesale Account Details',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (profile.gstin.isNotEmpty) ...[
                            _buildInfoRow(Icons.receipt_long_outlined, 'GSTIN', profile.gstin),
                            const SizedBox(height: 12),
                          ],
                          if (profile.phone.isNotEmpty) ...[
                            _buildInfoRow(Icons.phone_outlined, 'Registered Phone', profile.phone),
                            const SizedBox(height: 12),
                          ],
                          if (profile.address.isNotEmpty) ...[
                            _buildInfoRow(Icons.location_on_outlined, 'Business Address', profile.address),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xffe6f6f8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.discount_outlined, color: primary, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'B2B Wholesale Pricing Active: 25-35% Margin Unlocked on all Catalog products.',
                                    style: TextStyle(color: Color(0xff024950), fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Technician Engineering Details
                if (isTechnician) ...[
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.engineering_outlined, color: primary, size: 20),
                              SizedBox(width: 8),
                              Text('Field Engineering Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),
                          if (profile.specialization.isNotEmpty) ...[
                            _buildInfoRow(Icons.build_outlined, 'Purifier Specialization', profile.specialization),
                            const SizedBox(height: 12),
                          ],
                          if (profile.city.isNotEmpty) ...[
                            _buildInfoRow(Icons.location_city_outlined, 'Service Region / Hub', profile.city),
                            const SizedBox(height: 12),
                          ],
                          if (profile.yearsExperience != null) ...[
                            _buildInfoRow(Icons.history_toggle_off_outlined, 'Field Experience', '${profile.yearsExperience} Years Technical Experience'),
                            const SizedBox(height: 12),
                          ],
                          if (profile.phone.isNotEmpty) ...[
                            _buildInfoRow(Icons.phone_outlined, 'Registered Mobile', profile.phone),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Customer / General Contact Information
                if (!isDealer && (profile.phone.isNotEmpty || profile.address.isNotEmpty)) ...[
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const Divider(height: 20),
                          if (profile.phone.isNotEmpty) ...[
                            _buildInfoRow(Icons.phone_outlined, 'Phone', profile.phone),
                            const SizedBox(height: 10),
                          ],
                          if (profile.address.isNotEmpty) ...[
                            _buildInfoRow(Icons.location_on_outlined, 'Default Delivery Address', profile.address),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Settings & Preferences
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      // Dark Mode Switch
                      ListenableBuilder(
                        listenable: ThemeService.instance,
                        builder: (context, _) {
                          final isDark = ThemeService.instance.isDarkMode;
                          return SwitchListTile(
                            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: primary),
                            title: const Text('Dark Mode'),
                            subtitle: Text(isDark ? 'Sleek dark theme active' : 'Bright daylight theme active'),
                            value: isDark,
                            activeThumbColor: primary,
                            activeTrackColor: primary.withValues(alpha: 0.4),
                            onChanged: (val) {
                              ThemeService.instance.toggleTheme();
                            },
                          );
                        },
                      ),
                      const Divider(height: 1),

                      // Push Notifications Setup
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: primary),
                        title: const Text('Push Notifications (FCM)'),
                        subtitle: const Text('Real-time order, service dispatch & dealer alerts'),
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            final token = await FirebaseService.instance.setupFCM();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(token != null
                                      ? 'FCM Token registered: ${token.substring(0, 15)}...'
                                      : 'FCM push notifications active'),
                                ),
                              );
                            }
                          },
                          child: const Text('Active', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Out Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    await FirebaseService.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferralCard(BuildContext context, UserProfile profile, Color primary) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final code = profile.referralCode.isNotEmpty
        ? profile.referralCode
        : 'CALIF${profile.uid.substring(0, profile.uid.length > 5 ? 5 : profile.uid.length).toUpperCase()}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xff1f2d3a), const Color(0xff16222c)]
                : [const Color(0xffe6f6f8), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: primary.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.card_giftcard_rounded, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Refer & Earn ₹150 Credits',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Friends get ₹200 OFF • You earn ₹150 wallet credits',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metrics row: Wallet Credits & Referrals count
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff273646) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Referral Wallet',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${profile.referralCredits.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff273646) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Friends Joined',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${profile.referralCount}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Referral code box with copy & share buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff182430) : const Color(0xfff0f9fa),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR REFERRAL CODE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          code,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy Code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Referral code "$code" copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Share', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Share.share(
                        'Hey! Use my referral code "$code" on Califnco to get ₹200 OFF on your water purifiers & spare parts order! Download & Shop: https://califnco.com',
                        subject: 'Get ₹200 OFF on Califnco with my code: $code',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
