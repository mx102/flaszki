/// Dead End check (PRD §4.4, ADR 0002).
library;

import 'board_state.dart';
import 'solver.dart';

/// Whether [state] is a proven Dead End: the exact-key solver exhausted the
/// search without a solution. Node cap hit (unknown) is not a Dead End, so a
/// solvable state is never reported.
bool isDeadEnd(BoardState state, {int nodeCap = defaultNodeCap}) =>
    solve(state, nodeCap: nodeCap, visited: VisitedKey.exact).result ==
    Solvability.unsolvable;
