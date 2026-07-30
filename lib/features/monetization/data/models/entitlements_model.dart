import 'package:hive/hive.dart';

import '../../domain/entities/entitlements.dart';

part 'entitlements_model.g.dart';

@HiveType(typeId: 4)
class EntitlementsModel extends HiveObject {
  @HiveField(0)
  int gems;
  @HiveField(1)
  bool adsRemoved;
  @HiveField(2)
  bool subscriptionActive;
  @HiveField(3)
  List<String> ownedProductIds;

  /// Epoch millis del último regalo diario VIP reclamado (null si nunca).
  @HiveField(4)
  int? lastVipClaimMs;

  /// Total de gemas obtenidas de por vida (para la billetera).
  @HiveField(5)
  int totalGemsEarned;

  EntitlementsModel({
    required this.gems,
    required this.adsRemoved,
    required this.subscriptionActive,
    required this.ownedProductIds,
    this.lastVipClaimMs,
    this.totalGemsEarned = 0,
  });

  factory EntitlementsModel.fromEntity(Entitlements e) => EntitlementsModel(
        gems: e.gems,
        adsRemoved: e.adsRemoved,
        subscriptionActive: e.subscriptionActive,
        ownedProductIds: List.from(e.ownedProductIds),
        lastVipClaimMs: e.lastVipClaim?.millisecondsSinceEpoch,
        totalGemsEarned: e.totalGemsEarned,
      );

  Entitlements toEntity() => Entitlements(
        gems: gems,
        totalGemsEarned: totalGemsEarned,
        adsRemoved: adsRemoved,
        subscriptionActive: subscriptionActive,
        ownedProductIds: List.unmodifiable(ownedProductIds),
        lastVipClaim: lastVipClaimMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastVipClaimMs!),
      );
}
