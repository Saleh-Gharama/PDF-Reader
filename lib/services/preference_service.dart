import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _favoritesKey = 'favorites';
  static const String _recentsKey = 'recents';
  static const int _maxRecents = 20;

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> toggleFavorite(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
    if (favorites.contains(path)) {
      favorites.remove(path);
    } else {
      favorites.add(path);
    }
    await prefs.setStringList(_favoritesKey, favorites);
  }

  Future<bool> isFavorite(String path) async {
    final favorites = await getFavorites();
    return favorites.contains(path);
  }

  Future<List<String>> getRecents() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentsKey) ?? [];
  }

  Future<void> addToRecents(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recents = prefs.getStringList(_recentsKey) ?? [];

    // Remove if already exists to move it to the front
    recents.remove(path);
    recents.insert(0, path);

    // Limit the number of recents
    if (recents.length > _maxRecents) {
      recents = recents.sublist(0, _maxRecents);
    }

    await prefs.setStringList(_recentsKey, recents);
  }
}
