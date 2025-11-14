enum BestOf { three, five }

extension BestOfX on BestOf {
  int get setsToWin => this == BestOf.three ? 2 : 3;
}
