import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'test.dart';
import 'test2.dart';
import 'test3.dart';

void main(){
  runApp(ProviderScope(child: Message()));
}

class Message extends StatelessWidget{
  const Message({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(home: MessagePage(),);
  }
}

class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({super.key});

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage> {
  static const _pageSize = 10;

  final PagingController<int, Message> _pagingController =
  PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();

    // ✅ 绑定分页加载回调
    _pagingController.addPageRequestListener((pageKey) {
      ref.read(messageNotifierProvider.notifier).fetchPage(pageKey);
    });

    // ✅ 监听 provider 状态，驱动 pagingController
    ref.listen<MessageStates>(messageNotifierProvider, (prev, next) {
      if (next.hasError) {
        _pagingController.error = "加载失败";
      } else if (!next.isLoading) {
        final isLastPage = !next.hasNextPage;
        if (isLastPage) {
          _pagingController.appendLastPage(next.items);
        } else {
          final nextPageKey = next.page + 1;
          _pagingController.appendPage(next.items, nextPageKey);
        }
      }
    });

    // ✅ 首次加载（避免 build 时触发）
    Future.microtask(() {
      ref.read(messageNotifierProvider.notifier).fetchPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: PagedListView<int, Message>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Message>(
          itemBuilder: (context, item, index) {
            return ListTile(
              title: Text(item.msg),
              subtitle: Text(item.data),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
