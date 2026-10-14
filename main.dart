import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

const String kPostsUrl = 'https://jsonplaceholder.typicode.com/posts';
const int kPostLimit = 5;
const String kFavoritesBox = 'favoritesBox';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(kFavoritesBox);
  runApp(const PostReaderApp());
}

// ==========================================
// BOOK DATA (replaces the lorem-ipsum text from the API)
// ==========================================
class Book {
  final String title;
  final String author;
  final String about;
  final IconData icon;
  const Book(this.title, this.author, this.about, this.icon);
}

const List<Book> kBooks = [
  Book(
    'To Kill a Mockingbird',
    'Harper Lee',
    'A young girl in a small Alabama town watches her father, a lawyer, defend a Black man falsely accused of a crime. Through her eyes, the story explores courage, prejudice, and doing what is right.',
    Icons.balance,
  ),
  Book(
    '1984',
    'George Orwell',
    'In a country watched by the government at every moment, a quiet clerk begins to question the Party that controls the truth. A warning about surveillance, propaganda, and lost freedom.',
    Icons.visibility,
  ),
  Book(
    'The Hobbit',
    'J.R.R. Tolkien',
    'Bilbo Baggins, a hobbit who loves his comfortable home, is pulled into an adventure with thirteen dwarves. Together they set out to win back a mountain treasure guarded by a dragon.',
    Icons.landscape,
  ),
  Book(
    'Pride and Prejudice',
    'Jane Austen',
    'Elizabeth Bennet is clever and independent, and Mr. Darcy is proud and wealthy. They must overcome first impressions and social expectations before they can admit they are in love.',
    Icons.favorite_border,
  ),
  Book(
    'The Alchemist',
    'Paulo Coelho',
    'A shepherd boy travels from Spain to the Egyptian desert in search of treasure. Along the way he learns to listen to his heart and follow his personal calling.',
    Icons.auto_awesome,
  ),
];

IconData bookIcon(int id) =>
    (id >= 1 && id <= kBooks.length) ? kBooks[id - 1].icon : Icons.menu_book;

// ==========================================
// HELPERS (make JSONPlaceholder text readable)
// ==========================================
String tidy(String text) {
  final clean = text.replaceAll('\n', ' ').trim();
  if (clean.isEmpty) return clean;
  return clean[0].toUpperCase() + clean.substring(1);
}

String paragraphs(String text) {
  final clean = tidy(text);
  final words = clean.split(' ');
  final buffer = StringBuffer();
  for (var i = 0; i < words.length; i++) {
    buffer.write(words[i]);
    if (i < words.length - 1) {
      buffer.write((i + 1) % 14 == 0 ? '\n\n' : ' ');
    }
  }
  final out = buffer.toString();
  return out.endsWith('.') ? out : '$out.';
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.error : AppColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(error ? Icons.error_outline : Icons.check_circle_outline,
                color: AppColors.paper),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

// ==========================================
// THEME
// ==========================================
class AppColors {
  static const primary = Color(0xFF6B4226);
  static const dark = Color(0xFF3E2723);
  static const surface = Color(0xFFF1E4CC);
  static const paper = Color(0xFFFAF1DF);
  static const gold = Color(0xFFB8893B);
  static const ink = Color(0xFF3B2A20);
  static const muted = Color(0xFF7D6450);
  static const border = Color(0xFFD8C3A0);
  static const error = Color(0xFF9B2C2C);
  static const success = Color(0xFF5E7B3A);
}

class PostReaderApp extends StatelessWidget {
  const PostReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    );

    return MaterialApp(
      title: 'Post Reader & Favorites',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Georgia',
        fontFamilyFallback: const ['Times New Roman', 'serif'],
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.surface,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.3),
          titleMedium: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.3),
          bodyLarge: TextStyle(fontSize: 17, color: AppColors.ink, height: 1.6),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.45),
          labelSmall: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.dark,
          foregroundColor: AppColors.paper,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.paper),
        ),
        cardTheme: CardThemeData(
          color: AppColors.paper,
          elevation: 1,
          shadowColor: AppColors.dark,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        dialogTheme: DialogThemeData(backgroundColor: AppColors.paper),
        dividerTheme: const DividerThemeData(color: AppColors.border),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.paper,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gold, width: 2)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.paper,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PostsScreen(),
        '/details': (context) => const PostDetailsScreen(),
        '/favorites': (context) => const FavoritesScreen(),
      },
    );
  }
}

// ==========================================
// 1. POSTS SCREEN (Home)
// ==========================================
class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$kPostsUrl?_limit=$kPostLimit'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _posts = data.take(kPostLimit).map((e) {
            final post = Map<String, dynamic>.from(e);
            final book = kBooks[(post['id'] - 1) % kBooks.length];
            post['title'] = book.title;
            post['body'] = book.about;
            post['author'] = book.author;
            return post;
          }).toList();
          _filtered = _posts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Could not load books (status ${response.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Check your internet connection.\n\n$e';
        _isLoading = false;
      });
    }
  }

  void _filterSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _posts
          : _posts
              .where((p) =>
                  p['title'].toString().toLowerCase().contains(q) ||
                  p['body'].toString().toLowerCase().contains(q))
              .toList();
    });
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String? titleError;
    String? bodyError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Add a Book'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                          labelText: 'Book title', errorText: titleError),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      decoration:
                          InputDecoration(
                          labelText: 'What is it about?', errorText: bodyError),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final body = bodyController.text.trim();

                    if (title.isEmpty || body.isEmpty) {
                      setDialogState(() {
                        titleError = title.isEmpty ? 'Book title cannot be empty' : null;
                        bodyError = body.isEmpty ? 'Description cannot be empty' : null;
                      });
                      return;
                    }

                    Navigator.pop(dialogContext);
                    await _submitPost(title, body);
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitPost(String title, String body) async {
    try {
      final response = await http.post(
        Uri.parse(kPostsUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final newId = _posts.fold<int>(0, (m, p) => p['id'] > m ? p['id'] : m) + 1;
        setState(() {
          _posts.insert(0, {
            'userId': 1,
            'id': newId,
            'title': title,
            'body': body,
            'author': 'You',
          });
          _filterSearch(_searchController.text);
        });
        showMessage(context, 'Book published successfully!');
      } else {
        showMessage(context, 'Failed to publish book (status ${response.statusCode}).',
            error: true);
      }
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Failed to publish book: $e', error: true);
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPosts,
      child: _filtered.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              Center(child: Text('No books match your search.')),
            ])
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final post = _filtered[index];
                return PostCard(
                  id: post['id'],
                  author: (post['author'] ?? 'You').toString(),
                  title: tidy(post['title']),
                  body: tidy(post['body']),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/details',
                    arguments: {
                      'id': post['id'],
                      'author': (post['author'] ?? 'You').toString(),
                      'title': tidy(post['title']),
                      'body': post['body'],
                    },
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'View Favorites',
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.dark,
              border: Border(bottom: BorderSide(color: AppColors.gold, width: 2)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                _filterSearch(v);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterSearch('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.paper,
        onPressed: _showCreatePostDialog,
        icon: const Icon(Icons.edit),
        label: const Text('Add Book'),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final int id;
  final String author;
  final String title;
  final String body;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.id,
    required this.author,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.gold.withOpacity(0.25),
          child: Icon(bookIcon(id), color: AppColors.primary),
        ),
        title: Text(title,
            maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BY ${author.toUpperCase()}', style: text.labelSmall),
              const SizedBox(height: 4),
              Text(body,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      ),
    );
  }
}

// ==========================================
// 2. POST DETAILS SCREEN
// ==========================================
class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final int postId = args['id'];
    final String author = args['author'] ?? 'You';
    final String title = args['title'];
    final String body = args['body'];
    final text = Theme.of(context).textTheme;
    final box = Hive.box(kFavoritesBox);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Book Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.gold.withOpacity(0.25),
                child: Icon(bookIcon(postId), size: 48, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.person, size: 16, color: AppColors.gold),
                  label: Text(author),
                  backgroundColor: AppColors.paper,
                  side: const BorderSide(color: AppColors.border),
                ),
                Chip(
                  avatar: const Icon(Icons.tag, size: 16, color: AppColors.gold),
                  label: Text('Book $postId'),
                  backgroundColor: AppColors.paper,
                  side: const BorderSide(color: AppColors.border),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: text.titleLarge),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('ABOUT THIS BOOK', style: text.labelSmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(paragraphs(body), style: text.bodyLarge),
            ),
            const SizedBox(height: 28),
            ValueListenableBuilder(
              valueListenable: box.listenable(keys: [postId]),
              builder: (context, Box b, _) {
                final saved = b.containsKey(postId);
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
                    label: Text(saved ? 'Saved to Favorites' : 'Save to Favorites',
                        style: const TextStyle(fontSize: 16)),
                    onPressed: saved
                        ? () => showMessage(context, 'This book is already in your favorites.')
                        : () async {
                            await b.put(postId, {
                              'id': postId,
                              'author': author,
                              'title': title,
                              'body': body,
                              'note': '',
                            });
                            if (!context.mounted) return;
                            showMessage(context, 'Book saved to favorites!');
                          },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. FAVORITES SCREEN
// ==========================================
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final Box _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box(kFavoritesBox);
  }

  void _editNote(dynamic key, Map<String, dynamic> post) {
    final noteController = TextEditingController(text: post['note'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Personal Note'),
          content: TextField(
            controller: noteController,
            autofocus: true,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Write a short note'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                post['note'] = noteController.text.trim();
                await _box.put(key, post);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                showMessage(context, 'Note updated.');
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _delete(dynamic key) async {
    await _box.delete(key);
    if (!mounted) return;
    showMessage(context, 'Removed from favorites.');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Favorite Books'),
      ),
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64, color: AppColors.gold.withOpacity(0.7)),
                  const SizedBox(height: 12),
                  Text('No favorites yet', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text('Open a book and tap “Save to Favorites”.',
                      style: text.bodyMedium),
                ],
              ),
            );
          }

          final savedPosts = box.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: savedPosts.length,
            itemBuilder: (context, index) {
              final post = Map<String, dynamic>.from(savedPosts[index]);
              final key = post['id'];
              final note = (post['note'] ?? '').toString();

              return Dismissible(
                key: ValueKey(key),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: AppColors.paper),
                ),
                onDismissed: (_) => _delete(key),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.gold.withOpacity(0.25),
                              child: Icon(bookIcon(post['id']),
                                  size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  'BY ${(post['author'] ?? 'You').toString().toUpperCase()}',
                                  style: text.labelSmall),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: AppColors.primary),
                              tooltip: 'Edit note',
                              onPressed: () => _editNote(key, post),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              tooltip: 'Remove favorite',
                              onPressed: () => _delete(key),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post['title'], style: text.titleMedium),
                              const SizedBox(height: 6),
                              Text(tidy(post['body']),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodyMedium),
                              if (note.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.sticky_note_2_outlined,
                                          size: 18, color: AppColors.gold),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(note,
                                            style: const TextStyle(
                                                color: AppColors.ink,
                                                fontStyle: FontStyle.italic)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}