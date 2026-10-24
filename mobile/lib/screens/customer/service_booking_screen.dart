import 'package:flutter/material.dart';
import '../../models/service_request.dart';
import '../../services/email_service.dart';
import '../../services/firebase_service.dart';
import '../../services/sms_service.dart';
import '../../services/location_service.dart';
import '../../widgets/map_location_picker.dart';
import '../../widgets/success_popup.dart';

class ServiceBookingScreen extends StatefulWidget {
  const ServiceBookingScreen({super.key});

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  String _serviceType = 'Periodic Filter / Membrane Replacement';
  final _modelCtrl = TextEditingController(text: 'Califnco AquaPure RO');
  final _issueCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  DateTime _preferredDate = DateTime.now().add(const Duration(days: 1));
  String _timeSlot = 'Morning (9:00 AM - 12:00 PM)';

  bool _isSubmitting = false;

  final List<String> _serviceTypes = [
    'Periodic Filter / Membrane Replacement',
    'RO Installation & Relocation',
    'Maintenance & Descaling Service',
    'Water Leakage or Motor Noise Repair',
    'Water TDS & Purity Inspection',
  ];

  final List<String> _slots = [
    'Morning (9:00 AM - 12:00 PM)',
    'Afternoon (12:00 PM - 3:00 PM)',
    'Evening (3:00 PM - 6:00 PM)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _loadProfile(user.uid);
    }
  }

  Future<void> _loadProfile(String uid) async {
    final p = await FirebaseService.instance.getUserProfile(uid);
    if (p != null && mounted) {
      setState(() {
        if (p.phone.isNotEmpty) _phoneCtrl.text = p.phone;
        if (p.address.isNotEmpty) _addressCtrl.text = p.address;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _modelCtrl.dispose();
    _issueCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchGPSLocation() async {
    const primary = Color(0xff087f8c);
    // Show same GPS loading dialog as checkout screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 86,
                        height: 86,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff087f8c)),
                          backgroundColor: Color(0x22087f8c),
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.water_drop,
                                color: primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Detecting GPS Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff087f8c),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fetching your current address & coordinates...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final loc = await LocationService.instance.getCurrentLocation();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        if (loc != null) {
          setState(() => _addressCtrl.text = loc.formattedAddress);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service address updated from GPS!'),
              backgroundColor: Color(0xff087f8c),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not fetch location. Please check GPS permissions.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch GPS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final ticketId = await FirebaseService.instance.submitServiceRequest(
        serviceType: _serviceType,
        purifierModel: _modelCtrl.text.trim(),
        issueDescription: _issueCtrl.text.trim().isEmpty ? 'General checkup' : _issueCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        preferredDate: _preferredDate,
        timeSlot: _timeSlot,
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
      );

      // Asynchronously trigger confirmation email via EmailJS
      final userEmail = FirebaseService.instance.currentUser?.email ?? '';
      final formattedTicket = 'TKT-${ticketId.substring(0, ticketId.length > 8 ? 8 : ticketId.length).toUpperCase()}';
      final formattedDate = '${_preferredDate.day}/${_preferredDate.month}/${_preferredDate.year}';
      if (userEmail.isNotEmpty) {
        EmailService.instance.sendServiceBookingConfirmation(
          toEmail: userEmail,
          toName: _nameCtrl.text.trim(),
          ticketId: formattedTicket,
          serviceType: _serviceType,
          preferredDate: formattedDate,
          timeSlot: _timeSlot,
          address: _addressCtrl.text.trim(),
        );
      }

      // Asynchronously trigger confirmation SMS via TextBee
      final customerPhone = _phoneCtrl.text.trim();
      if (customerPhone.isNotEmpty) {
        SmsService.instance.sendServiceBookingSms(
          phone: customerPhone,
          customerName: _nameCtrl.text.trim(),
          ticketId: formattedTicket,
          serviceType: _serviceType,
          preferredDate: formattedDate,
          timeSlot: _timeSlot,
        );
      }

      if (mounted) {
        CalifncoSuccessDialog.show(
          context,
          title: 'Service Scheduled! 💧',
          subtitle: 'Your RO technician visit has been booked with Califnco Field Support.',
          referenceId: '#TKT-${ticketId.substring(0, ticketId.length > 8 ? 8 : ticketId.length).toUpperCase()}',
          referenceLabel: 'Ticket ID',
          details: [
            SuccessPopupItem(
              icon: Icons.handyman_outlined,
              label: 'Service Type',
              value: _serviceType,
            ),
            SuccessPopupItem(
              icon: Icons.water_drop_outlined,
              label: 'Purifier Model',
              value: _modelCtrl.text.trim(),
            ),
            SuccessPopupItem(
              icon: Icons.calendar_today_outlined,
              label: 'Slot',
              value: '${_preferredDate.day}/${_preferredDate.month}/${_preferredDate.year} ($_timeSlot)',
            ),
            SuccessPopupItem(
              icon: Icons.phone_outlined,
              label: 'Contact',
              value: _phoneCtrl.text.trim(),
            ),
          ],
          primaryButtonText: 'View Service History',
          onPrimaryPressed: () {
            Navigator.pop(context);
            _tabController.animateTo(1); // Switch to active requests tab
          },
          secondaryButtonText: 'Book Another Service',
          onSecondaryPressed: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book service: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);
    final user = FirebaseService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purifier Service Desk'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          tabs: const [
            Tab(icon: Icon(Icons.build), text: 'Book Service'),
            Tab(icon: Icon(Icons.history), text: 'My Service Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Book Service Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, color: primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Califnco Certified RO Technicians • Genuine Spares • 30-Day Service Guarantee',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _serviceType,
                    decoration: const InputDecoration(labelText: 'Type of Service *', border: OutlineInputBorder()),
                    items: _serviceTypes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _serviceType = v!),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(labelText: 'Purifier Model / Brand *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Enter model' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _issueCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Issue Description / Notes',
                      hintText: 'e.g. Low water output, filter warning beeping, taste change',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date & Slot Picker
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _preferredDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) setState(() => _preferredDate = picked);
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text('${_preferredDate.day}/${_preferredDate.month}/${_preferredDate.year}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _timeSlot,
                          isDense: true,
                          decoration: const InputDecoration(labelText: 'Slot', border: OutlineInputBorder()),
                          items: _slots
                              .map((s) => DropdownMenuItem(value: s, child: Text(s.split(' ')[0], overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _timeSlot = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Contact Name *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Enter contact name' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder()),
                    validator: (v) => v!.length < 10 ? 'Enter phone number' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Service Visit Address *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            icon: const Icon(Icons.my_location, size: 16, color: primary),
                            label: const Text('GPS', style: TextStyle(fontSize: 12, color: primary)),
                            onPressed: _fetchGPSLocation,
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            icon: const Icon(Icons.map, size: 16, color: primary),
                            label: const Text('Pin on Map', style: TextStyle(fontSize: 12, color: primary)),
                            onPressed: () async {
                              final currentCtx = context;
                              final loc = await MapLocationPickerModal.show(currentCtx);
                              if (loc != null && mounted) {
                                setState(() => _addressCtrl.text = loc.formattedAddress);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Door No, Street, Landmark, Area, City',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter service address' : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: primary),
                      onPressed: _isSubmitting ? null : _submitRequest,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Schedule Service Visit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab 2: Service History Stream
          user == null
              ? const Center(child: Text('Sign in to view your service requests'))
              : StreamBuilder<List<ServiceRequest>>(
                  stream: FirebaseService.instance.streamUserServiceRequests(user.uid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = snap.data ?? [];

                    if (requests.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.build_circle_outlined, size: 56, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No active service requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 6),
                              Text('Book a technician anytime using the form.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        final isOpen = req.status == 'open' || req.status == 'scheduled';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        req.serviceType,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isOpen ? Colors.blue.shade50 : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isOpen ? Colors.blue : Colors.green),
                                      ),
                                      child: Text(
                                        req.status.toUpperCase(),
                                        style: TextStyle(
                                          color: isOpen ? Colors.blue.shade800 : Colors.green.shade800,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Purifier: ${req.purifierModel}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                Text('Date: ${req.preferredDate.day}/${req.preferredDate.month}/${req.preferredDate.year} • ${req.timeSlot}',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                if (req.issueDescription.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Notes: ${req.issueDescription}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
