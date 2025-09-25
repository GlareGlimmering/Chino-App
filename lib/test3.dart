import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewsText{
  String texts;
  bool isBold;
  NewsText({required this.texts,this.isBold=false});
}

final newsProvider=ChangeNotifierProvider((ref)=>News());
class News extends ChangeNotifier{
  final List<NewsText> _newsList=[];
  List<NewsText> get newsList=>_newsList;

  void addData(String data){
    _newsList.add(NewsText(texts: data));
    notifyListeners();
  }

  void clearAllData(){
    _newsList.clear();
    notifyListeners();
  }

}

const String API_KEY = "i312100F"; // 必须与服务器端设置的密钥一致！

final messageProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final url = 'http://142.171.176.173:8000/message'; // 替换为你的服务器地址和端口

  try {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'X-API-Key': API_KEY,
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
    // 处理网络错误等
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
                    child: ListTile(
                      title: Text(newsAsync.newsList[index].texts),
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
                      ref.read(newsProvider).addData(
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
                      newsAsync.clearAllData();
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

