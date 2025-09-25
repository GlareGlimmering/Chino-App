import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const url='http://142.171.176.173:8000/message';

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

final messageProvider=FutureProvider<Map<String,dynamic>>(
    (ref) async{
      final response=await http.get(Uri.parse(url));
      if(response.statusCode==200){
        return json.decode(response.body);
      }
      else{
        throw Exception("Failed to load");
      }
    }
);


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


class ChinoHome extends ConsumerWidget{
  const ChinoHome({super.key});



  @override

  Widget build(BuildContext context,WidgetRef ref){
    final newsAsync=ref.watch(newsProvider);
    final httpAsync=ref.watch(messageProvider);


    return Scaffold(
      body: Center(


        child:Column(

          children: [
            Expanded(
              child: ListView.builder(

                itemCount: newsAsync.newsList.length,
                itemBuilder: (BuildContext context,int index){
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
                    onPressed: (){
                      ref.read(newsProvider).addData(
                        httpAsync.when(
                          data: (data) => data['data'].toString(),
                          error: (err, stack) => "Error: $err",
                          loading: () => "Loading...",
                        ),
                      );
                      ref.refresh(messageProvider);
                    },
                    child: Icon(Icons.apple),
                  ),

                  FloatingActionButton(
                    onPressed: (){
                      newsAsync.clearAllData();
                    },
                    child: Icon(Icons.delete),
                  )

                ],
              ),
            ),






          ],
        )

      ),




    );
  }
}
