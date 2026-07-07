import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages an in-progress game draft so the user can resume after the app is
/// backgrounded or killed before settlement completes.
///
/// The draft is stored under the key [_kDraftKey] in SharedPreferences as a
/// JSON object.  The shape matches the route-arguments maps that the game
/// screens already pass between themselves, plus an extra [screen] field that
/// records which screen was active when the draft was last written:
///
///   {
///     "screen": "game" | "buyins" | "result",
///     "players": [...],
///     "chipValue": 1000.0,
///     "cashValue": 100.0,
///     "roomName": "Friday Night",   // nullable
///     "groupName": "My Group"       // nullable
///   }
///
/// The key [_kDraftKey] ("draft_session") does NOT collide with any existing
/// SharedPreferences keys used by [StorageService] (those all use the prefix
/// "game_") or by [ProgressService].
class DraftSessionService {
  static const String _kDraftKey = 'draft_session';

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Serialises [gameState] and persists it.  Call this every time the active
  /// game state changes (player added, buy-in updated, chips entered).
  ///
  /// [gameState] must include at least:
  ///   - "screen"    : String  — "game" | "buyins" | "result"
  ///   - "players"   : List    — list of player maps
  ///   - "chipValue" : double
  ///   - "cashValue" : double
  Future<void> saveDraft(Map<String, dynamic> gameState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDraftKey, jsonEncode(gameState));
  }

  /// Returns the persisted draft, or [null] if none exists.
  Future<Map<String, dynamic>?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDraftKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Corrupt data — treat as no draft
      await clearDraft();
      return null;
    }
  }

  /// Removes the draft.  Call this after a successful settlement so the next
  /// app launch doesn't offer to resume an already-finished game.
  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftKey);
  }
}
