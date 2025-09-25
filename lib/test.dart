import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsItem {
  final String text;
  final bool isFavorite;
  NewsItem({required this.text, this.isFavorite = false});

  NewsItem copyWith({String? text, bool? isFavorite}) {
    return NewsItem(
      text: text ?? this.text,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// 1. 定义状态
class NewsState {
  final List<NewsItem> newsList;
  NewsState({required this.newsList});

  // 复制一个新状态（不可变模式）
  NewsState copyWith({List<NewsItem>? newsList}) {
    return NewsState(newsList: newsList ?? this.newsList);
  }
}



// 2. 定义 Notifier
class NewsNotifier extends StateNotifier<NewsState> {
  NewsNotifier() : super(NewsState(newsList: []));

  void addNews(String text) {
    final newItem = NewsItem(text: text);
    state = state.copyWith(newsList: [...state.newsList, newItem]);
  }

  void toggleFavorite(int index) {
    final updated = [...state.newsList];
    final item = updated[index];
    updated[index] = item.copyWith(isFavorite: !item.isFavorite);
    state = state.copyWith(newsList: updated);
  }

  void clearAll() {
    state = state.copyWith(newsList: []);
  }
}

// 3. 提供给 UI
final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  return NewsNotifier();
});
