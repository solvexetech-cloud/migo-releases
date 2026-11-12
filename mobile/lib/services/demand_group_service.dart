// mobile/lib/services/demand_group_service.dart
// UPDATED - Saves minPrice, maxPrice, brand, urgency, budgetType to demand_groups
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/demand_group_model.dart';
import '../models/demand_settings_model.dart';

class DemandGroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> processNewDemand({
    required String demandId,
    required String title,
    required String category,
    required String zoneId,
    required String countryCode,
    required int quantity,
    required double targetPrice,
    required DateTime? deliveryDate,
    required String customerId,
    // 🆕 New fields
    double? minPrice,
    double? maxPrice,
    String? brand,
    String? urgency,
    String? budgetType,
  }) async {
    final settingsDoc = await _db.collection('app_config').doc('demandSettings').get();
    final settings = settingsDoc.exists ? DemandSettingsModel.fromFirestore(settingsDoc) : DemandSettingsModel.defaults();
    final isBulk = settings.isPrivateBulk(quantity);
    
    if (isBulk) {
      final newGroupRef = _db.collection('demand_groups').doc();
      final newGroup = DemandGroupModel(
        id: newGroupRef.id, title: title, category: category, zoneId: zoneId, countryCode: countryCode,
        memberCount: 1, members: [customerId], memberDemandIds: [demandId], threshold: 1,
        status: 'threshold_reached', totalQuantity: quantity,
        minTargetPrice: minPrice ?? targetPrice, maxTargetPrice: maxPrice ?? targetPrice, avgTargetPrice: targetPrice,
        createdAt: DateTime.now(), thresholdReachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: settings.demandExpiryDays)), deliveryDate: deliveryDate,
      );

      // 🆕 Save with extra fields
      final data = newGroup.toMap();
      data['minPrice'] = minPrice ?? targetPrice;
      data['maxPrice'] = maxPrice ?? targetPrice;
      data['brand'] = brand ?? '';
      data['urgency'] = urgency ?? 'Flexible';
      data['budgetType'] = budgetType ?? 'Flexible';

      await newGroupRef.set(data);
      await _db.collection('demands').doc(demandId).update({'groupId': newGroupRef.id, 'status': 'threshold_reached'});
      return;
    }

    final int threshold = settings.thresholdForCategory(category);
    final groupsQuery = await _db.collection('demand_groups')
        .where('title', isEqualTo: title).where('category', isEqualTo: category)
        .where('zoneId', isEqualTo: zoneId).where('status', whereIn: ['collecting', 'threshold_reached']).get();

    if (groupsQuery.docs.isEmpty) {
      final newGroupRef = _db.collection('demand_groups').doc();
      final newGroup = DemandGroupModel(
        id: newGroupRef.id, title: title, category: category, zoneId: zoneId, countryCode: countryCode,
        memberCount: 1, members: [customerId], memberDemandIds: [demandId], threshold: threshold,
        status: threshold <= 1 ? 'threshold_reached' : 'collecting', totalQuantity: quantity,
        minTargetPrice: minPrice ?? targetPrice, maxTargetPrice: maxPrice ?? targetPrice, avgTargetPrice: targetPrice,
        createdAt: DateTime.now(), thresholdReachedAt: threshold <= 1 ? DateTime.now() : null,
        expiresAt: DateTime.now().add(Duration(days: settings.demandExpiryDays)), deliveryDate: deliveryDate,
      );

      final data = newGroup.toMap();
      data['minPrice'] = minPrice ?? targetPrice;
      data['maxPrice'] = maxPrice ?? targetPrice;
      data['brand'] = brand ?? '';
      data['urgency'] = urgency ?? 'Flexible';
      data['budgetType'] = budgetType ?? 'Flexible';

      await newGroupRef.set(data);
      await _db.collection('demands').doc(demandId).update({'groupId': newGroupRef.id, 'status': newGroup.status});
    } else {
      final groupDoc = groupsQuery.docs.first;
      final group = DemandGroupModel.fromFirestore(groupDoc);
      if (group.members.contains(customerId)) return;
      final newCount = group.memberCount + 1;
      final newStatus = newCount >= group.threshold ? 'threshold_reached' : 'collecting';
      final newTotalQty = group.totalQuantity + quantity;
      final newMinPrice = (minPrice ?? targetPrice) < group.minTargetPrice ? (minPrice ?? targetPrice) : group.minTargetPrice;
      final newMaxPrice = (maxPrice ?? targetPrice) > group.maxTargetPrice ? (maxPrice ?? targetPrice) : group.maxTargetPrice;
      final newAvgPrice = (group.avgTargetPrice + targetPrice) / 2;
      final bool justReached = (group.status == 'collecting' && newStatus == 'threshold_reached');

      await groupDoc.reference.update({
        'memberCount': newCount, 'members': FieldValue.arrayUnion([customerId]),
        'memberDemandIds': FieldValue.arrayUnion([demandId]), 'totalQuantity': newTotalQty,
        'minTargetPrice': newMinPrice, 'maxTargetPrice': newMaxPrice, 'avgTargetPrice': newAvgPrice,
        'minPrice': newMinPrice, 'maxPrice': newMaxPrice, // 🆕 Also update min/max
        'status': newStatus, 'updatedAt': FieldValue.serverTimestamp(),
        if (justReached) 'thresholdReachedAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('demands').doc(demandId).update({'groupId': group.id, 'status': newStatus});
    }
  }
}