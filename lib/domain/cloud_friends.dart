/// Optional discoveries during a single Cloud Cruise. Order is replay-stable.
enum CloudFriend {
  whale,
  bunny,
  turtle;

  String get title => switch (this) {
    whale => 'Cloud Whale',
    bunny => 'Daydream Bunny',
    turtle => 'Sky Turtle',
  };
}

class DriftingCloud {
  DriftingCloud({required this.friend, required this.x, required this.y});
  final CloudFriend friend;
  double x;
  final double y;
  bool discovered = false, passed = false;
  static const pickupRadius = .20;
}
