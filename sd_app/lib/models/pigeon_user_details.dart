class PigeonUserDetails {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;

  PigeonUserDetails({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  factory PigeonUserDetails.fromMap(Map<String, dynamic> data) {
    return PigeonUserDetails(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}
