class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role; // customer, dealer, admin, technician
  final String referralCode;
  final double referralCredits;
  final int referralCount;
  final String address;
  final String? dealerStatus; // pending, approved, rejected (if dealer)
  final String? technicianStatus; // pending, approved, rejected (if technician)
  final String businessName;
  final String contactPerson;
  final String gstin;
  final String city;
  final String state;
  final String pincode;
  final String specialization;
  final int? yearsExperience;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.phone = '',
    this.role = 'customer',
    required this.referralCode,
    this.referralCredits = 0.0,
    this.referralCount = 0,
    this.address = '',
    this.dealerStatus,
    this.technicianStatus,
    this.businessName = '',
    this.contactPerson = '',
    this.gstin = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
    this.specialization = '',
    this.yearsExperience,
  });

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    final rawName = (data['name'] as String?)?.trim() ?? '';
    final bName = (data['businessName'] as String?)?.trim() ?? '';
    final cPerson = (data['contactPerson'] as String?)?.trim() ?? '';

    // If 'name' is empty, fall back to businessName or contactPerson
    final displayName = rawName.isNotEmpty
        ? rawName
        : (bName.isNotEmpty ? bName : (cPerson.isNotEmpty ? cPerson : 'Califnco User'));

    return UserProfile(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      name: displayName,
      phone: (data['phone'] as String?) ?? '',
      role: (data['role'] as String?) ?? 'customer',
      referralCode: (data['referralCode'] as String?) ??
          'CALIF${uid.substring(0, uid.length > 5 ? 5 : uid.length).toUpperCase()}',
      referralCredits: (data['referralCredits'] as num?)?.toDouble() ?? 0.0,
      referralCount: (data['referralCount'] as num?)?.toInt() ?? 0,
      address: (data['address'] as String?) ?? '',
      dealerStatus: data['dealerStatus'] as String?,
      technicianStatus: data['technicianStatus'] as String?,
      businessName: bName,
      contactPerson: cPerson,
      gstin: (data['gstin'] as String?) ?? '',
      city: (data['city'] as String?) ?? '',
      state: (data['state'] as String?) ?? '',
      pincode: (data['pincode'] as String?) ?? '',
      specialization: (data['specialization'] as String?) ?? (data['primarySkill'] as String?) ?? '',
      yearsExperience: (data['yearsExperience'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'referralCode': referralCode,
      'referralCredits': referralCredits,
      'referralCount': referralCount,
      'address': address,
      if (dealerStatus != null) 'dealerStatus': dealerStatus,
      if (technicianStatus != null) 'technicianStatus': technicianStatus,
      if (businessName.isNotEmpty) 'businessName': businessName,
      if (contactPerson.isNotEmpty) 'contactPerson': contactPerson,
      if (gstin.isNotEmpty) 'gstin': gstin,
      if (city.isNotEmpty) 'city': city,
      if (state.isNotEmpty) 'state': state,
      if (pincode.isNotEmpty) 'pincode': pincode,
      if (specialization.isNotEmpty) 'specialization': specialization,
      if (yearsExperience != null) 'yearsExperience': yearsExperience,
    };
  }
}
