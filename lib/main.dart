import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'summary.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ArticleView());
  }
}

class ArticleModel {
  Future<Summary> getRandomArticleSummary() async {
    final uri = Uri.https(
      'en.wikipedia.org',
      '/api/rest_v1/page/random/summary',
    );
    final response = await get(uri);

    if (response.statusCode != 200) {
      throw HttpException('Requête échouée : ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, Object?>;
    return Summary.fromJson(data);
  }
}

class ArticleViewModel extends ChangeNotifier {
  ArticleViewModel(this.model) {
    getRandomArticleSummary();
  }

  final ArticleModel model;

  Summary? summary;
  String? errorMessage;
  bool loading = false;

  final List<Summary> _history = <Summary>[];

  Summary? get previousSummary {
    if (_history.length < 2) {
      return null;
    }
    return _history[_history.length - 2];
  }

  Future<void> getRandomArticleSummary() async {
    loading = true;
    notifyListeners();

    try {
      final result = await model.getRandomArticleSummary();
      summary = result;
      errorMessage = null;
      _history.add(result);

      if (_history.length > 10) {
        _history.removeAt(0);
      }
    } on HttpException catch (error) {
      summary = null;
      errorMessage = error.message;
    } on FormatException {
      summary = null;
      errorMessage = 'Réponse JSON invalide.';
    } on SocketException {
      summary = null;
      errorMessage = 'Erreur réseau : vérifiez votre connexion internet.';
    } catch (_) {
      summary = null;
      errorMessage = 'Une erreur inconnue est survenue.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void goToPrevious() {
    if (_history.length < 2) return;

    _history.removeLast(); // retire l'article courant de la pile
    summary = _history.last; // l'article précédent devient le courant
    errorMessage = null;
    notifyListeners();
  }
}

class ArticleView extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  ArticleView({super.key});

  // Le ViewModel est instancié ici — il vivra tant que ce widget existera
  final ArticleViewModel viewModel = ArticleViewModel(ArticleModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wikipedia Flutter'),
        actions: [
          ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) {
              return TextButton(
                onPressed: viewModel.previousSummary == null
                    ? null
                    : viewModel.goToPrevious,
                child: const Text('Précédent'),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          return switch ((
            viewModel.loading,
            viewModel.summary,
            viewModel.errorMessage,
          )) {
            (true, _, _) => const Center(child: CircularProgressIndicator()),
            (false, _, String message) => Center(child: Text(message)),
            (false, null, null) => const Center(
              child: Text('Une erreur inconnue est survenue'),
            ),
            (false, Summary summary, null) => ArticlePage(
              summary: summary,
              onPressed: viewModel.getRandomArticleSummary,
            ),
          };
        },
      ),
    );
  }
}

class ArticlePage extends StatelessWidget {
  const ArticlePage({
    super.key,
    required this.summary,
    required this.onPressed,
  });

  final Summary summary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ArticleWidget(summary: summary),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: onPressed,
              child: const Text('Article suivant'),
            ),
          ),
        ],
      ),
    );
  }
}

class ArticleWidget extends StatelessWidget {
  const ArticleWidget({super.key, required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final image = summary.preferredSource;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.hasImage && image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                image.source,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          const SizedBox(height: 10),
          Text(
            summary.titles.normalized,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineMedium,
          ),
          if (summary.description != null) ...[
            const SizedBox(height: 10),
            Text(
              summary.description!,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          Text(summary.extract),
        ],
      ),
    );
  }
}
