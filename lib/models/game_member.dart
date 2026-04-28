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

  Map<String, dynamic> toMap() {
    return {'id': id, 'gameId': gameId, 'userId': userId, 'status': status};
  }
}
