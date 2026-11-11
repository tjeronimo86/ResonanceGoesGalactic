import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/session.dart';

/// Galactic view (rebuild of the Galactic Vibration Player, see tjeronimo86/OpenGalacticMusicPlayer).
const galacticFont = 'ChakraPetch';

abstract final class G {
  static const bg = Color(0xFF07070F);
  static const card = Color(0xFF0D0D19);
  static const cardEdge = Color(0xFF1C1C30);
  static const tile = Color(0xFF14142A);
  static const chip = Color(0xFF141426);
  static const chipEdge = Color(0xFF262642);
  static const grid = Color(0xFF1E1E34);
  static const text = Color(0xFFE9E9F5);
  static const dim = Color(0xFF8C8CA8);
  static const faint = Color(0xFF55557A);
  static const ok = Color(0xFF34D399);
  static const warn = Color(0xFFFBBF24);
  static const bad = Color(0xFFFF4D6D);
}

/// Colours of a style: bars bottom → top, plus accents for the controls.
@immutable
class GPalette {
  const GPalette(this.low, this.high, this.accent, this.accent2);
  final Color low, high, accent, accent2;

  static GPalette lerp(GPalette a, GPalette b, double t) => GPalette(
    Color.lerp(a.low, b.low, t)!,
    Color.lerp(a.high, b.high, t)!,
    Color.lerp(a.accent, b.accent, t)!,
    Color.lerp(a.accent2, b.accent2, t)!,
  );
}

enum VizStyle {
  fab2m('Fab2M', '1', GPalette(Color(0xFF7B3BFF), Color(0xFF3D7BFF), Color(0xFF6E8BFF), Color(0xFF22D3EE))),
  cosmic('Cosmic', '2', GPalette(Color(0xFFFF2E9A), Color(0xFF8B5CF6), Color(0xFFB45CFF), Color(0xFFFF4FB0))),
  chrome('Chrome', '3', GPalette(Color(0xFF5B6B85), Color(0xFFE6F0FF), Color(0xFF9EC9FF), Color(0xFF22D3EE))),
  vinyl('Vinyl', '4', GPalette(Color(0xFFFF3B5C), Color(0xFFFF9A1F), Color(0xFFFF7A2F), Color(0xFFFFC14D))),
  crbrvs('CRBRVS', '5', GPalette(Color(0xFF2B3BFF), Color(0xFFFF2448), Color(0xFFFF2E63), Color(0xFF3D5BFF))),
  synth('Synth', '6', GPalette(Color(0xFFFF3EA5), Color(0xFF22D3EE), Color(0xFFFF4FB0), Color(0xFF22D3EE))),
  aurora('Aurora', '7', GPalette(Color(0xFF14E89A), Color(0xFF8B5CF6), Color(0xFF2EE6B8), Color(0xFF8B5CF6))),
  octave('Oktave', '8', GPalette(Color(0xFF2D9CFF), Color(0xFFFF8A1F), Color(0xFFFF8A1F), Color(0xFF2D9CFF))),
  led('LED', '9', GPalette(Color(0xFF22E36B), Color(0xFFFF3B3B), Color(0xFF35E07A), Color(0xFFFFD43B))),
  mirror('Spiegel', '0', GPalette(Color(0xFF14E0C8), Color(0xFF7B5CFF), Color(0xFF2EE6D0), Color(0xFF7B5CFF)));

  const VizStyle(this.label, this.key, this.palette);
  final String label;
  final String key;
  final GPalette palette;
}

/// Chosen look of the Galactic view, kept in the preferences.
@immutable
class GalacticLook {
  const GalacticLook({
    this.style = VizStyle.fab2m,
    this.curve = false,
    this.stereo = false,
    this.outline = false,
    this.cover = false,
    this.random = true,
    this.randomSeconds = 8,
    this.eqOpen = false,
    this.vuRef = 0,
  });
  final VizStyle style;
  final bool curve, stereo, outline, cover, random, eqOpen;
  final int randomSeconds;

  /// 0 = automatic (follows the song's loudness), otherwise the dBFS level of 0 VU.
  final int vuRef;

  GalacticLook copyWith({
    VizStyle? style,
    bool? curve,
    bool? stereo,
    bool? outline,
    bool? cover,
    bool? random,
    int? randomSeconds,
    bool? eqOpen,
    int? vuRef,
  }) => GalacticLook(
    style: style ?? this.style,
    curve: curve ?? this.curve,
    stereo: stereo ?? this.stereo,
    outline: outline ?? this.outline,
    cover: cover ?? this.cover,
    random: random ?? this.random,
    randomSeconds: randomSeconds ?? this.randomSeconds,
    eqOpen: eqOpen ?? this.eqOpen,
    vuRef: vuRef ?? this.vuRef,
  );
}

class GalacticLookController extends Notifier<GalacticLook> {
  @override
  GalacticLook build() {
    final p = ref.read(prefsProvider);
    final name = p.getString('galactic_style');
    return GalacticLook(
      style: VizStyle.values.where((s) => s.name == name).firstOrNull ?? VizStyle.fab2m,
      curve: p.getBool('galactic_curve') ?? false,
      stereo: p.getBool('galactic_stereo') ?? false,
      outline: p.getBool('galactic_outline') ?? false,
      cover: p.getBool('galactic_cover') ?? false,
      random: p.getBool('galactic_random') ?? true,
      randomSeconds: p.getInt('galactic_random_sec') ?? 8,
      eqOpen: p.getBool('galactic_eq_open') ?? false,
      vuRef: p.getInt('galactic_vu_ref') ?? 0,
    );
  }

  void _save(GalacticLook l) {
    final p = ref.read(prefsProvider);
    p.setString('galactic_style', l.style.name);
    p.setBool('galactic_curve', l.curve);
    p.setBool('galactic_stereo', l.stereo);
    p.setBool('galactic_outline', l.outline);
    p.setBool('galactic_cover', l.cover);
    p.setBool('galactic_random', l.random);
    p.setInt('galactic_random_sec', l.randomSeconds);
    p.setBool('galactic_eq_open', l.eqOpen);
    p.setInt('galactic_vu_ref', l.vuRef);
    state = l;
  }

  /// A style picked by hand ends the random mode.
  void pick(VizStyle s, {bool fromRandom = false}) =>
      _save(state.copyWith(style: s, random: fromRandom ? state.random : false));

  void next(int direction) {
    final all = VizStyle.values;
    pick(all[(state.style.index + direction + all.length) % all.length]);
  }

  void set(GalacticLook l) => _save(l);
}

final galacticLookProvider = NotifierProvider<GalacticLookController, GalacticLook>(GalacticLookController.new);

/// The few texts of the Galactic view (German and English, like the rest of the app).
class GText {
  GText(this.de);
  final bool de;

  static GText of(BuildContext context) => GText(Localizations.localeOf(context).languageCode == 'de');

  String get title => 'Galactic';
  String get axisLevel => de ? 'Pegel (dBFS)' : 'Level (dBFS)';
  String get axisFreq => de ? 'Frequenz (Hz)' : 'Frequency (Hz)';
  String get curve => de ? 'Kurve' : 'Curve';
  String get stereo => 'Stereo';
  String get outline => de ? 'Kontur' : 'Outline';
  String get cover => 'Cover';
  String get random => de ? 'Zufall' : 'Random';
  String get eqOn => de ? 'Aktiv' : 'On';
  String get eqOff => de ? 'Aus' : 'Off';
  String get eqReset => de ? 'Zurücksetzen' : 'Reset';
  String get eqSliders => de ? 'Regler' : 'Sliders';
  String get eqCustom => de ? 'Eigene' : 'Custom';
  String get integrated => de ? 'Integriert' : 'Integrated';
  String get momentary => de ? 'Momentan' : 'Momentary';
  String get shortTerm => de ? 'Kurzzeit' : 'Short term';
  String get lra => de ? 'Bereich (LRA)' : 'Range (LRA)';
  String get maxPeak => de ? 'Spitze max' : 'Max peak';
  String get vsStreaming => 'vs Streaming';
  String get queue => de ? 'Warteschlange' : 'Queue';
  String get filter => de ? 'Warteschlange filtern' : 'Filter queue';
  String get empty => de ? 'Nichts in der Warteschlange.' : 'Nothing in the queue.';
  String get nothing => de ? 'Nichts in Wiedergabe' : 'Nothing playing';
  String get ok => de ? 'OK, unter Grenzwert' : 'OK, below ceiling';
  String get over => de ? 'Über -1 dBTP' : 'Above -1 dBTP';
  String get peak => de ? 'Spitze' : 'Peak';
  String get soFar => de ? 'bisher' : 'so far';
  String get noWave => de ? 'Wellenform wird geladen …' : 'Loading waveform …';
  String get settings => de ? 'Galactic-Einstellungen' : 'Galactic settings';
  String get randomEvery => de ? 'Zufall: Stil wechseln alle' : 'Random: change style every';
  String get vuCal => de ? 'VU-Kalibrierung (0 VU =)' : 'VU calibration (0 VU =)';
  String get vuAuto => de ? 'Auto (folgt dem Titel)' : 'Auto (follows the song)';
  String get whatsNew => de ? 'Was ist neu in Galactic' : "What's new in Galactic";
  String get done => de ? 'Fertig' : 'Done';
  String get swipeHint => de ? 'Über das Spektrum wischen wechselt den Stil' : 'Swipe across the spectrum to change the style';
  String get about => de
      ? 'Nachbau des Galactic Vibration Player. Spektrum, Pegel, Lautheit (EBU R128) und True Peak werden live auf dem Gerät gemessen.'
      : 'Rebuild of the Galactic Vibration Player. Spectrum, levels, loudness (EBU R128) and true peak are measured live on the device.';
  String get eqNote => de
      ? 'Der Equalizer wirkt hinter der Messung: Spektrum zeigt seine Kurve, VU und Lautheit messen ohne ihn.'
      : 'The equalizer acts after the measurement: the spectrum shows its curve, VU and loudness are measured without it.';
}
