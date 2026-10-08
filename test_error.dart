import 'dart:async';

Future<List<String>> getStrings() async {
  List<dynamic> res = [{'id': 1}, {'id': 2}];
  return res.map((e) {
    if (e['id'] == 1) throw FormatException("Boom!");
    return "Test";
  }).toList();
}

void main() async {
  try {
    final future = getStrings().catchError((e) {
      print("Caught in catchError: $e");
      return <String>[];
    });
    
    final futures = await Future.wait([future]);
    print("Wait finished: $futures");
    
    final res = futures[0] as List<String>;
    print("Res: $res");
  } catch (e) {
    print("Caught in outer: $e");
  }
}
