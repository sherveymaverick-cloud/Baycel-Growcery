import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/delivery.dart';
import '../models/attendance.dart';
import '../models/absence_form.dart';
import '../models/payroll.dart';
import '../models/settings.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference _users = _firestore.collection('users');
  late final CollectionReference _products = _firestore.collection('products');
  late final CollectionReference _stockMovements = _firestore.collection('stock_movements');
  late final CollectionReference _deliveries = _firestore.collection('deliveries');
  late final CollectionReference _attendance = _firestore.collection('attendance');
  late final CollectionReference _absenceForms = _firestore.collection('absence_forms');
  late final CollectionReference _payrolls = _firestore.collection('payrolls');
  late final CollectionReference _settings = _firestore.collection('settings');

  // ── Users ──────────────────────────────────────────

  Future<void> saveUser(StoreUser user) async {
    try {
      await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user profile. Please try again.');
    }
  }

  Future<StoreUser?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    final doc = await _users.doc(currentUser.uid).get();
    if (!doc.exists) return null;
    return StoreUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Stream<StoreUser?> currentUserStream() {
    final auth = _auth.currentUser;
    if (auth == null) return Stream.value(null);
    return _users.doc(auth.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StoreUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  Stream<List<StoreUser>> getUsers() {
    return _users.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => StoreUser.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _users.doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update employee. Please try again.');
    }
  }

  Future<StoreUser?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return StoreUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // ── Products ──────────────────────────────────────

  Future<void> saveProduct(Product product) async {
    await _products.doc(product.id).set(product.toMap(), SetOptions(merge: true));
  }

  Stream<List<Product>> getProducts() {
    return _products.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> addProduct(Product product) async {
    try {
      await _products.add(product.toMap());
    } catch (e) {
      throw Exception('Failed to add product. Please try again.');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _products.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product. Please try again.');
    }
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // ── Stock Movements ──────────────────────────────

  Future<void> addStockMovement(StockMovement movement) async {
    await _stockMovements.add(movement.toMap());
  }

  Stream<List<StockMovement>> getStockMovements() {
    return _stockMovements
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockMovement.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ── Deliveries ──────────────────────────────────

  Future<void> addDelivery(Delivery delivery) async {
    try {
      await _deliveries.add(delivery.toMap());
    } catch (e) {
      throw Exception('Failed to add delivery. Please try again.');
    }
  }

  Future<void> updateDelivery(String id, Map<String, dynamic> data) async {
    try {
      await _deliveries.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update delivery. Please try again.');
    }
  }

  Stream<List<Delivery>> getDeliveries() {
    return _deliveries
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Delivery.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ── Attendance ──────────────────────────────────

  Future<void> addAttendance(AttendanceRecord record) async {
    try {
      await _attendance.add(record.toMap());
    } catch (e) {
      throw Exception('Failed to record attendance. Please try again.');
    }
  }

  Future<void> updateAttendance(String id, Map<String, dynamic> data) async {
    try {
      await _attendance.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update attendance. Please try again.');
    }
  }

  Stream<List<AttendanceRecord>> getAttendance() {
    return _attendance
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<AttendanceRecord?> getLatestAttendance(String employeeId) async {
    final query = await _attendance
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // ── Absence Forms ──────────────────────────────

  Future<void> addAbsenceForm(AbsenceForm form) async {
    try {
      await _absenceForms.add(form.toMap());
    } catch (e) {
      throw Exception('Failed to submit absence form. Please try again.');
    }
  }

  Stream<List<AbsenceForm>> getAbsenceForms() {
    return _absenceForms
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsenceForm.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> updateAbsenceFormStatus(String id, String status) async {
    try {
      await _absenceForms.doc(id).update({'status': status});
    } catch (e) {
      throw Exception('Failed to update absence form. Please try again.');
    }
  }

  // ── Payroll ──────────────────────────────────────

  Future<void> addPayroll(PayrollRecord payroll) async {
    try {
      await _payrolls.add(payroll.toMap());
    } catch (e) {
      throw Exception('Failed to add payroll record. Please try again.');
    }
  }

  Future<void> deletePayroll(String id) async {
    try {
      await _payrolls.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete payroll record.');
    }
  }

  Stream<List<PayrollRecord>> getPayrolls() {
    return _payrolls
        .orderBy('periodEnd', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PayrollRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ── Settings ──────────────────────────────────────

  Future<void> saveSettings(StoreSettings settings) async {
    try {
      await _settings.doc('default').set(settings.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save settings. Please try again.');
    }
  }

  Stream<StoreSettings?> getSettings() {
    return _settings.doc('default').snapshots().map((doc) {
      if (!doc.exists) return null;
      return StoreSettings.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }
}
