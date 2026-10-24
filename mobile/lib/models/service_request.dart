class ServiceRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String serviceType; // installation, filter_replacement, maintenance, repair, tds_inspection
  final String purifierModel;
  final String issueDescription;
  final String address;
  final DateTime preferredDate;
  final String timeSlot; // Morning (9am-12pm), Afternoon (12pm-3pm), Evening (3pm-6pm)
  final String status; // open, scheduled, in_progress, resolved, cancelled
  final String? technicianAssigned;
  final DateTime createdAt;

  const ServiceRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.serviceType,
    required this.purifierModel,
    required this.issueDescription,
    required this.address,
    required this.preferredDate,
    required this.timeSlot,
    this.status = 'open',
    this.technicianAssigned,
    required this.createdAt,
  });

  factory ServiceRequest.fromFirestore(String id, Map<String, dynamic> data) {
    return ServiceRequest(
      id: id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Customer',
      customerPhone: data['customerPhone'] ?? '',
      serviceType: data['serviceType'] ?? 'maintenance',
      purifierModel: data['purifierModel'] ?? data['productName'] ?? 'Califnco RO',
      issueDescription: data['issue'] ?? data['issueDescription'] ?? '',
      address: data['address'] ?? '',
      preferredDate: data['preferredDate'] != null
          ? (data['preferredDate'] is DateTime
              ? data['preferredDate']
              : (data['preferredDate'] as dynamic).toDate())
          : DateTime.now().add(const Duration(days: 1)),
      timeSlot: data['timeSlot'] ?? 'Morning (9 AM - 12 PM)',
      status: data['status'] ?? 'open',
      technicianAssigned: data['technicianAssigned'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is DateTime
              ? data['createdAt']
              : (data['createdAt'] as dynamic).toDate())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'serviceType': serviceType,
      'purifierModel': purifierModel,
      'issueDescription': issueDescription,
      'issue': issueDescription,
      'address': address,
      'preferredDate': preferredDate,
      'timeSlot': timeSlot,
      'status': status,
      'technicianAssigned': technicianAssigned,
      'createdAt': createdAt,
    };
  }
}
