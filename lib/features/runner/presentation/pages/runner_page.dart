import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/orientation/portrait_lock.dart';
import '../../../../core/services/audio_service.dart';
import '../../../analytics/domain/analytics_service.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../../character_editor/presentation/widgets/character_preview.dart';
import '../../../economy/presentation/bloc/wallet_bloc.dart';
import '../../../economy/presentation/bloc/wallet_event.dart';
import '../../../economy/presentation/bloc/wallet_state.dart';
import '../../../economy/presentation/widgets/chest_opening_widget.dart';
import '../../../missions/domain/entities/mission.dart';
import '../../../missions/presentation/bloc/mission_bloc.dart';
import '../../../missions/presentation/bloc/mission_event.dart';
import '../../../missions/presentation/bloc/mission_state.dart';
import '../../../missions/presentation/widgets/mission_card.dart';
import '../../../monetization/domain/entities/vip_perks.dart';
import '../../../monetization/domain/repositories/store_repository.dart';
import '../../../ranking/domain/entities/score.dart';
import '../../../ranking/presentation/bloc/ranking_bloc.dart';
import '../../../ranking/presentation/bloc/ranking_event.dart';
import '../../../ranking/presentation/bloc/ranking_state.dart';
import '../../data/tutorial_prefs.dart';
import '../../domain/entities/continue_cost.dart';
import '../../domain/entities/world_config.dart';
import '../game/brix_run_game.dart';
import '../game/hud_data.dart';
import '../input/swipe_detector.dart';
import 'world_selection_page.dart';

part 'runner_hud.dart';
part 'runner_overlays.dart';

class RunnerPage extends StatefulWidget {
  final Character character;
  final String worldId;
  final String worldName;
  final String worldEmoji;
  final Color worldColor;

  /// Pista de fondo elegida para esta partida (relativa a `assets/audio/`).
  /// `null` si el jugador desactivó la música antes de correr.
  final String? musicAsset;

  const RunnerPage({
    super.key,
    required this.character,
    required this.worldId,
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
    this.musicAsset,
  });

  @override
  State<RunnerPage> createState() => _RunnerPageState();
}

class _RunnerPageState extends State<RunnerPage> {
  late final BrixRunGame _game;
  static const double _swipeThreshold = 40.0;
  bool _showChest = false;
  bool _isPaused = false;

  /// Si ya se abrió el cofre de esta partida. Evita reclamarlo dos veces
  /// (el cofre otorga la recompensa al mostrarse) y, en la victoria, cambia
  /// el botón "Reclamar cofre" por las acciones de navegación.
  bool _chestClaimed = false;

  /// Cuántas monedas recogidas en la carrera en curso ya se han **abonado** a la
  /// billetera. Al morir se abonan las monedas de la carrera para que el jugador
  /// pueda gastarlas al revivir (y no se pierdan si abandona); este contador
  /// evita volver a abonarlas al terminar la carrera (sin doble conteo). Se
  /// reinicia con cada nueva carrera (`restart`).
  int _coinsBankedThisRun = 0;

  @override
  void initState() {
    super.initState();
    // Los VIP ganan monedas con un multiplicador (beneficio de suscripción).
    final vip = sl<StoreRepository>().entitlementsSync().subscriptionActive;
    // Tutorial guiado: solo en las pistas gratis y durante las primeras carreras.
    final showTutorial =
        isTutorialWorld(widget.worldId) && TutorialPrefs.shouldShow();
    _game = BrixRunGame(
      appearance: widget.character.appearance,
      characterType: widget.character.type,
      worldId: widget.worldId,
      onRunComplete: _onRunComplete,
      onHit: _onHit,
      onOfferContinue: _onOfferContinue,
      coinMultiplier: vip ? VipPerks.coinMultiplier : 1.0,
      showTutorial: showTutorial,
    );
    if (showTutorial) {
      // Cuenta esta exposición del tutorial (a las 3 deja de aparecer).
      TutorialPrefs.incrementSeen();
    }
    sl<AnalyticsService>()
        .track(AnalyticsEvents.runStart, params: {'world': widget.worldId});
    // Pre-load ranking for this world to show personal best in game over
    context.read<RankingBloc>().add(LoadRanking(widget.worldId));
    // Música de fondo temática del mundo elegida antes de correr (en bucle).
    _startMusic();
    // En la web móvil el navegador puede quedarse en horizontal: mientras el
    // aviso de "gira tu teléfono" tapa la partida, el motor se pausa para que
    // el jugador no muera a ciegas.
    landscapeBlocked.addListener(_onLandscapeBlockedChanged);
  }

  /// Arranca la música de fondo del mundo (en bucle) si el jugador la dejó
  /// activada antes de correr; si la desactivó, garantiza silencio de música.
  /// Se usa al entrar y al reiniciar la partida.
  void _startMusic() {
    final asset = widget.musicAsset;
    if (asset != null) {
      AudioService.instance.playMusic(asset);
    } else {
      AudioService.instance.stopMusic();
    }
  }

  void _onLandscapeBlockedChanged() {
    if (landscapeBlocked.value) {
      _game.pauseEngine();
      AudioService.instance.pauseMusic();
      return;
    }
    // Al volver a vertical solo se reanuda si la partida sigue viva, el jugador
    // no la había pausado a mano y no está decidiendo si paga por continuar.
    final runOver = !_game.isAlive || _game.phase == GamePhase.victory;
    if (!_isPaused && !runOver && !_game.awaitingContinue) {
      _game.resumeEngine();
      AudioService.instance.resumeMusic();
    }
  }

  /// Paga las recompensas de las misiones recién completadas: monedas (que hasta
  /// ahora se mostraban pero NUNCA se acreditaban) y un pequeño faucet de gemas.
  void _rewardCompletedMissions(List<Mission> completed) {
    if (completed.isEmpty) return;
    final coins = completed.fold<int>(0, (sum, m) => sum + m.rewardCoins);
    if (coins > 0) {
      context.read<WalletBloc>().add(EarnCoinsEvent(coins));
    }
    final gems = completed.length * kGemsPerCompletedMission;
    if (gems > 0) {
      // Fire-and-forget: incrementa el saldo de gemas (entitlements) en local.
      sl<StoreRepository>().grantGems(gems);
    }
  }

  void _onRunComplete(int coins) {
    // La carrera terminó (derrota o victoria): corta la música de fondo de
    // inmediato para que no siga sonando bajo la pantalla de fin de partida.
    AudioService.instance.stopMusic();
    // Solo se acredita el remanente aún no abonado (parte de las monedas de la
    // carrera pudo abonarse ya en las ofertas de continuar). `RecordRunEvent`
    // suma el remanente y actualiza la racha una sola vez (aunque sea 0).
    final unbanked = coins - _coinsBankedThisRun;
    context.read<WalletBloc>().add(RecordRunEvent(unbanked));
    context.read<MissionBloc>().add(AdvanceMissionsEvent(MissionRunData(
      coins: _game.coins,
      meters: _game.meters,
      evadedObstacles: _game.maxObstacleStreak,
      seconds: _game.elapsedSeconds.floor(),
      jumps: _game.jumpCount,
    )));
    context.read<RankingBloc>().add(SubmitScoreEvent(Score(
      id: const Uuid().v4(),
      characterName: widget.character.name,
      worldId: widget.worldId,
      score: _game.score,
      meters: _game.meters,
      coins: _game.coins,
      createdAt: DateTime.now(),
    )));
    // En derrota el cofre se abre automáticamente; en victoria se reclama
    // con el botón "Reclamar cofre" de la pantalla de victoria.
    final isVictory = _game.phase == GamePhase.victory;
    sl<AnalyticsService>().track(
      isVictory ? AnalyticsEvents.runVictory : AnalyticsEvents.runDeath,
      params: {
        'world': widget.worldId,
        'meters': _game.meters,
        'coins': _game.coins,
      },
    );
    setState(() {
      _showChest = !isVictory;
      _isPaused = false;
    });
  }

  void _onHit() {
    HapticFeedback.heavyImpact();
  }

  /// El juego avisa de un golpe mortal y ofrece retomar la carrera pagando.
  /// La partida ya quedó pausada con el overlay de continuación; aquí solo se
  /// refresca la UI y se registra el evento de analítica.
  void _onOfferContinue() {
    // Abona a la billetera las monedas recogidas en la carrera que aún no se
    // habían abonado, para que cuenten como saldo gastable al revivir (y queden
    // guardadas si el jugador abandona). El remanente se descuenta al terminar
    // para no duplicar (ver `_onRunComplete`). No toca `game.coins` (el HUD no
    // se reinicia).
    final unbanked = _game.coins - _coinsBankedThisRun;
    if (unbanked > 0) {
      context.read<WalletBloc>().add(EarnCoinsEvent(unbanked));
      _coinsBankedThisRun = _game.coins;
    }
    final offer = continueOfferFor(_game.continuesUsed);
    sl<AnalyticsService>().track(AnalyticsEvents.continueOffer, params: {
      'world': widget.worldId,
      'index': _game.continuesUsed,
      'currency': offer.currency.name,
      'amount': offer.amount,
    });
    // La música se atenúa mientras se decide (no se corta: la carrera sigue viva).
    AudioService.instance.pauseMusic();
    if (mounted) setState(() => _isPaused = false);
  }

  /// Cobra el coste de la continuación con la moneda que toque y, si el pago
  /// prospera, retoma la carrera en el mismo punto. Devuelve `false` si no se
  /// pudo pagar (saldo insuficiente), para que el overlay muestre el aviso.
  Future<bool> _payAndContinue() async {
    final offer = continueOfferFor(_game.continuesUsed);
    if (offer.isCoins) {
      final coins = context.read<WalletBloc>().state.wallet.coins;
      if (coins < offer.amount) return false;
      context.read<WalletBloc>().add(SpendCoinsEvent(offer.amount));
    } else {
      final gems = sl<StoreRepository>().entitlementsSync().gems;
      if (gems < offer.amount) return false;
      final result = await sl<StoreRepository>().spendGems(offer.amount);
      if (!result.success) return false;
    }
    sl<AnalyticsService>().track(AnalyticsEvents.continuePurchase, params: {
      'world': widget.worldId,
      'index': _game.continuesUsed,
      'currency': offer.currency.name,
      'amount': offer.amount,
    });
    AudioService.instance.resumeMusic();
    _game.continueRun();
    if (mounted) setState(() {});
    return true;
  }

  /// El jugador renuncia a continuar: la carrera termina y va al Game Over.
  void _declineContinue() {
    sl<AnalyticsService>().track(AnalyticsEvents.continueDecline, params: {
      'world': widget.worldId,
      'index': _game.continuesUsed,
    });
    _game.declineContinue();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    landscapeBlocked.removeListener(_onLandscapeBlockedChanged);
    AudioService.instance.stopMusic();
    _game.dispose();
    super.dispose();
  }

  // ── Swipe ───────────────────────────────────────────────────────────────────
  // La política del gesto vive en [SwipeDetector] (presentation/input/), que la
  // resuelve MIENTRAS el dedo se mueve en vez de al levantarlo. Aquí solo se
  // cablea y se traduce la acción a los controles del juego.

  final SwipeDetector _swipes = SwipeDetector(flickVelocity: _swipeThreshold);

  void _handlePanStart(DragStartDetails d) => _swipes.start(d.localPosition);

  void _handlePanUpdate(DragUpdateDetails d) {
    if (_isPaused) return;
    _apply(_swipes.update(d.localPosition));
  }

  void _handlePanEnd(DragEndDetails d) {
    final action = _swipes.end(d.velocity.pixelsPerSecond);
    if (_isPaused) return;
    _apply(action);
  }

  /// Ejecuta la acción de un gesto sobre el juego. `null` = el gesto aún no ha
  /// producido nada.
  void _apply(SwipeAction? action) {
    switch (action) {
      case null:
        return;
      case SwipeAction.left:
        _moveLane(_game.onSwipeLeft());
      case SwipeAction.right:
        _moveLane(_game.onSwipeRight());
      case SwipeAction.up:
        _game.onSwipeUp();
      case SwipeAction.down:
        _game.onSwipeDown();
    }
  }

  /// Golpecito seco solo cuando el corredor cambia de carril de verdad: en los
  /// bordes de la pista no hay a dónde ir, y vibrar ahí le diría al jugador que
  /// se movió cuando no lo hizo.
  void _moveLane(bool moved) {
    if (moved) HapticFeedback.selectionClick();
  }

  /// Toque por zonas de la pantalla (además del swipe): tercio izquierdo →
  /// izquierda, tercio derecho → derecha, centro-arriba → saltar, centro-abajo
  /// → agacharse. El `GestureDetector` ocupa toda la pantalla, así que
  /// `localPosition` y el tamaño de pantalla coinciden.
  void _handleTapUp(TapUpDetails d) {
    if (_isPaused) return;
    final size = MediaQuery.sizeOf(context);
    final dx = d.localPosition.dx;
    final third = size.width / 3;
    if (dx < third) {
      if (_game.onSwipeLeft()) HapticFeedback.selectionClick();
    } else if (dx > third * 2) {
      if (_game.onSwipeRight()) HapticFeedback.selectionClick();
    } else if (d.localPosition.dy < size.height / 2) {
      _game.onSwipeUp();
    } else {
      _game.onSwipeDown();
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _game.pauseEngine();
        // Al pausar también se calla la música de fondo.
        AudioService.instance.pauseMusic();
      } else {
        _game.resumeEngine();
        AudioService.instance.resumeMusic();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Paga las misiones recién completadas (monedas + gemas) una sola vez
          // por carrera: se dispara cuando `justCompleted` pasa a no vacío.
          BlocListener<MissionBloc, MissionState>(
            listenWhen: (p, c) =>
                c.justCompleted.isNotEmpty &&
                p.justCompleted != c.justCompleted,
            listener: (context, missionState) =>
                _rewardCompletedMissions(missionState.justCompleted),
            child: const SizedBox.shrink(),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            onTapUp: _handleTapUp,
            child: GameWidget<BrixRunGame>(
              game: _game,
              overlayBuilderMap: {
                'hud': (context, game) => _HudOverlay(
                      game: game,
                      onTogglePause: _togglePause,
                    ),
                'gameOver': (context, game) =>
                    BlocBuilder<MissionBloc, MissionState>(
                      builder: (context, missionState) => _GameOverOverlay(
                        game: game,
                        character: widget.character,
                        completedMissions: missionState.justCompleted,
                        worldId: widget.worldId,
                        worldName: widget.worldName,
                        worldEmoji: widget.worldEmoji,
                        worldColor: widget.worldColor,
                        onRestart: () {
                          setState(() {
                            _showChest = false;
                            _chestClaimed = false;
                            _isPaused = false;
                            _coinsBankedThisRun = 0;
                          });
                          game.restart();
                          // La música se cortó al terminar la carrera anterior:
                          // vuelve a arrancarla para la nueva.
                          _startMusic();
                        },
                        onExit: () => context.goNamed('worlds'),
                      ),
                    ),
                'victory': (context, game) =>
                    BlocBuilder<MissionBloc, MissionState>(
                      builder: (context, missionState) => _VictoryOverlay(
                        game: game,
                        character: widget.character,
                        completedMissions: missionState.justCompleted,
                        worldId: widget.worldId,
                        worldName: widget.worldName,
                        worldEmoji: widget.worldEmoji,
                        worldColor: widget.worldColor,
                        chestClaimed: _chestClaimed,
                        // Guarda: el cofre entrega la recompensa al mostrarse,
                        // así que nunca debe abrirse dos veces.
                        onClaimChest: () {
                          if (_chestClaimed || _showChest) return;
                          setState(() => _showChest = true);
                        },
                        onRestart: () {
                          setState(() {
                            _showChest = false;
                            _chestClaimed = false;
                            _isPaused = false;
                            _coinsBankedThisRun = 0;
                          });
                          game.restart();
                          // La música se cortó al terminar la carrera anterior:
                          // vuelve a arrancarla para la nueva.
                          _startMusic();
                        },
                        onExit: () => context.goNamed('worlds'),
                      ),
                    ),
                // Oferta de retomar la carrera pagando, antes del Game Over.
                'continue': (context, game) =>
                    BlocBuilder<WalletBloc, WalletState>(
                      builder: (context, walletState) => _ContinueOverlay(
                        offer: continueOfferFor(game.continuesUsed),
                        coins: walletState.wallet.coins,
                        gems: sl<StoreRepository>().entitlementsSync().gems,
                        onPay: _payAndContinue,
                        onDecline: _declineContinue,
                        onGetGems: () => context.pushNamed('store'),
                      ),
                    ),
              },
            ),
          ),

          // Pause overlay
          if (_isPaused)
            _PauseOverlay(
              onResume: _togglePause,
              onExit: () => context.goNamed('worlds'),
            ),

          // Chest overlay — shown after game over
          if (_showChest)
            BlocBuilder<WalletBloc, WalletState>(
              builder: (context, state) => ChestOpeningWidget(
                isVip: state.wallet.earnVipChest,
                onDismiss: () => setState(() {
                  _showChest = false;
                  _chestClaimed = true;
                }),
              ),
            ),
        ],
      ),
    );
  }
}

