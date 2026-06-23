import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/character.dart';
import '../bloc/character_editor_bloc.dart';
import '../bloc/character_editor_event.dart';
import '../bloc/character_editor_state.dart';
import '../widgets/character_preview.dart';

class CharacterEditorPage extends StatelessWidget {
  final String? characterId;

  const CharacterEditorPage({super.key, this.characterId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<CharacterEditorBloc>()..add(const LoadCharacters());
        if (characterId != null) {
          bloc.add(LoadCharacterForEdit(characterId!));
        } else {
          bloc.add(const StartNewCharacter());
        }
        return bloc;
      },
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatelessWidget {
  const _EditorView();

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
          context.goNamed('gallery');
        }
        if (state.status == EditorStatus.error && state.errorMessage != null) {
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
        backgroundColor: const Color(0xFFF5F0E8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFD700),
          leading: BackButton(
            color: Colors.black87,
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
                color: Colors.black87,
              ),
            ),
          ),
          actions: [
            BlocBuilder<CharacterEditorBloc, CharacterEditorState>(
              builder: (context, state) => IconButton(
                icon: state.status == EditorStatus.saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded, color: Colors.black87),
                onPressed: () => context
                    .read<CharacterEditorBloc>()
                    .add(const SaveCurrentCharacter()),
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
                  child: _EditorTabs(appearance: state.currentCharacter!.appearance),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final Character character;
  const _PreviewSection({required this.character});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8E0D0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          CharacterPreview(appearance: character.appearance, size: 80),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) =>
                      context.read<CharacterEditorBloc>().add(UpdateName(v)),
                  controller: TextEditingController(text: character.name)
                    ..selection = TextSelection.collapsed(offset: character.name.length),
                  decoration: const InputDecoration(
                    hintText: 'Nombre del personaje',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _TypeSelector(selected: character.type),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final CharacterType selected;
  const _TypeSelector({required this.selected});

  static const _labels = {
    CharacterType.hero: ('Héroe', Colors.blue),
    CharacterType.villain: ('Villano', Colors.red),
    CharacterType.neutral: ('Neutral', Colors.grey),
    CharacterType.mysterious: ('Misterioso', Colors.purple),
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CharacterType.values.map((type) {
          final (label, color) = _labels[type]!;
          final isSelected = type == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              selectedColor: color.withValues(alpha: 0.3),
              onSelected: (_) => context
                  .read<CharacterEditorBloc>()
                  .add(UpdateCharacterType(type)),
            ),
          );
        }).toList(),
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
          const TabBar(
            isScrollable: true,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              Tab(text: 'Cabeza'),
              Tab(text: 'Cabello'),
              Tab(text: 'Torso'),
              Tab(text: 'Piernas'),
              Tab(text: 'Accesorios'),
            ],
          ),
          Expanded(
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
      padding: const EdgeInsets.all(16),
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
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
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
            label: (e) => e.name,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(eyes: e)),
                ),
          ),
          const SizedBox(height: 16),
          const Text('Boca', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<MouthStyle>(
            values: MouthStyle.values,
            selected: appearance.mouth,
            label: (e) => e.name,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(mouth: e)),
                ),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Hair ───────────────────────────────────────────────────────────────

class _HairTab extends StatelessWidget {
  final CharacterAppearance appearance;
  const _HairTab({required this.appearance});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<HeadwearType>(
            values: HeadwearType.values,
            selected: appearance.headwearType,
            label: (e) => switch (e) {
              HeadwearType.none => 'Ninguno',
              HeadwearType.hair => 'Cabello',
              HeadwearType.helmet => 'Casco',
              HeadwearType.hat => 'Sombrero',
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
              label: (e) => e.name,
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
              label: (e) => e.name,
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
              label: (e) => e.name,
              onSelect: (e) => context.read<CharacterEditorBloc>().add(
                    UpdateAppearance(appearance.copyWith(hatStyle: e)),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab: Torso ──────────────────────────────────────────────────────────────

class _TorsoTab extends StatelessWidget {
  final CharacterAppearance appearance;
  const _TorsoTab({required this.appearance});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Diseño de torso',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<TorsoDesign>(
            values: TorsoDesign.values,
            selected: appearance.torso,
            label: (e) => e.name,
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
            label: (e) => e.name,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(gloves: e)),
                ),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Legs ───────────────────────────────────────────────────────────────

class _LegsTab extends StatelessWidget {
  final CharacterAppearance appearance;
  const _LegsTab({required this.appearance});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Diseño de piernas',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _EnumSelector<LegDesign>(
            values: LegDesign.values,
            selected: appearance.legDesign,
            label: (e) => e.name,
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
            label: (e) => e.name,
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
            label: (e) => e.name,
            onSelect: (e) => context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(shoes: e)),
                ),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Accessories ────────────────────────────────────────────────────────

class _AccessoriesTab extends StatelessWidget {
  final CharacterAppearance appearance;
  const _AccessoriesTab({required this.appearance});

  static const _slots = [
    ('Mano derecha', 'rightHand', ['pistola', 'espada', 'varita', 'antorcha', 'micrófono']),
    ('Mano izquierda', 'leftHand', ['escudo', 'linterna', 'bolso', 'libro', 'bomba']),
    ('Espalda', 'back', ['capa corta', 'jetpack', 'alas', 'mochila']),
    ('Hombros', 'shoulders', ['hombreras', 'loro pirata', 'insignia']),
    ('Cintura', 'waist', ['cinturón herramientas', 'faja ninja', 'correa cowboy']),
    ('Cuello', 'neck', ['collar', 'corbata', 'medallón', 'bufanda']),
    ('Cara', 'face', ['gafas de sol', 'antifaz', 'parche pirata', 'máscara']),
    ('Pies', 'feet', ['espuelas', 'tobilleras', 'botas propulsión']),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _slots.map((slot) {
        final (label, field, options) = slot;
        final current = _getField(appearance.accessories, field);
        return _AccessorySlot(
          label: label,
          options: options,
          selected: current,
          onSelect: (value) {
            final updated = _setField(appearance.accessories, field, value);
            context.read<CharacterEditorBloc>().add(
                  UpdateAppearance(appearance.copyWith(accessories: updated)),
                );
          },
        );
      }).toList(),
    );
  }

  String? _getField(CharacterAccessories acc, String field) => switch (field) {
        'rightHand' => acc.rightHand,
        'leftHand' => acc.leftHand,
        'back' => acc.back,
        'shoulders' => acc.shoulders,
        'waist' => acc.waist,
        'neck' => acc.neck,
        'face' => acc.face,
        'feet' => acc.feet,
        _ => null,
      };

  CharacterAccessories _setField(
          CharacterAccessories acc, String field, String? value) =>
      switch (field) {
        'rightHand' => acc.copyWith(rightHand: value),
        'leftHand' => acc.copyWith(leftHand: value),
        'back' => acc.copyWith(back: value),
        'shoulders' => acc.copyWith(shoulders: value),
        'waist' => acc.copyWith(waist: value),
        'neck' => acc.copyWith(neck: value),
        'face' => acc.copyWith(face: value),
        'feet' => acc.copyWith(feet: value),
        _ => acc,
      };
}

class _AccessorySlot extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _AccessorySlot({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
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
                onTap: () => onSelect(null),
              ),
              ...options.map((o) => _OptionChip(
                    label: o,
                    isSelected: selected == o,
                    onTap: () => onSelect(selected == o ? null : o),
                  )),
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
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD700) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isSelected ? Colors.black87 : Colors.black54,
            ),
          ),
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
              color: isSelected ? const Color(0xFFFFD700) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFFFFD700) : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Text(
              label(v),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isSelected ? Colors.black87 : Colors.black54,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
