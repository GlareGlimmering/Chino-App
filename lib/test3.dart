import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'test.dart';
import 'test2.dart';

final messageNotifierProvider =
StateNotifierProvider<MessageNotifier, MessageStates>(
      (ref) => MessageNotifier(),
);

class MessageNotifier extends StateNotifier<MessageStates> {
  MessageNotifier() : super(const MessageStates());

  Future<void> fetchPage(int pageKey) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, hasError: false);

    try {
      // 假设：每次加载 10 条
      final newItems = await _fetchFromServer(pageKey);

      final isLastPage = newItems.length < 10;

      state = state.copyWith(
        items: [...state.items, ...newItems],
        page: pageKey,
        isLoading: false,
        hasNextPage: !isLastPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  Future<List<Message>> _fetchFromServer(int pageKey) async {
    // 这里你可以用 dio/http 请求
    // 我先 mock 一下
    await Future.delayed(const Duration(seconds: 1));
    return List.generate(
      10,
          (index) => Message(
        msg: "Hello from server",
        data: DateTime.now().toString(),
      ),
    );
  }
}
