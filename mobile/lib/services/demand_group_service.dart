// mobile/lib/services/demand_group_service.dart
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
        minTargetPrice: targetPrice, maxTargetPrice: targetPrice, avgTargetPrice: targetPrice,
        createdAt: DateTime.now(), thresholdReachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: settings.demandExpiryDays)), deliveryDate: deliveryDate,
      );
      await newGroupRef.set(newGroup.toMap());
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
        minTargetPrice: targetPrice, maxTargetPrice: targetPrice, avgTargetPrice: targetPrice,
        createdAt: DateTime.now(), thresholdReachedAt: threshold <= 1 ? DateTime.now() : null,
        expiresAt: DateTime.now().add(Duration(days: settings.demandExpiryDays)), deliveryDate: deliveryDate,
      );
      await newGroupRef.set(newGroup.toMap());
      await _db.collection('demands').doc(demandId).update({'groupId': newGroupRef.id, 'status': newGroup.status});
    } else {
      final groupDoc = groupsQuery.docs.first;
      final group = DemandGroupModel.fromFirestore(groupDoc);
      if (group.members.contains(customerId)) return;
      final newCount = group.memberCount + 1;
      final newStatus = newCount >= group.threshold ? 'threshold_reached' : 'collecting';
      final newTotalQty = group.totalQuantity + quantity;
      final newMinPrice = targetPrice < group.minTargetPrice ? targetPrice : group.minTargetPrice;
      final newMaxPrice = targetPrice > group.maxTargetPrice ? targetPrice : group.maxTargetPrice;
      final newAvgPrice = (group.avgTargetPrice + targetPrice) / 2;
      final bool justReached = (group.status == 'collecting' && newStatus == 'threshold_reached');

      await groupDoc.reference.update({
        'memberCount': newCount, 'members': FieldValue.arrayUnion([customerId]),
        'memberDemandIds': FieldValue.arrayUnion([demandId]), 'totalQuantity': newTotalQty,
        'minTargetPrice': newMinPrice, 'maxTargetPrice': newMaxPrice, 'avgTargetPrice': newAvgPrice,
        'status': newStatus, 'updatedAt': FieldValue.serverTimestamp(),
        if (justReached) 'thresholdReachedAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('demands').doc(demandId).update({'groupId': group.id, 'status': newStatus});
    }
  }
}