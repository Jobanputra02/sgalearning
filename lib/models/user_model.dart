import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String branch;
  final String role;
  final String? addressLine1;
  final String? addressLine2;
  final String city;
  final String zipCode;
  final DateTime createdAt;
  final bool isActive;
  final bool isApproved;

  const UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.branch,
    required this.role,
    this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.zipCode,
    required this.createdAt,
    required this.isActive,
    this.isApproved = false,
  });

  String get fullName => '$firstName $lastName';
  bool get isStudent   => role == 'student';
  bool get isFaculty   => role == 'faculty';
  bool get isAdmin     => role == 'admin';

  String get roleLabel {
    switch (role) {
      case 'faculty': return 'Faculty';
      case 'admin':   return 'Admin';
      default:        return 'Student';
    }
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:          doc.id,
      firstName:    d['firstName']    ?? '',
      lastName:     d['lastName']     ?? '',
      email:        d['email']        ?? '',
      phone:        d['phone']        ?? '',
      branch:       d['branch']       ?? '',
      role:         d['role']         ?? 'student',
      addressLine1: d['addressLine1'],
      addressLine2: d['addressLine2'],
      city:         d['city']         ?? '',
      zipCode:      d['zipCode']      ?? '',
      createdAt:    (d['createdAt'] as Timestamp).toDate(),
      isActive:     d['isActive']     ?? true,
      isApproved:   d['isApproved']   ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'firstName':    firstName,
    'lastName':     lastName,
    'email':        email,
    'phone':        phone,
    'branch':       branch,
    'role':         role,
    if (addressLine1 != null) 'addressLine1': addressLine1,
    if (addressLine2 != null) 'addressLine2': addressLine2,
    'city':         city,
    'zipCode':      zipCode,
    'createdAt':    Timestamp.fromDate(createdAt),
    'isActive':     isActive,
    'isApproved':   isApproved,
  };
}