import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> getTransactionToken() async {
  final response = await http.post(
    Uri.parse("https://your-backend.com/get-token"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "order_id": "order-123",
      "amount": 50000,
      "customer_name": "Budi"
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['token'];
  } else {
    print("Failed to get token");
    return null;
  }
}
