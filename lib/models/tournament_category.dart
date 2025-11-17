enum TournamentCategory { atp250, atp500, masters1000, grandSlam }

class CategoryInfo {
  final TournamentCategory category;
  final String displayName;
  final List<int> typicalFormats;

  const CategoryInfo(this.category, this.displayName, this.typicalFormats);

  static const List<CategoryInfo> values = [
    CategoryInfo(TournamentCategory.atp250, 'ATP 250', [28, 32, 48, 56]),
    CategoryInfo(TournamentCategory.atp500, 'ATP 500', [32, 48]),
    CategoryInfo(TournamentCategory.masters1000, 'Masters 1000', [56, 96]),
    CategoryInfo(TournamentCategory.grandSlam, 'Grand Chelem', [128]),
  ];

  static CategoryInfo byCategory(TournamentCategory c) =>
      values.firstWhere((v) => v.category == c);
}
