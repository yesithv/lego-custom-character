/// Lo que el jugador ha desbloqueado con dinero real (o el stub simulado).
///
/// Es el estado persistente de la monetización: saldo de gemas, si se quitaron
/// los anuncios, si la suscripción VIP está activa y qué productos ya posee.
class Entitlements {
  /// Saldo de moneda dura (gemas).
  final int gems;

  /// El jugador compró "quitar anuncios".
  final bool adsRemoved;

  /// Suscripción VIP activa.
  final bool subscriptionActive;

  /// SKUs ya adquiridos (para no volver a ofrecer no-consumibles y para
  /// restaurar compras).
  final List<String> ownedProductIds;

  const Entitlements({
    this.gems = 0,
    this.adsRemoved = false,
    this.subscriptionActive = false,
    this.ownedProductIds = const [],
  });

  /// No se deben mostrar anuncios si se compraron sin anuncios o hay VIP.
  bool get adsDisabled => adsRemoved || subscriptionActive;

  bool owns(String productId) => ownedProductIds.contains(productId);

  Entitlements copyWith({
    int? gems,
    bool? adsRemoved,
    bool? subscriptionActive,
    List<String>? ownedProductIds,
  }) =>
      Entitlements(
        gems: gems ?? this.gems,
        adsRemoved: adsRemoved ?? this.adsRemoved,
        subscriptionActive: subscriptionActive ?? this.subscriptionActive,
        ownedProductIds: ownedProductIds ?? this.ownedProductIds,
      );
}
