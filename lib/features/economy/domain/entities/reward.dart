import '../../../character_editor/domain/entities/character.dart';

sealed class Reward {
  const Reward();
  String get displayLabel;
  String get emoji;
}

class CoinsReward extends Reward {
  final int amount;
  const CoinsReward(this.amount);

  @override
  String get displayLabel => '$amount monedas';

  @override
  String get emoji => '✦';
}

class PartReward extends Reward {
  final String partId;
  final String partName;
  final AccessoryRarity rarity;

  const PartReward({
    required this.partId,
    required this.partName,
    required this.rarity,
  });

  @override
  String get displayLabel => partName;

  @override
  String get emoji {
    if (rarity == AccessoryRarity.legendary) return '👑';
    if (rarity == AccessoryRarity.epic) return '⚡';
    if (rarity == AccessoryRarity.rare) return '💎';
    return '⚙️';
  }
}
