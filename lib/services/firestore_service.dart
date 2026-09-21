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
import 'notification_service.dart';
import '../models/cash_advance.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int _pageSize = 20;

  late final CollectionReference _users = _firestore.collection('users');
  late final CollectionReference _products = _firestore.collection('products');
  late final CollectionReference _stockMovements = _firestore.collection('stock_movements');
  late final CollectionReference _deliveries = _firestore.collection('deliveries');
  late final CollectionReference _attendance = _firestore.collection('attendance');
  late final CollectionReference _absenceForms = _firestore.collection('absence_forms');
  late final CollectionReference _payrolls = _firestore.collection('payrolls');
  late final CollectionReference _settings = _firestore.collection('settings');
  late final CollectionReference _cashAdvances = _firestore.collection('cash_advances');

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

  Stream<List<StoreUser>> getUsersPage() {
    return _users.limit(_pageSize).snapshots().map((snapshot) => snapshot.docs
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

  Future<void> deleteUser(String uid) async {
    try {
      await _users.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete employee. Please try again.');
    }
  }

  // ── Products ──────────────────────────────────────

  Future<void> saveProduct(Product product) async {
    await _products.doc(product.id).set(product.toMap(), SetOptions(merge: true));
    if (product.stockQuantity <= product.reorderLevel && product.stockQuantity > 0) {
      await NotificationService.sendLowStockAlert(product.name, product.stockQuantity, product.reorderLevel);
    }
  }

  Stream<List<Product>> getProducts() {
    return _products.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<List<Product>> getProductsPage() {
    return _products.limit(_pageSize).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<List<Product>> getProductsByCategory(String category) {
    return _products
        .where('category', isEqualTo: category)
        .orderBy('name')
        .limit(_pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
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

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      await _products.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update product. Please try again.');
    }
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final snapshot = await _products.where('barcode', isEqualTo: barcode).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<Product?> getProductBySku(String sku) async {
    final snapshot = await _products.where('sku', isEqualTo: sku).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
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

  Stream<List<StockMovement>> getStockMovementsByUser(String userId) {
    return _stockMovements
        .where('performedBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockMovement.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
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
        .limit(_pageSize)
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

  Future<String> addAttendanceAndReturnId(AttendanceRecord record) async {
    try {
      final doc = await _attendance.add(record.toMap());
      return doc.id;
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
        .limit(_pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<AttendanceRecord?> getLatestAttendance(String employeeId) async {
    final query = await _attendance
        .where('employeeId', isEqualTo: employeeId)
        .get();
    if (query.docs.isEmpty) return null;
    final records = query.docs
        .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return records.first;
  }

  Future<AttendanceRecord?> getTodaysAttendance(String employeeId) async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final query = await _attendance
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isEqualTo: dateStr)
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
      await NotificationService.sendAbsenceRequest(form.employeeName, form.reason, form.employeeId);
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

  Future<void> updateAbsenceFormStatus(String id, String status, {String? rejectionComment}) async {
    try {
      final data = <String, dynamic>{'status': status, 'reviewedAt': DateTime.now()};
      if (rejectionComment != null && rejectionComment.isNotEmpty) {
        data['rejectionComment'] = rejectionComment;
      }
      await _absenceForms.doc(id).update(data);
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

  Future<void> updatePayroll(String id, Map<String, dynamic> data) async {
    try {
      await _payrolls.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update payroll record.');
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

  // ── Cash Advances ──────────────────────────────

  Future<void> addCashAdvance(CashAdvance advance) async {
    try {
      await _cashAdvances.add(advance.toMap());
      await NotificationService.sendCashAdvanceRequest(advance.employeeName, advance.amount, advance.employeeId);
    } catch (e) {
      throw Exception('Failed to submit cash advance. Please try again.');
    }
  }

  Stream<List<CashAdvance>> getCashAdvances() {
    return _cashAdvances
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CashAdvance.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<CashAdvance>> getCashAdvancesByUser(String userId) {
    return _cashAdvances
        .where('employeeId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CashAdvance.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt)));
  }

  Future<void> updateCashAdvance(String id, Map<String, dynamic> data) async {
    try {
      await _cashAdvances.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update cash advance. Please try again.');
    }
  }

  // ── Pagination Load More ──────────────────────────

  Future<List<StoreUser>> loadMoreUsers(DocumentSnapshot lastDoc) async {
    final snap = await _users.startAfterDocument(lastDoc).limit(_pageSize).get();
    return snap.docs
        .map((doc) => StoreUser.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> loadMoreProducts(DocumentSnapshot lastDoc) async {
    final snap = await _products.startAfterDocument(lastDoc).limit(_pageSize).get();
    return snap.docs
        .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Delivery>> loadMoreDeliveries(DocumentSnapshot lastDoc) async {
    final snap = await _deliveries
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDoc)
        .limit(_pageSize)
        .get();
    return snap.docs
        .map((doc) => Delivery.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceRecord>> loadMoreAttendance(DocumentSnapshot lastDoc) async {
    final snap = await _attendance
        .orderBy('date', descending: true)
        .startAfterDocument(lastDoc)
        .limit(_pageSize)
        .get();
    return snap.docs
        .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }
}
