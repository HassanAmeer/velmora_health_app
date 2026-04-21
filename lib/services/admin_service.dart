import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String adminCollection = 'admin';
  static const String supportCollection = 'support_messages';
  static const String bugsCollection = 'bug_reports';
  static const String docsCollection = 'legal_docs';
  static const String faqsCollection = 'faqs';

  // Fetch Legal Documents (Privacy Policy, Terms)
  Future<Map<String, dynamic>?> getLegalDoc(String docId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(adminCollection)
          .doc(docsCollection)
          .collection('items')
          .doc(docId)
          .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching legal doc: $e');
      return null;
    }
  }

  // Fetch FAQs
  Future<List<Map<String, dynamic>>> getFAQs() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(adminCollection)
          .doc(faqsCollection)
          .collection('items')
          .orderBy('order')
          .get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching FAQs: $e');
      return [];
    }
  }

  // Submit Support Message
  Future<void> submitSupportMessage({
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      await _firestore
          .collection(adminCollection)
          .doc(supportCollection)
          .collection('submissions')
          .add({
            'userId': _auth.currentUser?.uid,
            'name': name,
            'email': email,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'pending',
          });
    } catch (e) {
      throw Exception('Failed to submit support message: $e');
    }
  }

  // Submit Bug Report
  Future<void> submitBugReport({
    required String title,
    required String description,
  }) async {
    try {
      await _firestore
          .collection(adminCollection)
          .doc(bugsCollection)
          .collection('submissions')
          .add({
            'userId': _auth.currentUser?.uid,
            'title': title,
            'description': description,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'pending',
          });
    } catch (e) {
      throw Exception('Failed to submit bug report: $e');
    }
  }
}
