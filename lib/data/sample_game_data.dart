import '../models/game_model.dart';
import '../models/player_model.dart';

final GameModel sampleGame = GameModel(
  id: 'sample_game_1',
  createdAt: DateTime.now(),
  chipValue: 500,
  cashValue: 100,
  groupId: 'sample-group-id',
  results: [],
);

final List<PlayerModel> samplePlayers = [
  PlayerModel(name: 'Amit', buyIns: [500], exitChips: 4000),
  PlayerModel(name: 'Neha', buyIns: [1000, 500], exitChips: 2000),
  PlayerModel(name: 'Raj', buyIns: [1000], exitChips: 2500),
];
