import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/test_mode/test_mode.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../economy/domain/entities/part_catalog.dart';
import '../../../economy/presentation/bloc/wallet_bloc.dart';
import '../../../economy/presentation/bloc/wallet_event.dart';
import '../../../economy/presentation/bloc/wallet_state.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/preset_characters.dart';
import '../bloc/character_editor_bloc.dart';
import '../bloc/character_editor_event.dart';
import '../bloc/character_editor_state.dart';
import '../widgets/character_preview.dart';

class CharacterEditorPage extends StatelessWidget {
  final String? characterId;
  final PresetCharacter? preset;

  const CharacterEditorPage({super.key, this.characterId, this.preset});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<CharacterEditorBloc>()..add(const LoadCharacters());
        if (characterId != null) {
          bloc.add(LoadCharacterForEdit(characterId!));
        } else if (preset != null) {
          bloc.add(StartFromPreset(preset!));
        } else {
          bloc.add(const StartNewCharacter());
        }
        return bloc;
      },
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  /// Cuando es true, tras guardar con éxito se va a elegir mundo (correr) en
  /// vez de volver a la galería. Lo activa el botón "Guardar y jugar".
  bool _playAfterSave = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CharacterEditorBloc, CharacterEditorState>(
      listenWhen: (prev, curr) =>
          curr.showSaveSuccess || curr.status == EditorStatus.error,
      listener: (context, state) {
        if (state.showSaveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Personaje guardado!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (_playAfterSave) {
            _playAfterSave = false;
            final id = state.currentCharacter?.id;
            context.goNamed(
              'worlds',
              queryParameters:
                  id != null ? {'character': id} : const <String, String>{},
            );
          } else {
            context.goNamed('gallery');
          }
        }
        if (state.status == EditorStatus.error && state.errorMessage != null) {
          _playAfterSave = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1424),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1466C8),
          elevation: 0,
          leading: BackButton(
            color: Colors.white,
            onPressed: () => context.goNamed('gallery'),
          ),
          title: BlocBuilder<CharacterEditorBloc, CharacterEditorState>(
            buildWhen: (p, c) => p.currentCharacter?.name != c.currentCharacter?.name,
            builder: (context, state) => Text(
              state.currentCharacter?.name.isEmpty ?? true
                  ? 'Nuevo personaje'
                  : state.currentCharacter!.name,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          actions: [
            // Guardar y correr de una vez con este personaje.
            IconButton(
              tooltip: 'Guardar y jugar',
              onPressed: () {
                _playAfterSave = true;
                context
                    .read<CharacterEditorBloc>()
                    .add(const SaveCurrentCharacter());
              },
              icon: const Icon(Icons.sports_score_rounded,
                  color: Color(0xFF43A047), size: 30),
            ),
            BlocBuilder<CharacterEditorBloc, CharacterEditorState>(
              builder: (context, state) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Material(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context
                        .read<CharacterEditorBloc>()
                        .add(const SaveCurrentCharacter()),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: state.status == EditorStatus.saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black87,
                              ),
                            )
                          : const Icon(Icons.save_rounded,
                              color: Colors.black87, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<CharacterEditorBloc, CharacterEditorState>(
          builder: (context, state) {
            if (state.currentCharacter == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                // Character preview + name
                _PreviewSection(character: state.currentCharacter!),
                // Category tabs
                Expanded(
                  child: _EditorTabs(
                    appearance: state.currentCharacter!.appearance,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PreviewSection extends StatefulWidget {
  final Character character;
  const _PreviewSection({required this.character});

  @override
  State<_PreviewSection> createState() => _PreviewSectionState();
}

class _PreviewSectionState extends State<_PreviewSection> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1466C8), Color(0xFF0A3D80)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.horizontal,
        16,
        AppSpacing.horizontal,
        24,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tarjeta translúcida detrás de la figura: hace que cada pieza resalte
          // y que se note al instante cada cambio de personalización.
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child:
                CharacterPreview(appearance: widget.character.appearance, size: 84),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'NOMBRE',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  onChanged: (v) =>
                      context.read<CharacterEditorBloc>().add(UpdateName(v)),
                  decoration: InputDecoration(
                    hintText: 'Nombre del personaje',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                _WalletPill(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Píldora con el saldo de monedas del jugador (borde dorado).
class _WalletPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF063574).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '${state.wallet.coins}',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorTabs extends StatelessWidget {
  final CharacterAppearance appearance;
  const _EditorTabs({required this.appearance});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          // Fondo oscuro para que las pestañas contrasten con el tema.
          Container(
            color: const Color(0xFF121A2C),
            child: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Color(0xFFFFD700),
              unselectedLabelColor: Colors.white70,
              indicatorColor: Color(0xFFFFD700),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: 'Cabeza'),
                Tab(text: 'Cabello'),
                Tab(text: 'Torso'),
                Tab(text: 'Piernas'),
                Tab(text: 'Accesorios'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF0E1424),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: TabBarView(
                  children: [
                    _SkinColorTab(appearance: appearance),
                    _HairTab(appearance: appearance),
                    _TorsoTab(appearance: appearance),
                    _LegsTab(appearance: appearance),
                    _AccessoriesTab(appearance: appearance),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Skin color + facial features ──────────────────────────────────────

class _SkinColorTab extends StatelessWidget {
  final CharacterAppearance appearance;
  const _SkinColorTab({required this.appearance});

  static const _skinColors = {
    SkinTone.light: Color(0xFFFFDBAC),
    SkinTone.medium: Color(0xFFD4A574),
    SkinTone.dark: Color(0xFF8D5524),
    SkinTone.blue: Colors.blue,
    SkinTone.green: Colors.green,
    SkinTone.purple: Colors.purple,
    SkinTone.orange: Colors.orange,
    SkinTone.silver: Colors.grey,
    SkinTone.gold: Color(0xFFFFD700),
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.scrollContent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Color de piel', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SkinTone.values.map((tone) {
              final color = _skinColors[tone]!;
              final isSelected = appearance.skinTone == tone;
              return GestureDetector(
                onTap: () => context.read<CharacterEditorBloc>().add(
                      UpdateAppearance(appearance.copyWith(skinTone: tone)),
                    ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFD700)
                          : Colors.white24,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Ojos', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<EyeStyle>(
            values: EyeStyle.values,
            selected: appearance.eyes,
            label: _eyeLabel,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(eyes: e)),
                ),
          ),
          const SizedBox(height: 16),
          const Text('Cejas', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<EyebrowStyle>(
            values: EyebrowStyle.values,
            selected: appearance.eyebrows,
            label: _eyebrowLabel,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(eyebrows: e)),
                ),
          ),
          const SizedBox(height: 16),
          const Text('Boca', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<MouthStyle>(
            values: MouthStyle.values,
            selected: appearance.mouth,
            label: _mouthLabel,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(mouth: e)),
                ),
          ),
          const SizedBox(height: 20),
          const Text('Extras faciales',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<FacialExtra>(
            values: FacialExtra.values,
            selected: appearance.facialExtra,
            label: _facialExtraLabel,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(facialExtra: e)),
                ),
          ),
        ],
      ),
    );
  }

  static String _eyeLabel(EyeStyle e) => switch (e) {
        EyeStyle.happy => 'Feliz',
        EyeStyle.angry => 'Enfadado',
        EyeStyle.surprised => 'Sorpresa',
        EyeStyle.sleepy => 'Dormido',
        EyeStyle.wink => 'Guiño',
        EyeStyle.laser => 'Láser',
        EyeStyle.robot => 'Robot',
        EyeStyle.crying => 'Llorando',
        EyeStyle.starry => 'Estrellas',
        EyeStyle.determined => 'Decidido',
      };

  static String _eyebrowLabel(EyebrowStyle e) => switch (e) {
        EyebrowStyle.normal => 'Normales',
        EyebrowStyle.arched => 'Arqueadas',
        EyebrowStyle.angry => 'Enfadadas',
        EyebrowStyle.friendly => 'Amables',
        EyebrowStyle.absent => 'Sin cejas',
      };

  static String _mouthLabel(MouthStyle e) => switch (e) {
        MouthStyle.smile => 'Sonrisa',
        MouthStyle.frown => 'Enfado',
        MouthStyle.teeth => 'Dientes',
        MouthStyle.fangs => 'Colmillos',
        MouthStyle.mustache => 'Bigote',
        MouthStyle.tongueOut => 'Lengua fuera',
        MouthStyle.silent => 'Seria',
      };

  static String _facialExtraLabel(FacialExtra e) => switch (e) {
        FacialExtra.none => 'Ninguno',
        FacialExtra.freckles => 'Pecas',
        FacialExtra.blush => 'Rubor',
        FacialExtra.scar => 'Cicatriz',
        FacialExtra.tribalTattoo => 'Tatuaje',
        FacialExtra.warPaint => 'Pintura',
        FacialExtra.monocle => 'Monóculo',
      };
}

// ── Tab: Hair ───────────────────────────────────────────────────────────────

class _HairTab extends StatelessWidget {
  final CharacterAppearance appearance;
  const _HairTab({required this.appearance});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.scrollContent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<HeadwearType>(
            values: HeadwearType.values,
            selected: appearance.headwearType,
            label: (e) {
              if (e == HeadwearType.none) return 'Ninguno';
              if (e == HeadwearType.hair) return 'Cabello';
              if (e == HeadwearType.helmet) return 'Casco';
              return 'Sombrero';
            },
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(headwearType: e)),
                ),
          ),
          if (appearance.headwearType == HeadwearType.hair) ...[
            const SizedBox(height: 16),
            const Text('Estilo de cabello',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _EnumSelector<HairStyle>(
              values: HairStyle.values,
              selected: appearance.hairStyle,
              label: _hairLabel,
              onSelect: (e) => context.read<CharacterEditorBloc>().add(
                    UpdateAppearance(appearance.copyWith(hairStyle: e)),
                  ),
            ),
          ],
          if (appearance.headwearType == HeadwearType.helmet) ...[
            const SizedBox(height: 16),
            const Text('Tipo de casco',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _EnumSelector<HelmetStyle>(
              values: HelmetStyle.values,
              selected: appearance.helmetStyle,
              label: _helmetLabel,
              onSelect: (e) => context.read<CharacterEditorBloc>().add(
                    UpdateAppearance(appearance.copyWith(helmetStyle: e)),
                  ),
            ),
          ],
          if (appearance.headwearType == HeadwearType.hat) ...[
            const SizedBox(height: 16),
            const Text('Tipo de sombrero',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _EnumSelector<HatStyle>(
              values: HatStyle.values,
              selected: appearance.hatStyle,
              label: _hatLabel,
              onSelect: (e) => context.read<CharacterEditorBloc>().add(
                    UpdateAppearance(appearance.copyWith(hatStyle: e)),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  static String _hairLabel(HairStyle e) => switch (e) {
        HairStyle.straight => 'Liso',
        HairStyle.curly => 'Rizado',
        HairStyle.afro => 'Afro',
        HairStyle.mohawk => 'Mohicano',
        HairStyle.ponytail => 'Coleta',
        HairStyle.braids => 'Trenzas',
        HairStyle.shaved => 'Rapado',
        HairStyle.bald => 'Calvo',
        HairStyle.messy => 'Despeinado',
        HairStyle.swept => 'Peinado atrás',
        HairStyle.fringe => 'Flequillo',
        HairStyle.longBlonde => 'Largo rubio',
        HairStyle.longBlack => 'Largo negro',
        HairStyle.wavyBob => 'Melena ondulada',
      };

  static String _helmetLabel(HelmetStyle e) => switch (e) {
        HelmetStyle.medieval => 'Medieval',
        HelmetStyle.space => 'Espacial',
        HelmetStyle.roman => 'Romano',
        HelmetStyle.viking => 'Vikingo',
        HelmetStyle.firefighter => 'Bombero',
        HelmetStyle.biker => 'Motero',
        HelmetStyle.astronaut => 'Astronauta',
        HelmetStyle.ninjaHood => 'Capucha ninja',
        HelmetStyle.ironMan => 'Hombre de hierro',
        HelmetStyle.spiderMan => 'Arácnido',
        HelmetStyle.blackPanther => 'Pantera',
        HelmetStyle.deadpool => 'Mercenario',
        HelmetStyle.wolverine => 'Lobezno',
        HelmetStyle.ghostSpider => 'Arácnida fantasma',
      };

  static String _hatLabel(HatStyle e) => switch (e) {
        HatStyle.wizard => 'Mago',
        HatStyle.cowboy => 'Vaquero',
        HatStyle.cap => 'Gorra',
        HatStyle.crown => 'Corona',
        HatStyle.tiara => 'Tiara',
        HatStyle.topHat => 'Chistera',
        HatStyle.pirate => 'Pirata',
        HatStyle.conical => 'Cónico',
      };
}

// ── Tab: Torso ──────────────────────────────────────────────────────────────

class _TorsoTab extends StatelessWidget {
  final CharacterAppearance appearance;
  const _TorsoTab({required this.appearance});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.scrollContent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Diseño de torso',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<TorsoDesign>(
            values: TorsoDesign.values,
            selected: appearance.torso,
            label: _torsoLabel,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(torso: e)),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Capa', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Switch(
                value: appearance.hasCape,
                onChanged: (v) => context.read<CharacterEditorBloc>().add(
                      UpdateAppearance(appearance.copyWith(hasCape: v)),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Guantes', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<GloveType>(
            values: GloveType.values,
            selected: appearance.gloves,
            label: _gloveLabel,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(gloves: e)),
                ),
          ),
        ],
      ),
    );
  }

  static String _torsoLabel(TorsoDesign e) => switch (e) {
        TorsoDesign.plain => 'Liso',
        TorsoDesign.police => 'Policía',
        TorsoDesign.firefighter => 'Bombero',
        TorsoDesign.astronaut => 'Astronauta',
        TorsoDesign.doctor => 'Médico',
        TorsoDesign.chef => 'Chef',
        TorsoDesign.military => 'Militar',
        TorsoDesign.ninja => 'Ninja',
        TorsoDesign.pirate => 'Pirata',
        TorsoDesign.superhero => 'Superhéroe',
        TorsoDesign.casual => 'Casual',
        TorsoDesign.medieval => 'Medieval',
        TorsoDesign.futuristic => 'Futurista',
        TorsoDesign.samurai => 'Samurái',
        TorsoDesign.dinosaur => 'Dinosaurio',
        TorsoDesign.robot => 'Robot',
        TorsoDesign.monster => 'Monstruo',
        TorsoDesign.alien => 'Alienígena',
        TorsoDesign.tactical => 'Táctico',
        TorsoDesign.tanktop => 'Camiseta',
        TorsoDesign.commando => 'Comando',
        TorsoDesign.golden => 'Dorado',
        TorsoDesign.spiderGwen => 'Arácnida',
        TorsoDesign.wonderWoman => 'Amazona',
        TorsoDesign.captainMarvel => 'Capitana',
        TorsoDesign.blackWidow => 'Viuda negra',
      };

  static String _gloveLabel(GloveType e) => switch (e) {
        GloveType.none => 'Ninguno',
        GloveType.boxing => 'Boxeo',
        GloveType.medieval => 'Medieval',
        GloveType.superhero => 'Superhéroe',
        GloveType.claws => 'Garras',
        GloveType.energy => 'Energía',
        GloveType.spiderWeb => 'Telaraña',
      };
}

// ── Tab: Legs ───────────────────────────────────────────────────────────────

class _LegsTab extends StatelessWidget {
  final CharacterAppearance appearance;
  const _LegsTab({required this.appearance});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.scrollContent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Diseño de piernas',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<LegDesign>(
            values: LegDesign.values,
            selected: appearance.legDesign,
            label: _legDesignLabel,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(legDesign: e)),
                ),
          ),
          const SizedBox(height: 16),
          const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<LegType>(
            values: LegType.values,
            selected: appearance.legType,
            label: _legTypeLabel,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(legType: e)),
                ),
          ),
          const SizedBox(height: 16),
          const Text('Zapatos', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<ShoeType>(
            values: ShoeType.values,
            selected: appearance.shoes,
            label: _shoeLabel,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(shoes: e)),
                ),
          ),
        ],
      ),
    );
  }

  static String _legDesignLabel(LegDesign e) => switch (e) {
        LegDesign.plain => 'Liso',
        LegDesign.camouflage => 'Camuflaje',
        LegDesign.stripes => 'Rayas',
        LegDesign.checkered => 'Cuadros',
        LegDesign.flames => 'Llamas',
        LegDesign.stars => 'Estrellas',
        LegDesign.armor => 'Armadura',
        LegDesign.desertCamo => 'Camuflaje desierto',
        LegDesign.mechanic => 'Mecánico',
        LegDesign.urbanCamo => 'Camuflaje urbano',
        LegDesign.golden => 'Dorado',
      };

  static String _legTypeLabel(LegType e) => switch (e) {
        LegType.pants => 'Pantalón',
        LegType.shorts => 'Pantalón corto',
        LegType.skirt => 'Falda',
        LegType.legArmor => 'Grebas',
        LegType.spacesuit => 'Traje espacial',
      };

  static String _shoeLabel(ShoeType e) => switch (e) {
        ShoeType.sneakers => 'Zapatillas',
        ShoeType.military => 'Botas militares',
        ShoeType.cowboy => 'Botas vaqueras',
        ShoeType.sandals => 'Sandalias',
        ShoeType.skates => 'Patines',
        ShoeType.flippers => 'Aletas',
        ShoeType.witchBoots => 'Botas de bruja',
        ShoeType.barefoot => 'Descalzo',
        ShoeType.heroBoots => 'Botas de héroe',
        ShoeType.balletTeal => 'Zapatillas de ballet',
      };
}

// ── Tab: Accessories ────────────────────────────────────────────────────────

class _AccessoriesTab extends StatelessWidget {
  final CharacterAppearance appearance;
  const _AccessoriesTab({required this.appearance});

  static const _slotMeta = [
    ('Mano derecha', 'rightHand'),
    ('Mano izquierda', 'leftHand'),
    ('Espalda', 'back'),
    ('Hombros', 'shoulders'),
    ('Cintura', 'waist'),
    ('Cuello', 'neck'),
    ('Cara', 'face'),
    ('Pies', 'feet'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        final unlocked = walletState.wallet.unlockedParts.toSet();
        // Reacciona al modo de prueba en vivo (desbloquea todos los accesorios).
        return ValueListenableBuilder<bool>(
          valueListenable: TestMode.instance.enabled,
          builder: (context, __, ___) => ListView(
          padding: AppSpacing.scrollContent,
          children: _slotMeta.map((meta) {
            final (label, field) = meta;
            final entries = catalogForSlot(field);
            final current = _getField(appearance.accessories, field);
            return _AccessorySlot(
              label: label,
              entries: entries,
              selected: current,
              unlockedParts: unlocked,
              coins: walletState.wallet.coins,
              onSelect: (id) {
                final updated = _setField(appearance.accessories, field, id);
                context.read<CharacterEditorBloc>().add(
                      UpdateAppearance(appearance.copyWith(accessories: updated)),
                    );
              },
              onUnlock: (entry) => _showUnlockDialog(
                context,
                entry: entry,
                coins: walletState.wallet.coins,
                onConfirm: () {
                  context.read<WalletBloc>().add(
                        UnlockPartEvent(partId: entry.id, cost: entry.coinCost),
                      );
                  final updated = _setField(appearance.accessories, field, entry.id);
                  context.read<CharacterEditorBloc>().add(
                        UpdateAppearance(appearance.copyWith(accessories: updated)),
                      );
                },
              ),
            );
          }).toList(),
          ),
        );
      },
    );
  }

  void _showUnlockDialog(
    BuildContext context, {
    required CatalogEntry entry,
    required int coins,
    required VoidCallback onConfirm,
  }) {
    final canAfford = coins >= entry.coinCost;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Desbloquear ${entry.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RarityBadge(rarity: entry.rarity),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙 ', style: TextStyle(fontSize: 18)),
                Text(
                  '${entry.coinCost} monedas',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tienes: 🪙 $coins',
              style: TextStyle(
                color: canAfford ? Colors.black54 : Colors.red,
                fontSize: 13,
              ),
            ),
            if (!canAfford) ...[
              const SizedBox(height: 8),
              const Text(
                'No tienes suficientes monedas.\n¡Juega para ganar más!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (canAfford)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('Desbloquear', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  String? _getField(CharacterAccessories acc, String field) {
    if (field == 'rightHand') return acc.rightHand;
    if (field == 'leftHand') return acc.leftHand;
    if (field == 'back') return acc.back;
    if (field == 'shoulders') return acc.shoulders;
    if (field == 'waist') return acc.waist;
    if (field == 'neck') return acc.neck;
    if (field == 'face') return acc.face;
    if (field == 'feet') return acc.feet;
    return null;
  }

  CharacterAccessories _setField(
      CharacterAccessories acc, String field, String? value) {
    if (field == 'rightHand') return acc.copyWith(rightHand: value);
    if (field == 'leftHand') return acc.copyWith(leftHand: value);
    if (field == 'back') return acc.copyWith(back: value);
    if (field == 'shoulders') return acc.copyWith(shoulders: value);
    if (field == 'waist') return acc.copyWith(waist: value);
    if (field == 'neck') return acc.copyWith(neck: value);
    if (field == 'face') return acc.copyWith(face: value);
    if (field == 'feet') return acc.copyWith(feet: value);
    return acc;
  }
}

class _AccessorySlot extends StatelessWidget {
  final String label;
  final List<CatalogEntry> entries;
  final String? selected;
  final Set<String> unlockedParts;
  final int coins;
  final ValueChanged<String?> onSelect;
  final ValueChanged<CatalogEntry> onUnlock;

  const _AccessorySlot({
    required this.label,
    required this.entries,
    required this.selected,
    required this.unlockedParts,
    required this.coins,
    required this.onSelect,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _OptionChip(
                label: 'Ninguno',
                isSelected: selected == null,
                isLocked: false,
                onTap: () => onSelect(null),
              ),
              ...entries.map((entry) {
                final isAvailable = entry.isFree ||
                    unlockedParts.contains(entry.id) ||
                    TestMode.instance.isOn;
                return _OptionChip(
                  label: entry.name,
                  isSelected: selected == entry.id,
                  isLocked: !isAvailable,
                  coinCost: isAvailable ? null : entry.coinCost,
                  rarity: entry.rarity,
                  onTap: () {
                    if (isAvailable) {
                      onSelect(selected == entry.id ? null : entry.id);
                    } else {
                      onUnlock(entry);
                    }
                  },
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLocked;
  final int? coinCost;
  final AccessoryRarity? rarity;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.isLocked,
    this.coinCost,
    this.rarity,
    required this.onTap,
  });

  Color get _rarityColor {
    if (rarity == AccessoryRarity.legendary) return const Color(0xFFE67E22);
    if (rarity == AccessoryRarity.epic) return const Color(0xFF9B59B6);
    if (rarity == AccessoryRarity.rare) return const Color(0xFF4A90E2);
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFD700)
                : isLocked
                    ? const Color(0xFF141B2E)
                    : const Color(0xFF1B2438),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFB8860B)
                  : isLocked
                      ? _rarityColor
                      : const Color(0xFF2E3A52),
              width: isLocked ? 1.5 : 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLocked) ...[
                Icon(Icons.lock_outline, size: 12, color: _rarityColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  color: isSelected
                      ? Colors.black
                      : isLocked
                          ? Colors.white38
                          : Colors.white70,
                ),
              ),
              if (isLocked && coinCost != null) ...[
                const SizedBox(width: 4),
                Text(
                  '🪙$coinCost',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _rarityColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final AccessoryRarity rarity;
  const _RarityBadge({required this.rarity});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    if (rarity == AccessoryRarity.legendary) {
      label = 'Legendario'; color = const Color(0xFFE67E22);
    } else if (rarity == AccessoryRarity.epic) {
      label = 'Épico'; color = const Color(0xFF9B59B6);
    } else if (rarity == AccessoryRarity.rare) {
      label = 'Raro'; color = const Color(0xFF4A90E2);
    } else {
      label = 'Común'; color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Generic enum selector ────────────────────────────────────────────────────

class _EnumSelector<T> extends StatelessWidget {
  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  const _EnumSelector({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onSelect(v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected ? const Color(0xFFFFD700) : const Color(0xFF1B2438),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFB8860B)
                    : const Color(0xFF2E3A52),
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Text(
              label(v),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? Colors.black : Colors.white70,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
