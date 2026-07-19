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

  EntitlementsModel({
    required this.gems,
    required this.adsRemoved,
    required this.subscriptionActive,
    required this.ownedProductIds,
  });

  factory EntitlementsModel.fromEntity(Entitlements e) => EntitlementsModel(
        gems: e.gems,
        adsRemoved: e.adsRemoved,
        subscriptionActive: e.subscriptionActive,
        ownedProductIds: List.from(e.ownedProductIds),
      );

  Entitlements toEntity() => Entitlements(
        gems: gems,
        adsRemoved: adsRemoved,
        subscriptionActive: subscriptionActive,
        ownedProductIds: List.unmodifiable(ownedProductIds),
      );
}
