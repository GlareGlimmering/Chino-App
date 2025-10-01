import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
part 'Infinity_List.freezed.dart';
part 'Infinity_List.g.dart';

@freezed
class Message with _$Message{
  const factory Message({
    required String msg,
    required String data,
    @Default(false)bool isMark,
  })=_Message;
  factory Message.fromJson(Map<String,dynamic>json)=>_$MessageFromJson(json);
}

@freezed
class MessageState with _$MessageState{
  const factory MessageState({
    @Default([]) List<Message> messages,
    @Default(1) int currentPage,
    @Default(false) bool isLoading,
    @Default(true) bool hasMore,
    String? errorMessage,
  }) =_MessageState;
}


const url='http://142.171.176.173:8001';


class MessageNotifier extends StateNotifier<MessageState>{
  /*
  构造函数初始化列表 + 构造函数体。
  MessageNotifier() 是构造函数。
  : super(const MessageState()) 表示在构造函数运行之前，先调用父类 StateNotifier 的构造函数，并传入初始状态 MessageState()。
  { fetchNextPage(); } 是构造函数体，表示一创建对象时就立刻执行 fetchNextPage()。
  👉 用途：初始化时设置初始状态，并马上触发一次数据加载。
 */
  MessageNotifier():super(const MessageState()){
    fetchNextPage();
  }

  Future<List<Message>> _fetchApiData(int page) async{
    final apiUrl='$url/message?page=$page&limit=10';

    final response=await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': 'i312100F',
        }
    );

    if(response.statusCode==200){
      final Map<String,dynamic>jsonMap=json.decode(response.body);
      final List<dynamic>jsonList=jsonMap['data'];

      /*
        Dart 的集合操作写法。
        map()：对列表里的每一项做一次转换。
        (json) => Message(...)：匿名函数（箭头函数），把每个 json 转成一个 Message 对象。
        as String：类型转换。
        .toList()：把 Iterable 结果再转回 List。
        👉 用途：把从后端拿到的 List<Map<String, dynamic>> 转成前端用的 List<Message> 对象。
       */
      return jsonList.map(
              (json)=>Message
            (
            msg: json['msg'] as String,
            data: json['data'] as String,
          )
      ).toList();
    }
    else{
      throw Exception('Failed to load page $page');
    }
  }

  /*
    异步函数定义。
    Future<void>：表示返回一个 Future（异步结果），但这个 Future 完成时不返回任何值。
    async：说明函数体里可以用 await 去等待异步操作（比如 http.get）。
    👉 用途：在分页加载时，请求下一页数据，并更新状态。
   */
  Future<void> fetchNextPage() async{
    if(state.isLoading || !state.hasMore) return;

    state=state.copyWith(isLoading: true,errorMessage: null);

    try{
      final newMessages=await _fetchApiData(state.currentPage);
      final hasMore= newMessages.length==10;//如何判断
      state=state.copyWith(
        messages: [...state.messages,...newMessages],
        currentPage: state.currentPage+1,
        hasMore: hasMore,
        isLoading: false,
      );


    }catch(e){
      state=state.copyWith(
        errorMessage: e.toString(),
        isLoading:false,
      );
    }
  }

  void deleteData(int index){
    final updateMsg=[...state.messages];
    updateMsg.removeAt(index);
    state=state.copyWith(
      messages: [...updateMsg],
    );

  }

  void mark(int index){
    final updateMgs=[...state.messages];
    updateMgs[index]=updateMgs[index].copyWith(isMark: !updateMgs[index].isMark);
    state=state.copyWith(
      messages: updateMgs,
    );
  }

  void reload(){
    fetchNextPage();
  }
}

final messageProvider=StateNotifierProvider<MessageNotifier,MessageState>(
      (ref)=>MessageNotifier(),
);


void main(){
  runApp(ProviderScope(child: Chino()));
}

class Chino extends StatelessWidget{
  const Chino({super.key});
  @override
  Widget build(BuildContext context){
    return MaterialApp(home: ChinoHomePage(),);
  }
}

class ChinoHomePage extends ConsumerWidget{
  const ChinoHomePage({super.key});
  @override
  Widget build(BuildContext context,WidgetRef ref){
    final stateWatch=ref.watch(messageProvider);
    final stateRead=ref.read(messageProvider.notifier);
    final ScrollController scrollController=ScrollController();

    /*
      滚动监听器：
      scrollController.addListener：每次用户滚动时都会触发回调。
      scrollController.position.pixels：当前滚动位置（已经滚过多少像素）。
      scrollController.position.maxScrollExtent：最大滚动范围（列表的最底部）。
      >= 0.8 * maxScrollExtent：如果滚动到了底部的 80% 位置，就触发加载下一页。
      ref.read(messageProvider.notifier).fetchNextPage()：通知 MessageNotifier 去加载更多数据。
      👉 用途：实现 无限滚动加载（用户快到底部时，自动加载下一页）。
     */

    scrollController.addListener((){
      if(scrollController.position.pixels>=scrollController.position.maxScrollExtent *0.9){
        ref.read(messageProvider.notifier).fetchNextPage();
      }
    });


    //
    // scrollController.animateTo(
    //     scrollController.position.maxScrollExtent,
    //     duration: Duration(microseconds: 300),
    //     curve: Curves.easeOut
    // );


    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                controller: scrollController,
                itemCount: stateWatch.messages.length+1,
                itemBuilder: (BuildContext context,int index){
                  if(index<stateWatch.messages.length){
                    final message=stateWatch.messages[index];
                    return Card(
                      color: stateWatch.messages[index].isMark?Colors.orangeAccent:null,
                      child: ListTile(

                        title: Text(
                          message.msg,
                          style: TextStyle(fontWeight: stateWatch.messages[index].isMark?FontWeight.bold:FontWeight.normal),
                        ),
                        subtitle: Text(message.data),

                        onLongPress: ()=>stateRead.deleteData(index),

                        trailing: IconButton(
                          onPressed: ()=>stateRead.mark(index),
                          icon: Icon(
                            Icons.favorite,
                            color: stateWatch.messages[index].isMark?Colors.redAccent:null,
                          ),
                        ),
                      ),
                    );
                  }
                  else{
                    return _buildListFooter(stateWatch);
                  }

                }
            ),
          ),
          SizedBox(height: 30,),
          FloatingActionButton(
            onPressed: ()=>stateRead.reload(),
            child: Icon(Icons.refresh),
          )
        ],
      ),
    );
  }

  /*
    _buildListFooter 的作用
    在无限列表里，通常需要一个「列表尾部」：
    当正在加载时 → 显示 CircularProgressIndicator（转圈）。
    当没有更多数据时 → 显示 “没有更多了”。
    当出错时 → 显示 “加载失败，点我重试”。
    _buildListFooter 就是一个单独的 Widget 方法，用来统一构建这种列表尾部 UI。
    👉 用途：提供用户友好的「列表底部状态提示」。
   */
  Widget _buildListFooter(MessageState state) {
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: ${state.errorMessage}', style: const TextStyle(color: Colors.red)),
        ),
      );
    } else if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (!state.hasMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No more data to load.'),
        ),
      );
    }
    return const SizedBox.shrink(); // 正常情况下不显示任何内容
  }

}

