/*
这个例子主要完成如下：
  1.使用业界通用的freezed规范（也包括手写版本）；
  2.使用业界通用的StateNotifierProvider；
  3.http访问的基本样例；
  4.长列表视角自动最底部；


 */

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;

part 'get_server_time_and_show_in_order.freezed.dart';

//使用freezed
@freezed
class NewsText with _$NewsText{
  const factory NewsText({
    required String texts,
    @Default(false) bool isFavorite,
  })= _NewsText;
}

@freezed
class NewsState with _$NewsState{
  const factory NewsState({
    @Default([])List<NewsText>newsList,
  })=_NewsState;
}

//使用手写copyWith
// class NewsText{
//   String texts;
//   bool isFavorite;
//   NewsText({required this.texts,this.isFavorite=false});
//
//   NewsText copyWith({String ? texts,bool ? isFavorite}){
//     return NewsText(
//       texts: texts ?? this.texts,
//       isFavorite: isFavorite ?? this.isFavorite,
//     );
//   }
// }
//
// class NewsState{
//   final List<NewsText> newsList;
//
//   NewsState({required this.newsList});
//
//   NewsState copyWith({List<NewsText> ? newsList}){
//     return NewsState(
//         newsList: newsList ?? this.newsList,
//     );
//   }
// }

final newsProvider=StateNotifierProvider<NewsNotifier,NewsState>((ref)=>NewsNotifier());
class NewsNotifier extends StateNotifier<NewsState>{
  NewsNotifier() : super(NewsState());

  void addData(String data){
    final updatedList=[...state.newsList,NewsText(texts: data)];
    state=state.copyWith(newsList: updatedList);
  }

  void clearAll(){
    state=state.copyWith(newsList: []);
  }

  void changeTextState(int index){
    final updatedList=[...state.newsList];
    updatedList[index]=updatedList[index].copyWith(isFavorite: !updatedList[index].isFavorite);
    state=state.copyWith(newsList: updatedList);
  }

}

const String apiKey = "i312100F"; // 必须与服务器端设置的密钥一致！

final messageProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final url = 'http://142.171.176.173:8000/message'; // 替换为你的服务器地址和端口

  try {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
    };

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    else if (response.statusCode == 401) {
      final errorDetail = json.decode(response.body)['detail'] ?? 'Authorization Failed';
      throw Exception('API Key Verification Failed: $errorDetail');
    }
    else {
      throw Exception("Failed to load data. Status: ${response.statusCode}");
    }
  } catch (e) {
    throw Exception("Network or other error: $e");
  }
});


void main(){
  runApp(ProviderScope(child: Chino()));
}

class Chino extends StatelessWidget{
  const Chino({super.key});

  @override

  Widget build(BuildContext context){
    return MaterialApp(home: ChinoHome(),);
  }

}


class ChinoHome extends ConsumerStatefulWidget {
  const ChinoHome({super.key});

  @override
  ConsumerState<ChinoHome> createState() => _ChinoHomeState();
}

class _ChinoHomeState extends ConsumerState<ChinoHome> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);
    final newsAsyncRead=ref.read(newsProvider.notifier);
    final httpAsync = ref.watch(messageProvider);

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: newsAsync.newsList.length,
                itemBuilder: (BuildContext context, int index) {

                  return Card(
                    elevation: newsAsync.newsList[index].isFavorite?5:null,
                    color: newsAsync.newsList[index].isFavorite?Colors.orangeAccent:null,

                    child: ListTile(
                      title: Text(
                        newsAsync.newsList[index].texts,
                        style: TextStyle(
                          fontWeight: newsAsync.newsList[index].isFavorite?FontWeight.bold:null,
                        ),
                      ),
                      trailing: IconButton(
                          onPressed: (){
                            newsAsyncRead.changeTextState(index);
                          },
                          icon: Icon(
                            Icons.favorite,
                            color: newsAsync.newsList[index].isFavorite?Colors.redAccent:null,
                          )
                      ),

                      // onTap: (){
                      //   showDialog(
                      //       context: context,
                      //       builder: (context){
                      //         return AlertDialog(
                      //           content: TextButton(
                      //               onPressed:(){
                      //                 newsAsync.changeTextState(index);
                      //                 Navigator.pop(context);
                      //               },
                      //               child: Icon(Icons.favorite)
                      //           ),
                      //
                      //
                      //         );
                      //       },
                      //   );
                      // },

                    ),
                  );
                },
              ),
            ),

            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      newsAsyncRead.addData(
                        httpAsync.when(
                          data: (data) => data['data'].toString(),
                          error: (err, stack) => "Error: $err",
                          loading: () => "Loading...",
                        ),
                      );

                      ref.refresh(messageProvider);

                      _scrollToBottom();
                    },
                    child: Icon(Icons.android),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      newsAsyncRead.clearAll();
                    },
                    child: Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

