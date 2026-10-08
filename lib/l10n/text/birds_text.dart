import '../generated/app_localizations.dart';

/// The birds' own words (slice S6): taglines and trails. The data keeps
/// its English twins (`birdDescriptions`, [BirdTrail.names]); names come
/// from [SharedText.birdName]. test/l10n_menus_test.dart keeps them
/// equal.
extension BirdsText on AppLocalizations {
  /// Bird [bird]'s tagline: "Small bird. Big sky." (0 Pip, 1 Peaches,
  /// 2 Minty, 3 Orbit).
  String birdDescription(int bird) => switch (bird % 4) {
    0 => bird_0_description,
    1 => bird_1_description,
    2 => bird_2_description,
    _ => bird_3_description,
  };

  /// The trail bird [bird] leaves in flight: "Sunshine bubbles".
  String birdTrailName(int bird) => switch (bird % 4) {
    0 => bird_0_trail,
    1 => bird_1_trail,
    2 => bird_2_trail,
    _ => bird_3_trail,
  };
}

/// Bird [bird]'s grammatical gender for messages that agree with it
/// (`{gender, select, male{…} female{…} other{…}}`): Pip and Minty
/// masculine, Peaches and Orbit feminine, as the translators' character
/// bible recommends (owner to confirm; change it here only).
String birdGender(int bird) => switch (bird % 4) {
  0 || 2 => 'male',
  _ => 'female',
};
