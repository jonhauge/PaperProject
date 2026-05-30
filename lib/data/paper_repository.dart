import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/paper.dart';

/// Persistence boundary for papers. The current implementation stores papers
/// as JSON in [SharedPreferences], which works uniformly across web, iOS and
/// Android. The git-backed sync layer ("git as cloud") will implement this
/// same interface, serialising each paper into its on-disk file layout and
/// committing/pushing.
abstract class PaperRepository {
  Future<List<Paper>> loadAll();
  Future<void> saveAll(List<Paper> papers);
}

class SharedPrefsPaperRepository implements PaperRepository {
  static const _key = 'paperflow.papers.v1';

  @override
  Future<List<Paper>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Paper.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveAll(List<Paper> papers) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(papers.map((p) => p.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
