class DealerApplication {
  final String id;
  final String userId;
  final String businessName;
  final String contactPerson;
  final String email;
  final String phone;
  final String gstin;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final int yearsInBusiness;
  final String status; // pending, approved, rejected
  final String? rejectionReason;
  final DateTime createdAt;

  const DealerApplication({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.gstin,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.yearsInBusiness = 1,
    this.status = 'pending',
    this.rejectionReason,
    required this.createdAt,
  });

  factory DealerApplication.fromFirestore(String id, Map<String, dynamic> data) {
    return DealerApplication(
      id: id,
      userId: data['userId'] ?? id,
      businessName: data['businessName'] ?? data['name'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      gstin: data['gstin'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      pincode: data['pincode'] ?? '',
      yearsInBusiness: (data['yearsInBusiness'] as num?)?.toInt() ?? 1,
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is DateTime
              ? data['createdAt']
              : (data['createdAt'] as dynamic).toDate())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'gstin': gstin,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'yearsInBusiness': yearsInBusiness,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
    };
  }
}
