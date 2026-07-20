/// Lo que el jugador ha desbloqueado con dinero real (o el stub simulado).
///
/// Es el estado persistente de la monetización: saldo de gemas, si se quitaron
/// los anuncios, si la suscripción VIP está activa y qué productos ya posee.
class Entitlements {
  /// Saldo de moneda dura (gemas).
  final int gems;

  /// El jugador compró "quitar anuncios". (Vestigial: el producto ya no se
  /// vende porque no hay anuncios; se conserva por estabilidad del esquema.)
  final bool adsRemoved;

  /// Suscripción VIP activa.
  final bool subscriptionActive;

  /// SKUs ya adquiridos (para no volver a ofrecer no-consumibles y para
  /// restaurar compras).
  final List<String> ownedProductIds;

  /// Último día en que se reclamó el regalo diario VIP (null si nunca).
  final DateTime? lastVipClaim;

  const Entitlements({
    this.gems = 0,
    this.adsRemoved = false,
    this.subscriptionActive = false,
    this.ownedProductIds = const [],
    this.lastVipClaim,
  });

  /// No se deben mostrar anuncios si se compraron sin anuncios o hay VIP.
  bool get adsDisabled => adsRemoved || subscriptionActive;

  bool owns(String productId) => ownedProductIds.contains(productId);

  /// Si el VIP puede reclamar hoy su regalo diario (por día natural local).
  bool get canClaimVipDaily {
    if (!subscriptionActive) return false;
    final last = lastVipClaim;
    if (last == null) return true;
    final now = DateTime.now();
    final l = last.toLocal();
    return now.year != l.year || now.month != l.month || now.day != l.day;
  }

  Entitlements copyWith({
    int? gems,
    bool? adsRemoved,
    bool? subscriptionActive,
    List<String>? ownedProductIds,
    DateTime? lastVipClaim,
  }) =>
      Entitlements(
        gems: gems ?? this.gems,
        adsRemoved: adsRemoved ?? this.adsRemoved,
        subscriptionActive: subscriptionActive ?? this.subscriptionActive,
        ownedProductIds: ownedProductIds ?? this.ownedProductIds,
        lastVipClaim: lastVipClaim ?? this.lastVipClaim,
      );
}
