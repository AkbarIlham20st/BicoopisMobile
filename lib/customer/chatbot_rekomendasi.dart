import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

// Konstanta untuk string
const String appTitle = 'Asisten Bot Bicopi';
const String botAvatarText = 'B';
const String userAvatarText = 'A';
const String defaultMessage = 'Tanyakan sesuatu tentang minuman!';
const String botTypingMessage = 'Bot sedang mengetik... 💬';
const String searchErrorMessage = 'Oops! Ada masalah saat aku cari datanya: ';
const String noMatchMessage = 'Belum ketemu yang cocok dengan "';
const String tryOtherKeywordsMessage = '", tapi kamu bisa coba kata lain seperti "dingin", "manis", atau "kopi"! 😉';
const String recommendationPrefix = 'Aku punya beberapa rekomendasi nih buat kamu yang suka "';
const String recommendationSuffix = '":\n\n'; // Ubah untuk fleksibilitas
const String aiErrorMessagePrefix = 'Maaf, terjadi kesalahan AI: ';
const String technicalErrorMessagePrefix = 'Terjadi kesalahan teknis: ';
const String textFieldHint = 'Tanya tentang minuman...';

// Konstanta untuk warna
const Color primaryColor = Color(0xFF078603);
const Color backgroundColor = Color(0xFFF0F2F5);
const Color userMessageColor = Color(0xFFDFFFD6);
const Color textFieldBackgroundColor = Color(0xFFF1F1F1);
const Color whiteColor = Colors.white;
const Color greyColor = Colors.grey;

// Controller untuk memicu handleSubmitted dari Quick Reply
class DefaultChatbotController extends InheritedWidget {
  const DefaultChatbotController({
    super.key,
    required this.handleSubmitted,
    required super.child,
  });

  final Function(String) handleSubmitted;

  static DefaultChatbotController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DefaultChatbotController>();
  }

  @override
  bool updateShouldNotify(DefaultChatbotController oldWidget) {
    return handleSubmitted != oldWidget.handleSubmitted;
  }
}

class ChatbotRekomendasi extends StatefulWidget {
  const ChatbotRekomendasi({super.key});

  @override
  State<ChatbotRekomendasi> createState() => _ChatbotRekomendasiState();
}

class _ChatbotRekomendasiState extends State<ChatbotRekomendasi> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isBotTyping = false;

  void _handleSubmitted(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isNotEmpty) {
      _textController.clear();
      setState(() {
        _messages.insert(0, ChatMessage(text: trimmedText, isUser: true));
        _isBotTyping = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      String rawBotResponse = await _generateBotResponse(trimmedText);

      setState(() {
        _isBotTyping = false; // Set false sebelum menambahkan pesan

        // Cek apakah ini adalah respons khusus dengan quick replies
        if (rawBotResponse.startsWith('CUSTOM_MESSAGE_WITH_QUICK_REPLY:')) {
          final parts = rawBotResponse.split(':');
          if (parts.length == 4) { // Memastikan format sesuai: COMMAND:KEYWORD:INITIAL_RECS:REMAINING_COUNT
            final keyword = parts[1];
            final initialRecommendations = parts[2].replaceAll('\\n', '\n'); // Ganti kembali newline jika ada
            final remainingCount = parts[3];

            final String botText = '$recommendationPrefix"$keyword"$recommendationSuffix$initialRecommendations\n\nAda lagi $remainingCount menu lainnya!';
            final List<String> quickReplies = ['Tampilkan semua $keyword'];

            _messages.insert(0, ChatMessage(text: botText, isUser: false, quickReplies: quickReplies));
          } else {
             // Fallback jika format tidak sesuai
            _messages.insert(0, ChatMessage(text: rawBotResponse, isUser: false));
          }
        } else {
          // Respons normal tanpa quick replies
          _messages.insert(0, ChatMessage(text: rawBotResponse, isUser: false));
        }
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _generateBotResponse(String userInput) async {
    final lowerCaseInput = userInput.toLowerCase();

    // --- Perintah salam dan pembuka & umum ---
    if (lowerCaseInput.contains('halo')) {
      return 'Iya, bisa saya bantu? Saya asisten bot Bicopi Anda.';
    } else if (lowerCaseInput.contains('selamat pagi')) {
      return 'Selamat pagi! Ada yang bisa saya bantu terkait minuman hari ini?';
    } else if (lowerCaseInput.contains('selamat siang')) {
      return 'Selamat siang! Ada yang bisa saya bantu terkait minuman hari ini?';
    } else if (lowerCaseInput.contains('selamat sore')) {
      return 'Selamat sore! Ada yang bisa saya bantu terkait minuman hari ini?';
    } else if (lowerCaseInput.contains('selamat malam')) {
      return 'Selamat malam! Ada yang bisa saya bantu terkait minuman hari ini?';
    } else if (lowerCaseInput.contains('siapa kamu') || lowerCaseInput.contains('kamu ini apa')) {
      return 'Saya adalah Asisten Bot Bicopi, siap membantu Anda menemukan minuman favorit atau menjawab pertanyaan seputar minuman!';
    } else if (lowerCaseInput.contains('terima kasih') || lowerCaseInput.contains('makasih')) {
      return 'Sama-sama! Senang bisa membantu. Ada lagi yang bisa saya bantu?';
    } else if (lowerCaseInput.contains('ada menu apa saja') || lowerCaseInput.contains('daftar minuman') || lowerCaseInput == 'menu') {
      return 'Tentu! Kami punya berbagai macam minuman. Anda bisa tanyakan \'minuman kopi\', \'minuman non-kopi\', \'minuman dingin\', atau \'minuman manis\' untuk rekomendasi! Atau coba sebutkan kategori seperti "kopi" atau "manis".';
    } else if (lowerCaseInput.contains('buka jam berapa') || lowerCaseInput.contains('jam operasional')) {
      return 'Kami buka setiap hari dari jam 08.00 pagi sampai 10.00 malam. Yuk, mampir!';
    } else if (lowerCaseInput.contains('ada promo') || lowerCaseInput.contains('diskon apa saja')) {
      // Contoh respons statis untuk promo, bisa diganti dengan data dari Supabase jika ada tabel promo
      return 'Saat ini kami sedang ada promo "Beli 2 Es Kopi Susu Gratis 1 Es Teh Manis" sampai akhir bulan ini! Jangan sampai kelewatan ya. 😉';
    } else if (lowerCaseInput.contains('saya bosan') || lowerCaseInput.contains('apa yang enak')) {
      // Contoh rekomendasi acak, bisa diambil dari Supabase
      final List<String> randomSuggestions = ['Es Kopi Susu Gula Aren', 'Matcha Latte', 'Ice Lemon Tea'];
      randomSuggestions.shuffle();
      return 'Wah, kalau lagi bosan, coba deh ${randomSuggestions.first}! Atau, kamu lebih suka yang manis, dingin, atau kopi?';
    }
    // --- Akhir perintah salam dan pembuka & umum ---

    final Map<String, String> keywordMap = {
      'manis': 'sweet',
      'kopi': 'coffee',
      'dingin': 'cold',
      'panas': 'hot',
      'hangat': 'warm',
      'segar': 'refreshing',
      'coklat': 'chocolate',
      'mangga': 'mango',
      'susu': 'milk',
      'air': 'water',
      'teh': 'tea',
      'buah': 'fruit',
      'jeruk': 'orange',
      'lemon': 'lemon',
      'espresso': 'espresso',
      'latte': 'latte',
      'americano': 'americano',
      'non-kopi': 'non-coffee', // Keyword untuk non-kopi
    };

    String? matchedKeyword;
    String? translatedKeyword;

    // Prioritaskan pencarian keyword dari map
    for (final entry in keywordMap.entries) {
      if (lowerCaseInput.contains(entry.key)) {
        matchedKeyword = entry.key;
        translatedKeyword = entry.value;
        break;
      }
    }

    // --- Penanganan untuk "tampilkan semua [keyword]" ---
    // Logika ini harus di atas pencarian keyword utama, karena ini adalah perintah spesifik
    // if (lowerCaseInput.startsWith('tampilkan semua ')) {
    //   String queryKeywordPart = lowerCaseInput.substring('tampilkan semua '.length).trim();
    //   String? originalKeywordForDisplay;
    //   String? translatedKeywordForDisplay;
    //
    //   // Cari keyword asli dari query "tampilkan semua"
    //   for (final entry in keywordMap.entries) {
    //     if (queryKeywordPart.contains(entry.key)) {
    //       originalKeywordForDisplay = entry.key;
    //       translatedKeywordForDisplay = entry.value;
    //       break;
    //     }
    //   }
    //
    //   // Khusus penanganan "non-kopi"
    //   if (queryKeywordPart.contains('non-kopi')) {
    //     originalKeywordForDisplay = 'non-kopi';
    //     translatedKeywordForDisplay = 'non-coffee';
    //   }
    //
    //
    //   if (originalKeywordForDisplay != null && translatedKeywordForDisplay != null) {
    //     try {
    //       final response = await Supabase.instance.client
    //           .from('menu')
    //           .select('nama_menu')
    //           // Untuk "non-coffee", kita mencari yang TIDAK mengandung 'coffee'
    //           .ilike('deskripsi_menu', translatedKeywordForDisplay == 'non-coffee' ? '%coffee%' : '%$translatedKeywordForDisplay%')
    //           .filter(translatedKeywordForDisplay == 'non-coffee' ? 'deskripsi_menu' : 'nama_menu', translatedKeywordForDisplay == 'non-coffee' ? 'not.ilike' : 'ilike', translatedKeywordForDisplay == 'non-coffee' ? '%coffee%' : '%$translatedKeywordForDisplay%')
    //           .execute();
    //
    //
    //       if (response.error != null) {
    //         return '$searchErrorMessage${response.error!.message} 😓';
    //       }
    //
    //       final data = response.data as List<dynamic>?;
    //
    //       if (data == null || data.isEmpty) {
    //         return 'Maaf, tidak ada menu yang cocok dengan "${originalKeywordForDisplay}".';
    //       }
    //
    //       List<String> allRekomendasi = data.map<String>((item) {
    //         final nama = item['nama_menu'] ?? 'Minuman';
    //         return '• $nama';
    //       }).toList();
    //
    //       return 'Berikut semua menu yang cocok dengan "${originalKeywordForDisplay}":\n\n${allRekomendasi.join('\n')}\n\nAda lagi yang bisa saya bantu? 😊';
    //     } catch (e) {
    //       return '$technicalErrorMessagePrefix$e';
    //     }
    //   } else {
    //     return 'Maaf, saya tidak mengerti keyword yang Anda maksud. Coba ulangi dengan keyword yang spesifik, misalnya "tampilkan semua kopi" atau "tampilkan semua manis".';
    //   }
    // }
    // --- Akhir penanganan "tampilkan semua [keyword]" ---

    if (lowerCaseInput.startsWith('tampilkan semua ')) {
      String queryKeywordPart = lowerCaseInput.substring('tampilkan semua '.length).trim();
      String? originalKeywordForDisplay;
      String? translatedKeywordForDisplay;

      // Cari keyword asli dari query "tampilkan semua"
      for (final entry in keywordMap.entries) {
        if (queryKeywordPart.contains(entry.key)) {
          originalKeywordForDisplay = entry.key;
          translatedKeywordForDisplay = entry.value;
          break;
        }
      }

      // Khusus penanganan "non-kopi"
      if (queryKeywordPart.contains('non-kopi')) {
        originalKeywordForDisplay = 'non-kopi';
        translatedKeywordForDisplay = 'non-coffee';
      }

      if (originalKeywordForDisplay != null && translatedKeywordForDisplay != null) {
        try {
          final query = Supabase.instance.client
              .from('menu')
              .select('nama_menu');
              // .select<List<Map<String, dynamic>>>('nama_menu');

          final data = translatedKeywordForDisplay == 'non-coffee'
              ? await query.not('deskripsi_menu', 'ilike', '%coffee%')
              : await query.or(
              'deskripsi_menu.ilike.%$translatedKeywordForDisplay%,nama_menu.ilike.%$translatedKeywordForDisplay%');

          if (data.isEmpty) {
            return 'Maaf, tidak ada menu yang cocok dengan "${originalKeywordForDisplay}".';
          }

          List<String> allRekomendasi = data.map<String>((item) {
            final nama = item['nama_menu'] ?? 'Minuman';
            return '• $nama';
          }).toList();

          return 'Berikut semua menu yang cocok dengan "${originalKeywordForDisplay}":\n\n${allRekomendasi.join('\n')}\n\nAda lagi yang bisa saya bantu? 😊';
        } catch (e) {
          return '$technicalErrorMessagePrefix$e';
        }
      } else {
        return 'Maaf, saya tidak mengerti keyword yang Anda maksud. Coba ulangi dengan keyword yang spesifik, misalnya "tampilkan semua kopi" atau "tampilkan semua manis".';
      }
    }


    // --- Pencarian berdasarkan keyword dari keywordMap (fungsi utama rekomendasi) ---
    // if (translatedKeyword != null) {
    //   try {
    //     final query = Supabase.instance.client
    //         .from('menu')
    //         .select('nama_menu, deskripsi_menu');
    //
    //     PostgrestResponse response;
    //     if (translatedKeyword == 'non-coffee') {
    //       // Jika keyword adalah 'non-kopi', cari yang deskripsinya TIDAK mengandung 'coffee'
    //       response = await query
    //           .not('deskripsi_menu', 'ilike', '%coffee%')
    //           .execute();
    //     } else {
    //       // Untuk keyword lainnya, cari yang deskripsinya mengandung keyword tersebut
    //       response = await query
    //           .ilike('deskripsi_menu', '%$translatedKeyword%')
    //           .execute();
    //     }
    //
    //     if (response.error != null) {
    //       return '$searchErrorMessage${response.error!.message} 😓';
    //     }
    //
    //     final data = response.data as List<dynamic>?;
    //
    //     if (data == null || data.isEmpty) {
    //       return '$noMatchMessage"$matchedKeyword"$tryOtherKeywordsMessage';
    //     }
    //
    //     List<String> rekomendasi = data.map<String>((item) {
    //       final nama = item['nama_menu'] ?? 'Minuman';
    //       return '• $nama';
    //     }).toList();
    //
    //     const int maxInitialDisplay = 5; // Jumlah menu yang ditampilkan pertama
    //     if (rekomendasi.length > maxInitialDisplay) {
    //       final initialRecommendations = rekomendasi.take(maxInitialDisplay).join('\n');
    //       final remainingCount = rekomendasi.length - maxInitialDisplay;
    //       // Mengembalikan string khusus yang akan diparse oleh _handleSubmitted
    //       // Menggunakan replaceAll('\n', '\\n') agar tidak pecah saat split(':')
    //       return 'CUSTOM_MESSAGE_WITH_QUICK_REPLY:$matchedKeyword:${initialRecommendations.replaceAll('\n', '\\n')}:$remainingCount';
    //     } else {
    //       return '$recommendationPrefix"$matchedKeyword"$recommendationSuffix${rekomendasi.join('\n')}\n\nAda lagi yang bisa saya bantu? 😊';
    //     }
    //   } catch (e) {
    //     return '$technicalErrorMessagePrefix$e';
    //   }
    // }
    if (translatedKeyword != null) {
      try {
        final query = Supabase.instance.client
            .from('menu')
            .select('nama_menu, deskripsi_menu');
            // .select<List<Map<String, dynamic>>>('nama_menu, deskripsi_menu');

        List<Map<String, dynamic>> data;

        if (translatedKeyword == 'non-coffee') {
          // Jika keyword adalah 'non-kopi', cari yang deskripsinya TIDAK mengandung 'coffee'
          data = await query.not('deskripsi_menu', 'ilike', '%coffee%');
        } else {
          // Untuk keyword lainnya, cari yang deskripsinya mengandung keyword tersebut
          data = await query.ilike('deskripsi_menu', '%$translatedKeyword%');
        }

        if (data.isEmpty) {
          return '$noMatchMessage"$matchedKeyword"$tryOtherKeywordsMessage';
        }

        List<String> rekomendasi = data.map<String>((item) {
          final nama = item['nama_menu'] ?? 'Minuman';
          return '• $nama';
        }).toList();

        const int maxInitialDisplay = 5;
        if (rekomendasi.length > maxInitialDisplay) {
          final initialRecommendations = rekomendasi.take(maxInitialDisplay).join('\n');
          final remainingCount = rekomendasi.length - maxInitialDisplay;
          return 'CUSTOM_MESSAGE_WITH_QUICK_REPLY:$matchedKeyword:${initialRecommendations.replaceAll('\n', '\\n')}:$remainingCount';
        } else {
          return '$recommendationPrefix"$matchedKeyword"$recommendationSuffix${rekomendasi.join('\n')}\n\nAda lagi yang bisa saya bantu? 😊';
        }
      } catch (e) {
        return '$technicalErrorMessagePrefix$e';
      }
    }



    // Jika tidak ada keyword cocok dari keywordMap dan bukan perintah 'tampilkan semua' → tanya ke AI (OpenRouter)
    try {
      final aiResponse = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          'Authorization':
              'Bearer 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',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://bicopi.app', // Ganti sesuai domain kamu
          'X-Title': 'Bicopi Chatbot'
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct",
          "messages": [
            {"role": "user", "content": userInput}
          ]
        }),
      );

      if (aiResponse.statusCode == 200) {
        final decoded = jsonDecode(aiResponse.body);
        final content = decoded['choices'][0]['message']['content'];
        return content.trim();
      } else {
        // Coba baca error dari AI jika ada
        String errorDetail = '';
        try {
          final errorBody = jsonDecode(aiResponse.body);
          if (errorBody['error'] != null && errorBody['error']['message'] != null) {
            errorDetail = ': ${errorBody['error']['message']}';
          }
        } catch (_) {
          // ignore parsing error
        }
        return '$aiErrorMessagePrefix${aiResponse.statusCode}$errorDetail. Silakan coba lagi.';
      }
    } catch (e) {
      return '$technicalErrorMessagePrefix$e. Pastikan koneksi internet Anda stabil.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(appTitle),
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        elevation: 0,
      ),
      body: DefaultChatbotController( // Bungkus dengan InheritedWidget
        handleSubmitted: _handleSubmitted, // Berikan fungsi handleSubmitted
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const Center(child: Text(defaultMessage))
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(12.0),
                      itemCount: _messages.length + (_isBotTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isBotTyping && index == _messages.length) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(botTypingMessage),
                            ),
                          );
                        }
                        return _messages[index];
                      },
                    ),
            ),
            const Divider(height: 1.0),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      decoration: const BoxDecoration(
        color: whiteColor,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: textFieldBackgroundColor,
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  decoration: const InputDecoration(
                    hintText: textFieldHint,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            CircleAvatar(
              backgroundColor: primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: whiteColor),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on PostgrestResponse {
  get error => null;
}

// Extensi ini tampaknya tidak diperlukan karena PostgrestResponse sudah memiliki properti 'error'.
// Jika Anda mendapatkan error terkait ini, Anda bisa menghapusnya.
// extension on PostgrestResponse {
//   // get error => null;
// }

class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.quickReplies, // Tambahkan properti ini
  });

  final String text;
  final bool isUser;
  final List<String>? quickReplies; // Daftar teks untuk tombol quick reply

  @override
  Widget build(BuildContext context) {
    final bgColor = isUser ? userMessageColor : whiteColor;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start, // Align avatar to the top
        children: [
          if (!isUser)
            const CircleAvatar(
              backgroundColor: greyColor,
              child: Text(botAvatarText, style: TextStyle(color: whiteColor)),
            ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: align,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: radius,
                  ),
                  child: Text(text),
                ),
                // --- Tambahkan Quick Replies di sini ---
                if (!isUser && quickReplies != null && quickReplies!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap( // Gunakan Wrap untuk tombol yang bisa wrap ke baris baru
                      spacing: 8.0, // Jarak antar tombol horizontal
                      runSpacing: 4.0, // Jarak antar baris vertikal
                      alignment: align == CrossAxisAlignment.start ? WrapAlignment.start : WrapAlignment.end, // Sesuaikan alignment tombol
                      children: quickReplies!.map((replyText) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, // Warna tombol
                            foregroundColor: whiteColor, // Warna teks tombol
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero, // Untuk membuat tombol sekecil mungkin sesuai konten
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Kurangi area sentuh
                          ),
                          onPressed: () {
                            // Panggil fungsi handleSubmitted di _ChatbotRekomendasiState
                            DefaultChatbotController.of(context)?.handleSubmitted(replyText);
                          },
                          child: Text(replyText),
                        );
                      }).toList(),
                    ),
                  ),
                // --- Akhir Quick Replies ---
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          if (isUser)
            const CircleAvatar(
              backgroundColor: primaryColor,
              child: Text(userAvatarText, style: TextStyle(color: whiteColor)),
            ),
        ],
      ),
    );
  }
}