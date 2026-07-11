import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'debouncer.dart';

class Photo {
  Photo({required this.id, required this.title, required this.thumbnailUrl});

  final int id;
  final String title;
  final String thumbnailUrl;

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json['id'] as int,
        title: json['title'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String,
      );
}

/// ARCHITECTURAL DECISIONS:
/// - The API (jsonplaceholder /photos) returns all 5000 items in one shot
///   with no real pagination, so we fetch it once, cache it in memory, and
///   simulate pagination ourselves by slicing the (filtered) list into
///   batches of [_pageSize]. This still lets us demonstrate real infinite-
///   scroll UX (ListView.builder + ScrollController) even though the
///   network call itself isn't paginated.
/// - Search filtering happens over the *full* cached dataset, not just the
///   currently-loaded page, so search behaves like the user expects
///   (results from anywhere in the 5000, not just what's scrolled into
///   view so far).
/// - Debounce logic lives in a standalone `Debouncer` class (see
///   debouncer.dart) so it can be unit tested without any widget/async
///   pump gymnastics, and so it isn't duplicated if another screen needs
///   the same behavior.
class PaginatedSearchScreen extends StatefulWidget {
  const PaginatedSearchScreen({super.key});

  @override
  State<PaginatedSearchScreen> createState() => _PaginatedSearchScreenState();
}

class _PaginatedSearchScreenState extends State<PaginatedSearchScreen> {
  static const _pageSize = 20;
  static const _endpoint =
      'https://jsonplaceholder.typicode.com/photos';

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 300));

  List<Photo> _allPhotos = []; // full dataset, fetched once
  List<Photo> _filteredPhotos = []; // dataset after search filter applied
  final List<Photo> _visiblePhotos = []; // what ListView.builder renders

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadAllPhotos();
  }

  @override
  void dispose() {
    // Dispose everything that holds a subscription/timer/listener to avoid
    // leaks and "setState called after dispose" errors.
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _loadAllPhotos() async {
    try {
      final response = await http.get(Uri.parse(_endpoint));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      final photos =
          data.map((e) => Photo.fromJson(e as Map<String, dynamic>)).toList();

      if (!mounted) return;
      setState(() {
        _allPhotos = photos;
        _filteredPhotos = photos;
        _isInitialLoading = false;
      });
      _loadNextBatch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load photos: $e';
        _isInitialLoading = false;
      });
    }
  }

  void _loadNextBatch() {
    if (_isLoadingMore) return;
    final start = _visiblePhotos.length;
    if (start >= _filteredPhotos.length) return; // nothing left to load

    setState(() => _isLoadingMore = true);

    // Simulate the natural pause a real paginated API call would have, so
    // the bottom loading indicator is actually visible/demonstrable.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final end = (start + _pageSize).clamp(0, _filteredPhotos.length);
      setState(() {
        _visiblePhotos.addAll(_filteredPhotos.sublist(start, end));
        _isLoadingMore = false;
      });
    });
  }

  void _onScroll() {
    // Trigger the next batch when the user is within ~300px of the bottom,
    // rather than waiting until they hit the exact edge (matches typical
    // infinite-scroll UX expectations).
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      _loadNextBatch();
    }
  }

  void _onSearchChanged() {
    // Debounce: don't filter on every keystroke, only once typing pauses
    // for 300ms.
    _debouncer.run(() {
      final query = _searchController.text.trim().toLowerCase();
      if (!mounted) return;
      setState(() {
        _filteredPhotos = query.isEmpty
            ? _allPhotos
            : _allPhotos
                .where((p) => p.title.toLowerCase().contains(query))
                .toList();
        _visiblePhotos.clear();
      });
      _loadNextBatch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search photo titles...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_visiblePhotos.isEmpty) {
      return const Center(child: Text('No photos match your search'));
    }

    // ListView.builder: only builds/keeps alive the items actually on (or
    // near) screen. We never construct a `ListView(children: [...])` with
    // hundreds of Widget instances up front.
    return ListView.builder(
      controller: _scrollController,
      itemCount: _visiblePhotos.length + 1, // +1 for the footer loader/end
      itemBuilder: (context, index) {
        if (index == _visiblePhotos.length) {
          return _buildFooter();
        }
        final photo = _visiblePhotos[index];
        return ListTile(
          leading: Image.network(
            photo.thumbnailUrl,
            width: 48,
            height: 48,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
          ),
          title: Text(photo.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('Photo #${photo.id}'),
        );
      },
    );
  }

  Widget _buildFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_visiblePhotos.length >= _filteredPhotos.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('— End of results —')),
      );
    }
    return const SizedBox.shrink();
  }
}
