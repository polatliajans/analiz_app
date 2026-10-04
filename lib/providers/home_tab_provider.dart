import 'package:flutter_riverpod/flutter_riverpod.dart';

const chartTabIndex = 0;
const radarTabIndex = 1;
const watchlistTabIndex = 2;
const profileTabIndex = 3;

class HomeTabNotifier extends Notifier<int> {
  @override
  int build() => chartTabIndex;

  void select(int index) => state = index;
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, int>(
  HomeTabNotifier.new,
);
