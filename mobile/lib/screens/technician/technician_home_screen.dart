import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/cart_service.dart';
import '../../services/firebase_service.dart';
import '../customer/profile_screen.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _currentIndex = 0;
  String _selectedFilter = 'pending'; // pending, in_progress, resolved, all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CartService.instance.setDealerMode(false);
      FirebaseService.instance.setupFCM();
    });
  }

  void _showResolutionDialog(String ticketId, String customerName) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Complete Service for $customerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter technical service notes & work performed (e.g. RO membrane replaced, TDS tested):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Replaced 100 GPD Membrane & sediment filter. TDS measured 38 ppm. System tested OK.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final note = noteCtrl.text.trim();
              Navigator.pop(ctx);
              await FirebaseService.instance.updateServiceByTechnician(
                serviceId: ticketId,
                status: 'resolved',
                resolutionNotes: note.isNotEmpty ? note : 'Service completed successfully.',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Service ticket marked as Resolved! Customer notified.')),
                );
              }
            },
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMapDirections(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map app.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching navigation: $e')),
        );
      }
    }
  }

  Future<void> _callCustomer(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot make phone calls on this device ($clean)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error dialing phone: $e')),
        );
      }
    }
  }

  Widget _buildServicesView(BuildContext context) {
    const primary = Color(0xff087f8c);
    final user = FirebaseService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.build_circle, color: primary),
            SizedBox(width: 8),
            Text('My Assigned Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseService.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Technician Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff091322), Color(0xff0f2b3e)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: primary,
                  child: Icon(Icons.engineering, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Field Service Engineer',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'tech@califnco.com',
                        style: const TextStyle(color: Color(0xff94a3b8), fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade400),
                        ),
                        child: const Text(
                          '● Verified Field Technician (Active)',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips: Pending / In Progress / Resolved / All
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Pending'),
                  selected: _selectedFilter == 'pending',
                  selectedColor: const Color(0xffFFA726).withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _selectedFilter = 'pending'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('In Progress'),
                  selected: _selectedFilter == 'in_progress',
                  onSelected: (_) => setState(() => _selectedFilter = 'in_progress'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Completed / History'),
                  selected: _selectedFilter == 'resolved',
                  onSelected: (_) => setState(() => _selectedFilter = 'resolved'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All Jobs'),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) => setState(() => _selectedFilter = 'all'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tickets List from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('serviceRequests')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primary));
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No service tickets assigned',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Assigned service jobs and repair requests will appear here in real time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final myUid = user?.uid ?? '';
                final myName = (user?.displayName ?? '').trim().toLowerCase();
                final myEmail = (user?.email ?? '').trim().toLowerCase();

                // Only show tickets that are explicitly assigned to this technician by Admin
                var docs = snap.data!.docs.where((d) {
                  final data = d.data();
                  final assignedTech = (data['assignedTechnician'] as String? ?? '').trim().toLowerCase();
                  final assignedId = (data['assignedTechnicianId'] as String? ?? '').trim();

                  // If not assigned to anyone yet, do NOT show on technician screen
                  if (assignedTech.isEmpty && assignedId.isEmpty) {
                    return false;
                  }

                  // Must match this logged-in technician
                  final matchesId = assignedId.isNotEmpty && assignedId == myUid;
                  final matchesName = myName.isNotEmpty && (assignedTech == myName || assignedTech.contains(myName) || myName.contains(assignedTech));
                  final matchesEmail = myEmail.isNotEmpty && assignedTech.contains(myEmail);

                  return matchesId || matchesName || matchesEmail;
                }).toList();

                // Apply client-side filter
                if (_selectedFilter != 'all') {
                  docs = docs.where((d) {
                    final s = d.data()['status'] as String? ?? 'open';
                    if (_selectedFilter == 'pending') {
                      return s == 'pending' || s == 'scheduled';
                    }
                    return s == _selectedFilter;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFilter == 'all'
                                ? 'No Service Jobs Assigned Yet'
                                : 'No $_selectedFilter Services',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedFilter == 'all'
                                ? 'When Admin assigns service and repair requests to you, they will appear here in real time.'
                                : 'Check other tabs to view your assigned service jobs.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data();
                    final status = data['status'] as String? ?? 'open';
                    final customerName = data['customerName'] as String? ?? 'Customer';
                    final customerPhone = data['customerPhone'] as String? ?? '9876543210';
                    final serviceType = data['serviceType'] as String? ?? 'RO Service';
                    final purifierModel = data['purifierModel'] as String? ?? 'AquaPure RO';
                    final issue = data['issue'] as String? ?? data['issueDescription'] as String? ?? 'Maintenance';
                    final address = data['address'] as String? ?? 'Chennai, TN';

                    Color statusColor = Colors.orange;
                    String displayStatus = status.toUpperCase();
                    if (status == 'pending') {
                      statusColor = const Color(0xffFFA726);
                      displayStatus = 'PENDING';
                    } else if (status == 'resolved') {
                      statusColor = Colors.green;
                      displayStatus = 'RESOLVED';
                    } else if (status == 'in_progress') {
                      statusColor = Colors.blue;
                      displayStatus = 'IN PROGRESS';
                    } else if (status == 'open') {
                      statusColor = Colors.grey;
                      displayStatus = 'OPEN';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.build, size: 18, color: primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          serviceType,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    displayStatus,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$customerName • $customerPhone',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: const TextStyle(fontSize: 12, color: Color(0xff475569)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primary,
                                      side: const BorderSide(color: primary),
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    ),
                                    icon: const Icon(Icons.directions, size: 16),
                                    label: const Text(
                                      'View Map / Directions',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () => _launchMapDirections(address),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.outlined(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.phone, size: 16, color: Colors.green),
                                  tooltip: 'Call Customer',
                                  onPressed: () => _callCustomer(customerPhone),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.water_drop, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Model: $purifierModel',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.report_problem_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Issue: $issue',
                                    style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                            if (data['resolutionNotes'] != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '✓ Service Notes: ${data['resolutionNotes']}',
                                  style: TextStyle(fontSize: 11.5, color: Colors.green.shade800),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Technician Action Buttons
                            Row(
                              children: [
                                if (status != 'resolved') ...[
                                  if (status != 'in_progress')
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.play_arrow, size: 16),
                                        label: const Text('Start Job'),
                                        onPressed: () async {
                                          await FirebaseService.instance.updateServiceByTechnician(
                                            serviceId: d.id,
                                            status: 'in_progress',
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Status updated to In Progress')),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  if (status != 'in_progress') const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Mark Resolved'),
                                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                      onPressed: () => _showResolutionDialog(d.id, customerName),
                                    ),
                                  ),
                                ] else ...[
                                  const Expanded(
                                    child: Center(
                                      child: Text(
                                        '✓ Completed & Verified',
                                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);

    final pages = [
      _buildServicesView(context),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: primary.withValues(alpha: 0.18),
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman, color: primary),
            label: 'My Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
