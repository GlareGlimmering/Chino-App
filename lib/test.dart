import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final messageProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await http.get(Uri.parse("http://142.171.176.173:8000/message"));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Failed to load message");
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


class ChinoHome extends ConsumerWidget{
  const ChinoHome({super.key});

  @override

  Widget build(BuildContext context,WidgetRef ref){
    return Scaffold(
      body:Center(
        child: Consumer(
          builder: (context, ref, child) {
            final asyncValue = ref.watch(messageProvider);

            return asyncValue.when(
              data: (data) => Text('${data["data"]}'),
              loading: () => CircularProgressIndicator(),
              error: (err, stack) => Text("Error: $err"),
            );
          },
        )
        ,

      ),
    );
  }
}