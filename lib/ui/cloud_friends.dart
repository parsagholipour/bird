import 'package:flutter/material.dart';
import '../domain/cloud_friends.dart';
import '../game/cloud_friend_art.dart';
import 'theme.dart';

class CloudFriendIcon extends StatelessWidget {
  const CloudFriendIcon({
    super.key,
    required this.friend,
    required this.discovered,
    this.width = 40,
  });
  final CloudFriend friend;
  final bool discovered;
  final double width;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${friend.title}${discovered ? ' discovered' : ' to discover'}',
    child: CustomPaint(
      size: Size(width, width * 80 / 112),
      painter: _CloudPainter(friend, discovered),
    ),
  );
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter(this.friend, this.discovered);
  final CloudFriend friend;
  final bool discovered;

  @override
  void paint(Canvas canvas, Size size) => CloudFriendArt.paint(
    canvas,
    Offset.zero & size,
    friend,
    discovered: discovered,
  );
  @override
  bool shouldRepaint(_CloudPainter oldDelegate) =>
      oldDelegate.friend != friend || oldDelegate.discovered != discovered;
}

class CloudFriendsHud extends StatelessWidget {
  const CloudFriendsHud({super.key, required this.friends});
  final Set<CloudFriend> friends;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: SkyColors.cream.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final friend in CloudFriend.values)
              CloudFriendIcon(
                friend: friend,
                discovered: friends.contains(friend),
                width: 30,
              ),
          ],
        ),
        Text(
          '${friends.length}/3 cloud friends',
          style: bodyText(10, weight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class CloudFriendsAlbum extends StatelessWidget {
  const CloudFriendsAlbum({super.key, required this.friends});
  final Set<CloudFriend> friends;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        friends.isEmpty ? 'Friends in the clouds' : 'Friends from this flight',
        style: heading(20),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          for (final friend in CloudFriend.values)
            Expanded(
              child: Column(
                children: [
                  CloudFriendIcon(
                    friend: friend,
                    discovered: friends.contains(friend),
                    width: 80,
                  ),
                  Text(friend.title, style: bodyText(11)),
                  Text(
                    friends.contains(friend) ? 'DISCOVERED' : 'Still drifting',
                    style: bodyText(
                      9,
                      weight: FontWeight.w900,
                      color: friends.contains(friend)
                          ? SkyColors.teal
                          : SkyColors.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        friends.isEmpty
            ? 'Fly close to a cloud friend to discover it.'
            : 'Save this session to visit them again in your replay.',
        style: bodyText(11, color: SkyColors.muted),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
    ],
  );
}
