import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_palette.dart';
import 'package:monamie_app/app/data/tracking/sharing_times.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings.dart';

import 'tracking_settings_edit_controller.dart';

const _ink = Color(0xFF1B1838);
const _muted = Color(0xFF4A4858);
const _line = Color(0xFFDDD9E4);

/// *Ajustes de acompanhamento*: how often people in the field send their
/// location, for the whole organization.
class TrackingSettingsView extends StatelessWidget {
  const TrackingSettingsView({super.key, required this.controller});

  final TrackingSettingsEditController controller;

  @override
  Widget build(BuildContext context) {
    final palette = PartnerPalette.fromConfig(Partner.current);
    final name = Partner.current?.name ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: palette.dark,
        foregroundColor: palette.onDark,
        title: const Text('Ajustes de acompanhamento'),
        centerTitle: false,
      ),
      body: Obx(() {
        final draft = controller.draft.value;
        final saving = controller.isSaving.value;
        final minutes = (int n) => n == 1 ? '1 min' : '$n min';
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                children: [
                  const Text(
                    'Com que frequência a equipe envia a localização?',
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vale para todos da $name que estão em campo.',
                    style: const TextStyle(fontSize: 15, color: _muted),
                  ),
                  if (controller.minPeriodMinutes.value > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'No plano Community, a localização é enviada no máximo a '
                      'cada ${controller.minPeriodMinutes.value} min.',
                      style: const TextStyle(fontSize: 13, color: _muted),
                    ),
                  ],
                  const SizedBox(height: 20),
                  for (final option in TrackingPreset.values)
                    _PresetTile(
                      option: option,
                      selected: controller.preset.value == option,
                      current:
                          option.settings == controller.savedSettings.value,
                      enabled: !saving && controller.allows(option),
                      color: palette.primary,
                      onTap: () => controller.pickPreset(option),
                    ),
                  if (controller.preset.value ==
                      TrackingPreset.personalizado) ...[
                    const SizedBox(height: 8),
                    _Slider(
                      label: 'Intervalo',
                      valueLabel: 'a cada ${minutes(draft.periodMinutes)}',
                      values: trackingPeriods,
                      value: draft.periodMinutes,
                      color: palette.primary,
                      onChanged: saving ? null : controller.setPeriod,
                    ),
                    _Slider(
                      label: 'Distância mínima',
                      valueLabel: '${draft.radiusMeters} m',
                      values: trackingRadii,
                      value: draft.radiusMeters,
                      color: palette.primary,
                      onChanged: saving ? null : controller.setRadius,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _Fact(
                    icon: Icons.send_outlined,
                    text:
                        'Até ${draft.positionsPerHour} '
                        '${draft.positionsPerHour == 1 ? 'posição' : 'posições'} '
                        'por hora, só quando a pessoa se mover '
                        '${draft.radiusMeters} m ou mais.',
                  ),
                  _Fact(
                    icon: Icons.schedule,
                    text:
                        'Quem ficar '
                        '${minutes(validity.inMinutes)} sem dar notícia '
                        'sai do mapa.',
                  ),
                  _Fact(
                    icon: Icons.battery_std,
                    text:
                        'Uso de bateria: '
                        '${const ['Baixo', 'Médio', 'Alto'][draft.batteryLevel - 1]}',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (controller.justSaved.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Salvo. A equipe recebe em instantes, sem desligar o '
                        'compartilhamento.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: palette.dark,
                        ),
                      ),
                    ),
                  if (controller.errorMessage.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        controller.errorMessage.value,
                        style: const TextStyle(
                          color: Color(0xFFB3261E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: saving || !controller.hasChanges
                          ? null
                          : controller.save,
                      child: saving
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: palette.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Salvando…'),
                              ],
                            )
                          : Text(
                              controller.hasChanges
                                  ? 'Salvar alterações'
                                  : 'Nenhuma alteração',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.option,
    required this.selected,
    required this.current,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final TrackingPreset option;
  final bool selected;
  final bool current;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  String get _description => switch (option) {
    TrackingPreset.personalizado => 'Você escolhe intervalo e distância',
    _ =>
      'A cada ${option.periodMinutes} min, se andar ${option.radiusMeters} m',
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected ? color.withAlpha(30) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? color : _line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? color : const Color(0xFFB9B4C9),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Opacity(
                    opacity: enabled ? 1 : 0.45,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              option.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            if (current) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Em uso',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _description,
                          style: const TextStyle(fontSize: 13, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.valueLabel,
    required this.values,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final List<int> values;
  final int value;
  final Color color;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(value).clamp(0, values.length - 1);
    final onChanged = this.onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(valueLabel, style: const TextStyle(color: _muted)),
          ],
        ),
        Slider(
          value: index.toDouble(),
          max: (values.length - 1).toDouble(),
          divisions: values.length - 1,
          label: valueLabel,
          activeColor: color,
          onChanged: onChanged == null
              ? null
              : (position) => onChanged(values[position.round()]),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.45, color: _muted),
          ),
        ),
      ],
    ),
  );
}
