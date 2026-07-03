import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/generic_group.dart';
import '../../../../core/providers/repository_providers.dart';

class AlternativeFinderState {
  final String query;
  final List<GenericGroup> results;
  final GenericGroup? exactMatch; // when a brand is found exactly
  final bool isLoading;

  const AlternativeFinderState({
    this.query = '',
    this.results = const [],
    this.exactMatch,
    this.isLoading = false,
  });

  AlternativeFinderState copyWith({
    String? query,
    List<GenericGroup>? results,
    GenericGroup? exactMatch,
    bool clearExactMatch = false,
    bool? isLoading,
  }) =>
      AlternativeFinderState(
        query: query ?? this.query,
        results: results ?? this.results,
        exactMatch:
            clearExactMatch ? null : (exactMatch ?? this.exactMatch),
        isLoading: isLoading ?? this.isLoading,
      );
}

class AlternativeFinderNotifier
    extends StateNotifier<AlternativeFinderState> {
  final Ref _ref;

  AlternativeFinderNotifier(this._ref)
      : super(const AlternativeFinderState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AlternativeFinderState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true);

    final repo = _ref.read(genericGroupRepositoryProvider);

    // Check for exact brand match first.
    final exact = await repo.findByBrand(query.trim());
    final results = await repo.search(query.trim());

    state = state.copyWith(
      results: results,
      exactMatch: exact,
      clearExactMatch: exact == null,
      isLoading: false,
    );
  }

  void clear() => state = const AlternativeFinderState();
}

final alternativeFinderProvider = StateNotifierProvider.autoDispose<
    AlternativeFinderNotifier, AlternativeFinderState>(
  AlternativeFinderNotifier.new,
);
