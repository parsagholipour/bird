import 'play_achievements.dart';

// Every Google Play Games id lives in this one file. Paste them from Play
// Console (Grow users → Play Games Services → Setup and management):
// the numeric project id from Configuration, and each achievement's id
// (`CgkI…`) from Achievements. The setup steps are in docs/specification.md,
// "Google Play Games".
//
// While [playGamesAppId] is empty the game makes no Play Games call at all,
// Android never starts the Play Games SDK, and Settings shows no Play Games
// strip. Android reads the project id from this line when it builds
// (android/app/build.gradle.kts), so keep it on one line in quotes.

/// The Play Games project id (digits only), such as '123456789012'.
const playGamesAppId = '';

/// Each achievement's Play id. An empty id is simply never reported.
const playAchievementIds = <PlayAchievement, String>{
  PlayAchievement.frequentFlyerBronze: '', // Frequent Flyer · Bronze
  PlayAchievement.frequentFlyerSilver: '', // Frequent Flyer · Silver
  PlayAchievement.frequentFlyerGold: '', // Frequent Flyer · Gold
  PlayAchievement.onTheDotBronze: '', // On the Dot · Bronze
  PlayAchievement.onTheDotSilver: '', // On the Dot · Silver
  PlayAchievement.onTheDotGold: '', // On the Dot · Gold
  PlayAchievement.starChaserBronze: '', // Star Chaser · Bronze
  PlayAchievement.starChaserSilver: '', // Star Chaser · Silver
  PlayAchievement.starChaserGold: '', // Star Chaser · Gold
  PlayAchievement.constellationBronze: '', // Constellation · Bronze
  PlayAchievement.constellationSilver: '', // Constellation · Silver
  PlayAchievement.constellationGold: '', // Constellation · Gold
  PlayAchievement.skyCaptainBronze: '', // Sky Captain · Bronze
  PlayAchievement.skyCaptainSilver: '', // Sky Captain · Silver
  PlayAchievement.skyCaptainGold: '', // Sky Captain · Gold
  PlayAchievement.trailblazerBronze: '', // Trailblazer · Bronze
  PlayAchievement.trailblazerSilver: '', // Trailblazer · Silver
  PlayAchievement.trailblazerGold: '', // Trailblazer · Gold
  PlayAchievement.flockTogetherBronze: '', // Flock Together · Bronze
  PlayAchievement.flockTogetherSilver: '', // Flock Together · Silver
  PlayAchievement.flockTogetherGold: '', // Flock Together · Gold
  PlayAchievement.allRounderBronze: '', // All-Rounder · Bronze
  PlayAchievement.allRounderSilver: '', // All-Rounder · Silver
  PlayAchievement.allRounderGold: '', // All-Rounder · Gold
  PlayAchievement.canopyBoss: '', // Mail Through the Canopy
  PlayAchievement.neferhoo: '', // Return to Sender
  PlayAchievement.roadBoss: '', // Mint Tea Again
  PlayAchievement.kingCoo: '', // Crumbs Cleared
  PlayAchievement.gargoyle: '', // Out of the Spotlight
  PlayAchievement.goldCanopy: '', // Gold Canopy
  PlayAchievement.goldRoad: '', // Gold Road
  PlayAchievement.brightLights: '', // Bright Lights
  PlayAchievement.lamplighter: '', // Lamplighter
  PlayAchievement.harbourBells: '', // Harbour Bells
  PlayAchievement.edgeOfTheMap: '', // Edge of the Map
  PlayAchievement.twoOnOnePhone: '', // Two on One Phone
  PlayAchievement.friendlyRivals: '', // Friendly Rivals
  PlayAchievement.routePlanner: '', // Route Planner
  PlayAchievement.wholeKit: '', // The Whole Kit
  PlayAchievement.penPal: '', // Pen Pal
  PlayAchievement.nightMail: '', // Night Mail (hidden)
  PlayAchievement.specialDelivery: '', // Special Delivery (hidden)
};
