import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _favoritesKey = 'favorite_files';
  static const String _recentsKey = 'recent_files';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> toggleFavorite(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    if (favorites.contains(filePath)) {
      favorites.remove(filePath);
    } else {
      favorites.add(filePath);
    }
    await prefs.setStringList(_favoritesKey, favorites);
  }

  Future<bool> isFavorite(String filePath) async {
    final favorites = await getFavorites();
    return favorites.contains(filePath);
  }

  Future<List<String>> getRecents() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentsKey) ?? [];
  }

  Future<void> addRecent(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recents = prefs.getStringList(_recentsKey) ?? [];

    // Remove if already exists to move it to the top
    recents.remove(filePath);
    recents.insert(0, filePath);

    // Keep only the last 20 recent files
    if (recents.length > 20) {
      recents = recents.sublist(0, 20);
    }

    await prefs.setStringList(_recentsKey, recents);
  }
}
