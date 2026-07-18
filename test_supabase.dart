import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://yuxfrgxdvuwfqwzsiezf.supabase.co/rest/v1';
  final anonKey = 'sb_publishable_PHGiUyOddWPoaeUkpSQNMQ_RnSLOjnA';

  try {
    final cat2Res = await http.get(
      Uri.parse('$url/categories'),
      headers: {'apikey': anonKey, 'Authorization': 'Bearer $anonKey'},
    );
    print('Categories: ${cat2Res.body}');
  } catch (e) {
    print('Error: $e');
  }
}
