enum MemberStatus { pending, approved, rejected, checkedIn }

class GameMember {
  final String id;
  final String gameId;
  final String userId;
  MemberStatus status;

  GameMember({
    required this.id,
    required this.gameId,
    required this.userId,
    this.status = MemberStatus.pending,
  });
}

List<GameMember> mockMembers = [
  GameMember(
    id: "m1",
    gameId: "g1",
    userId: "u2",
    status: MemberStatus.pending,
  ),
  GameMember(
    id: "m2",
    gameId: "g1",
    userId: "u3",
    status: MemberStatus.approved,
  ),
  GameMember(
    id: "m3",
    gameId: "g2",
    userId: "u1",
    status: MemberStatus.approved,
  ),
];
