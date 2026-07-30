# Economía de Run For Win — Auditoría, investigación y definición

> Documento vivo. Fecha de esta revisión: 2026-07-30.
> Regla de producto firme: **público infantil (<13), solo IAP, SIN anuncios,
> compuerta parental antes de comprar, sin loot boxes con dinero real, sin
> pay-to-win.** Todo lo que sigue respeta esas restricciones.

Este documento tiene cuatro partes:

1. **Estado actual** — todos los números tal como están hoy en el código.
2. **Hallazgos de congruencia** — dónde la economía no cuadra.
3. **Investigación de mercado** — qué hacen juegos comparables y benchmarks 2025–2026.
4. **Economía recomendada** — la definición completa propuesta (monedas, gemas,
   conversión, precios reales, VIP, faucets/sinks) y el plan de implementación.

---

## 1. Estado actual (auditoría del código)

Hay **dos monedas**:

- 🪙 **Monedas** (*soft currency*): se ganan jugando.
- 💎 **Gemas** (*hard currency*): moneda dura, hoy solo se obtienen pagando o con VIP.

### 1.1 Fuentes de monedas (faucets)

| Fuente | Cantidad | Nota |
|---|---|---|
| Recoger moneda en carrera | +1 (héroe/neutral/misterioso), **+2 villano** | ×1.5 si es VIP (`brix_run_game.dart:665`) |
| Bonus de victoria (jefe) | **+500** por victoria | `victoryCoinBonus = 500` (`brix_run_game.dart:73`) |
| Ruleta diaria | 50 / 100 / 200 / 500 (ponderado) + piezas | pesos 30/25/15/10 (`wallet_repository_impl.dart`) |
| Cofre de racha (racha ≥ 3 días) | 150 + piezas rare/epic/legendary | `earnVipChest = runStreak >= 3` |
| Misiones | 50–200 c/u (3 activas) | **⚠️ NO se acreditan — ver §2.1** |
| Canje de gemas → monedas | 40💎→500🪙 · 100💎→1500🪙 | `gem_product.dart` |

Una carrera **ganada** típica hoy: ~10–30 monedas recogidas **+ 500 de victoria**
≈ **510–530 monedas por victoria**.

### 1.2 Sumideros de monedas (sinks)

| Sumidero | Costo | Detalle |
|---|---|---|
| Cosméticos *rare* | 200 🪙 | 8 piezas en el catálogo |
| Cosméticos *epic* | 500 🪙 | 5 piezas |
| Cosméticos *legendary* | 1000 🪙 | `coinCostForRarity`, pero **0 en catálogo** |
| Cosméticos *common* | gratis | ~52 piezas (65 en total) |
| Desbloqueo de mundos | 500 → 8000 | ver abajo |

**Importante:** los mundos **no se “compran”** con el saldo. Se desbloquean cuando
`totalCoinsEarned` (monedas ganadas de por vida, que solo sube) alcanza el umbral
(`world_selection_page.dart:409`). Es una **barrera de progresión tipo XP**, no un
gasto — comprar cosméticos no retrasa el avance de mundos.

| Mundo | Umbral (lifetime) |
|---|---|
| Galaxia Brix | 500 |
| Jungla Salvaje | 1 200 |
| Ciudad Oscura | 2 200 |
| Fondo del Mar | 3 500 |
| Tundra Helada | 5 500 |
| Metrópolis Robot | 8 000 |
| **Total** | **20 900** |

### 1.3 Fuentes de gemas

| Fuente | Cantidad |
|---|---|
| VIP diario | **25 💎/día** (≈ 750/mes) |
| Compra: “Puñado” | 100 💎 — USD 1.99 |
| Compra: “Cofre” | 550 💎 — USD 8.99 (+10%) |

> **No existe ninguna fuente gratuita de gemas fuera del VIP.** Un jugador que no
> paga nunca obtiene gemas.

### 1.4 Sumideros de gemas (canjería)

| Producto | Precio | ¿También en monedas? |
|---|---|---|
| 500 monedas | 40 💎 | — (12.5 monedas/gema) |
| 1500 monedas | 100 💎 | — (15 monedas/gema) |
| Jetpack | 50 💎 | **Sí: 200 🪙** |
| Medallón dorado | 50 💎 | **Sí: 200 🪙** |
| Capa vampiro | 120 💎 | **Sí: 500 🪙** |
| Botas de propulsión | 120 💎 | **Sí: 500 🪙** |

### 1.5 Tienda de dinero real (IAP)

| Producto | Precio | Entrega |
|---|---|---|
| Club VIP (susc.) | USD 4.99 / mes | 25💎/día + monedas ×1.5 por carrera |
| Puñado de gemas | USD 1.99 | 100 💎 |
| Cofre de gemas | USD 8.99 | 550 💎 (+10%) |
| Pack de bienvenida | USD 3.99 | jetpack + alas + varita + antifaz |

---

## 2. Hallazgos de congruencia (lo que no cuadra)

### 2.1 🔴 Crítico — las misiones prometen monedas que nunca se pagan
`rewardCoins` (50–200) se muestra en la tarjeta de misión, en el banner previo a
la carrera y en el resumen final (`+50 🪙`), pero **al completarse una misión no
se dispara ningún `EarnCoinsEvent`**. `MissionBloc._onAdvance` detecta las misiones
recién completadas (`justCompleted`) y ahí se queda: no hay acreditación al
monedero. El jugador ve una recompensa que nunca recibe. **Debe corregirse antes
de desplegar.**

### 2.2 🔴 Los cosméticos de gemas están *estrictamente dominados* por las monedas
Cada cosmético de la canjería de gemas también se vende por monedas, y siempre
más barato:

| Cosmético | En gemas | Equivalente en monedas (a 15 🪙/💎) | Precio real en monedas | Sobrecosto |
|---|---|---|---|---|
| Jetpack | 50 💎 | ≈ 750 🪙 | **200 🪙** | 3.75× |
| Medallón | 50 💎 | ≈ 750 🪙 | **200 🪙** | 3.75× |
| Capa vampiro | 120 💎 | ≈ 1 800 🪙 | **500 🪙** | 3.6× |
| Botas propulsión | 120 💎 | ≈ 1 800 🪙 | **500 🪙** | 3.6× |

Ningún jugador racional compra estos cosméticos con gemas. La canjería de gemas
no tiene, en la práctica, ningún cosmético que valga la pena.

### 2.3 🔴 Las gemas no tienen faucet gratuito → moneda “muerta” para el 98–99%
Como casi nadie paga (ver §3), y no hay gemas por jugar, para la gran mayoría las
gemas son una UI que nunca se usa: no pueden canjear monedas ni cosméticos de
gemas. Una moneda dura sin *ninguna* vía de obtención por juego se siente como un
muro, no como una aspiración.

### 2.4 🟠 El “Pack de bienvenida” (USD 3.99) es mal negocio
Entrega jetpack + alas + varita + antifaz, **todos comprables con monedas**
(200+200+200+200 = 800 🪙 ≈ **menos de 2 victorias**). Pagar USD 3.99 por algo que
se consigue jugando un rato no convierte a un primer comprador. Los *starter packs*
que sí convierten ofrecen 3–5× de valor y algo **exclusivo**.

### 2.5 🟠 Inflación de monedas: el bonus de victoria aplana la economía
+500 por victoria hace que:
- el 2.º mundo (500) se desbloquee prácticamente con la primera victoria;
- cualquier *epic* (500) cueste **una** victoria.

Las monedas se vuelven abundantes en cuanto sabes ganar, así que los sumideros de
monedas dejan de generar decisiones interesantes y **toda la monetización recae en
las gemas** — que, por §2.2/§2.3, no funcionan. La economía queda sin tensión.

### 2.6 🟡 Precio de gemas por debajo del estándar de anclaje
100 💎 por USD 1.99 ≈ **50 💎 / USD**. El estándar de la industria ronda **~100 unidades
de moneda dura por USD** en el tramo bajo, con bonus creciente en tramos altos. El
tramo grande está en USD 8.99 (poco habitual) en vez de los puntos psicológicos
USD 4.99 / 9.99 / 19.99.

### 2.7 🟡 Código muerto tras quitar la etiqueta de tipo
Al eliminar el badge “Héroe/Villano” (Punto 2 de esta sesión), el helper
`characterType()` de l10n y las claves `type_*` quedan sin uso. Inofensivo, pero
conviene limpiarlo en un pase posterior.

---

## 3. Investigación de mercado (benchmarks 2025–2026 y comparables)

### 3.1 Conversión e ingresos: cómo se comporta el gasto
- **Tasa de pagadores muy baja:** la tasa de *in-app payers* en juegos móviles ronda
  el **0.8%** (casual puede llegar a 1–3%). Es decir, **~99 de cada 100 jugadores
  nunca pagan** → la economía **tiene que ser divertida y completa gratis**, y la
  monetización debe apoyarse en la minoría que sí paga.
- **Los ingresos los llevan los “whales”:** una fracción pequeña de los pagadores
  genera la mayor parte de los ingresos. Por eso importan los tramos altos de gemas
  y una suscripción con valor sostenido.
- **Primer precio:** el tramo de primera compra más común en EE. UU. es **USD 0.99**;
  los precios terminados en .99 (0.99/4.99/9.99/19.99) disparan la compra por impulso.
- **IAP total 2025:** ~USD 81.7 mil millones (Sensor Tower), +1.3% interanual.
- **Suscripciones en auge:** los ingresos por suscripción vía tiendas crecieron
  **~105% interanual** (Q1 2026) — es la palanca de crecimiento del momento.

### 3.2 Juegos infantiles específicamente
- Los juegos *Kids* tienen de los **IPM más altos** (iOS 4.3, Android 6.1) y buen
  **ROAS D30 (~68% en iOS)**: enganchan y retienen bien.
- Pero por COPPA/reglas Kids de las tiendas: **sin analítica de terceros, sin
  publicidad conductual, compra siempre tras compuerta parental** — justo la línea
  que ya sigue Run For Win.

### 3.3 Cómo montan la economía los comparables (endless runners)
- **Subway Surfers:** doble moneda — **Coins** (soft, se juega) + **Keys** (premium).
  Cosméticos (personajes, hoverboards) como motor. Venden una mejora permanente
  **“Double Coins”** muy popular. Monetización **híbrida** (IAP + anuncios).
- **Talking Tom Gold Run, Sonic Dash, Minion Rush:** mismo patrón — doble moneda,
  progresión por cosméticos/personajes, IAP + anuncios, packs de moneda en escalera.

**Implicación para nosotros:** casi todos los comparables **complementan** IAP con
anuncios. Run For Win **renuncia a los anuncios por decisión de producto**, así que
la monetización se apoya **solo** en (a) cosméticos deseables, (b) paquetes de gemas
y (c) VIP. Eso obliga a que esas tres piezas estén **impecables** — hoy las tres
tienen fugas (§2). La ventaja: sin anuncios, el producto es más “premium” y
kid-safe, un argumento de venta real para los padres.

### 3.4 Buenas prácticas de precios de moneda dura
- Packs en escalera ascendente con **bonus creciente** (p. ej. +0% / +10% / +20% / +25%),
  para que el tramo medio-alto “se sienta” como el más inteligente (anclaje).
- **Dar algo de moneda dura gratis** por logros/juego: reduce fricción y hace que la
  moneda “signifique” algo cuando luego se compra.
- La moneda dura debe tener **usos con sentido y exclusivos** (si se consigue igual
  con la soft, nadie la compra — exactamente nuestro §2.2).

---

## 4. Economía recomendada (definición completa)

Principio rector: **gratis debe ser completo y justo**; el dinero **acelera y
embellece**, nunca “gana”. Todo kid-safe.

### 4.1 Roles claros de cada moneda

- 🪙 **Monedas (soft):** se ganan jugando. Compran **la mayoría** de cosméticos y
  marcan la progresión de mundos (umbral lifetime). Abundantes por diseño.
- 💎 **Gemas (hard):** premium. Compran **cosméticos exclusivos** (que NO existen en
  monedas), **atajos de conveniencia** (desbloquear ya un mundo) y **paquetes de
  monedas**. Escasas; con un **goteo gratuito** para que sean aspiracionales.

**Ancla de valor canónica:** `1 💎 ≈ 10 🪙`. Todo se diseña alrededor de esto.

### 4.2 Corrección de fugas (obligatorio antes de desplegar)

1. **Pagar las misiones (§2.1).** Al completar una misión, acreditar `rewardCoins`
   con `EarnCoinsEvent`. Recomendado: acreditar en el **resumen de fin de carrera**
   (una sola vez por misión), con feedback visual.
2. **Quitar el solapamiento de cosméticos (§2.2).** Los 4 cosméticos de la canjería
   de gemas se mantienen **solo en monedas**. La canjería de gemas pasa a vender
   **cosméticos exclusivos nuevos** (skins *epic/legendary* que no están en el
   catálogo de monedas), a 80–250 💎.
3. **Abrir un faucet de gemas gratuito (§2.3):**
   - Ruleta diaria: añadir un tramo de **+5 💎** (peso bajo, p. ej. 8–10%).
   - Hito: al **desbloquear un mundo nuevo**, regalar **+10 💎**.
   - Hito: **completar las 3 misiones del día**, +5 💎.
   Objetivo: un no-pagador constante junta ~20–40 💎/semana → puede aspirar a un
   cosmético de gemas cada cierto tiempo, sin presión.

### 4.3 Ajuste de faucets/sinks de monedas (equilibrio)

- **Bonus de victoria: 500 → ~200** (`victoryCoinBonus`). Sigue siendo un premio
  claro, pero deja de aplanar la economía.
- **Recogidas por carrera:** sin cambio (1 / 2 villano, ×1.5 VIP).
- Con esto, una **victoria** rinde ~220–260 🪙 y un *epic* (500) cuesta ~2 victorias:
  hay una meta real que perseguir.
- **Añadir 2–4 cosméticos *legendary* (1000 🪙)** al catálogo para dar techo a la
  progresión de monedas (hoy el tramo 1000 existe en código pero no en catálogo).
- **Mundos:** mantener como barrera lifetime (progresión). Opcional: permitir
  **saltar** el siguiente mundo por gemas (atajo de conveniencia; ver 4.5).

### 4.4 Canjería de gemas (sinks de gemas, sin dom.)

| Producto | Precio | Notas |
|---|---|---|
| 500 monedas | 40 💎 | 12.5 🪙/💎 — respeta el ancla |
| 1 500 monedas | 100 💎 | 15 🪙/💎 — descuento por volumen |
| Skin exclusivo *epic* (nuevo) | 80–120 💎 | **no existe en monedas** |
| Skin exclusivo *legendary* (nuevo) | 180–250 💎 | pieza estrella |
| Saltar desbloqueo del próximo mundo | 60–150 💎 | conveniencia, no pay-to-win |

### 4.5 Precios de dinero real (IAP) — escalera propuesta

**Gemas** (anclaje ~100 💎/USD en el tramo bajo, bonus creciente):

| Pack | Actual | **Propuesto** |
|---|---|---|
| Puñado | 100 💎 · USD 1.99 | **200 💎 · USD 1.99** (+0%) |
| Cofre | 550 💎 · USD 8.99 | **550 💎 · USD 4.99** (+10%) |
| Baúl | — | **1 200 💎 · USD 9.99** (+20%) |
| Mega (opcional) | — | **2 500 💎 · USD 19.99** (+25%) |

**Pack de bienvenida** (una vez por cuenta, convierte la 1.ª compra):

- **USD 2.99** → **300 💎 + 1 skin EXCLUSIVO + 1 000 🪙**. Valor percibido 3–4× el
  precio; el skin exclusivo es el gancho. Sustituye al pack actual (§2.4).

**Club VIP** (suscripción):

- Mantener **USD 4.99/mes**, pero ahora sus 25💎/día **sí tienen en qué gastarse**
  (skins exclusivos, atajos). Añadir **cosmético exclusivo mensual** y considerar:
  - **Opción anual** ~**USD 29.99/año** (≈ 50% dto., sube el LTV).
  - **Prueba de 3 días** para bajar la fricción del primer pago.
  - Multiplicador de monedas: mantener **×1.5** (×2 vuelve a inflar).

> Todos los SKU deben existir con el mismo `id` en Google Play Console / App Store
> Connect, y toda compra pasa por la compuerta parental (ya implementada).

### 4.6 Tabla resumen de parámetros (objetivo)

| Parámetro | Hoy | Objetivo |
|---|---|---|
| `victoryCoinBonus` | 500 | **200** |
| Moneda por recogida | 1 / 2 (villano) | igual |
| Multiplicador VIP | ×1.5 | igual |
| Recompensa misión | 50–200 (no pagada) | **50–200, pagada** |
| Faucet de gemas gratis | 0 | **ruleta + hitos (~20–40/sem)** |
| Gemas VIP/día | 25 | igual |
| Cosméticos gema exclusivos | 0 | **≥ 4** |
| Legendarios en monedas | 0 | **2–4 @ 1000** |
| Ancla gema→moneda | 12.5–15 | **~10–15 (consistente)** |
| Pack bienvenida | USD 3.99, no exclusivo | **USD 2.99, con exclusivo** |
| Tramos de gemas | 1.99 / 8.99 | **1.99 / 4.99 / 9.99 (/19.99)** |
| Suscripción | 4.99/mes | **4.99/mes (+ anual 29.99, prueba 3 d)** |

### 4.7 Plan de implementación priorizado

1. **P0 (bloquea despliegue):** pagar misiones (§4.2.1); quitar solapamiento de
   cosméticos de gemas (§4.2.2).
2. **P1:** faucet gratuito de gemas (§4.2.3); bajar `victoryCoinBonus` a 200;
   rediseñar el pack de bienvenida (§4.5).
3. **P2:** reescalar tramos de gemas a 1.99/4.99/9.99; añadir skins exclusivos de
   gemas y legendarios de monedas; atajo de mundo por gemas.
4. **P3:** opción anual + prueba de VIP; limpiar código muerto de `characterType`.

---

## Fuentes

- [AppsFlyer — The State of App Monetization 2026](https://www.appsflyer.com/resources/reports/app-marketing-monetization-report/)
- [MAF — Conversion Rates, IPM & IAP Benchmarks for Mobile Games (2026)](https://maf.ad/en/blog/mobile-game-conversion-rates/)
- [Liftoff — 2025 Casual Gaming Apps Report](https://liftoff.ai/2025-casual-gaming-apps-report/)
- [FoxData — Subway Surfers' Monetization Strategies](https://foxdata.com/en/blogs/subway-surfers-ingenious-monetization-strategies/)
- [Subway Surfers Wiki — Currencies](https://subwaysurf.fandom.com/wiki/Currencies)
- [Udonis — Mobile Game Monetization Strategies 2026](https://www.blog.udonis.co/mobile-marketing/mobile-games/mobile-game-monetization)
- [Adapty — Mobile Game Monetization Models 2026](https://adapty.io/blog/mobile-game-monetization/)
