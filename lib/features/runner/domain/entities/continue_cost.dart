/// Política de coste para **retomar la carrera** (revive) tras un golpe mortal.
///
/// Modelo híbrido de coste creciente, kid-safe y determinista (sin azar):
/// las primeras continuaciones se pagan con 🪙 monedas (asequibles, se ganan
/// jugando; dan sumidero a la moneda blanda que sobra) y, a partir de ahí, con
/// 💎 gemas (moneda dura, crea el sumidero que a la economía le falta). El
/// coste sube en cada continuación para que revivir sin fin sea caro.
///
/// Es una función **pura**, sin estado ni persistencia: el contador de
/// continuaciones vive en la partida (`BrixRunGame.continuesUsed`), no en Hive.
library;

/// Con qué moneda se paga una continuación concreta.
enum ContinueCurrency { coins, gems }

/// Oferta de continuación: qué moneda y cuánto cuesta la siguiente reanudación.
class ContinueOffer {
  final ContinueCurrency currency;
  final int amount;

  const ContinueOffer(this.currency, this.amount);

  bool get isCoins => currency == ContinueCurrency.coins;
  bool get isGems => currency == ContinueCurrency.gems;
}

/// Costes de las continuaciones pagadas con **monedas** (por índice 0-based).
/// Las dos primeras reanudaciones son en monedas: asequibles para casi todos
/// (una victoria rinde ~200🪙) y drenan la moneda blanda abundante.
const List<int> kContinueCoinCosts = [100, 250];

/// Coste en **gemas** de la primera continuación pagada con gemas (la 3ª global,
/// índice 2). A partir de ahí el coste se duplica en cada reanudación.
const int kContinueBaseGemCost = 20;

/// Tope del coste en gemas para que no se dispare a cifras absurdas.
const int kContinueMaxGemCost = 320;

/// Devuelve la oferta para la **próxima** continuación, dado cuántas se han
/// usado ya en esta carrera.
///
/// - `continuesUsed == 0` → 1ª continuación (100 🪙)
/// - `continuesUsed == 1` → 2ª continuación (250 🪙)
/// - `continuesUsed == 2` → 3ª continuación (20 💎)
/// - `continuesUsed == 3` → 4ª continuación (40 💎)
/// - `continuesUsed >= 4` → 80, 160, 320… 💎 (con tope [kContinueMaxGemCost])
ContinueOffer continueOfferFor(int continuesUsed) {
  final n = continuesUsed < 0 ? 0 : continuesUsed;
  if (n < kContinueCoinCosts.length) {
    return ContinueOffer(ContinueCurrency.coins, kContinueCoinCosts[n]);
  }
  // Índice dentro del tramo de gemas: 0 → base, 1 → base×2, 2 → base×4…
  final gemStep = n - kContinueCoinCosts.length;
  var cost = kContinueBaseGemCost;
  for (var i = 0; i < gemStep; i++) {
    cost *= 2;
    if (cost >= kContinueMaxGemCost) {
      cost = kContinueMaxGemCost;
      break;
    }
  }
  return ContinueOffer(ContinueCurrency.gems, cost);
}
