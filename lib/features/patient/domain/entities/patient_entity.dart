class PatientEntity {
  final String uid;
  final String firstName;
  final String lastName;
  final String name;
  final String phone;
  final int age;
  final String gender;
  final String address;
  final String city;
  final String nicNumber;
  final String email;
  final DateTime? createdAt;

  const PatientEntity({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    required this.address,
    required this.city,
    required this.nicNumber,
    required this.email,
    this.createdAt,
  });
}
