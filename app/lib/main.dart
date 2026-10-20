import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MosaediApp());

const brand = Color(0xFF6C63FF);
const bg = Color(0xFF0B1020);
const panel = Color(0xFF141B2D);

class MosaediApp extends StatelessWidget {
  const MosaediApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mosaedi AI',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.dark),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    ),
    home: const ChatPage(),
  );
}

class ChatItem {
  final String role;
  final String text;
  ChatItem(this.role, this.text);
  Map<String, dynamic> toJson() => {'role': role, 'content': text};
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final messages = <ChatItem>[
    ChatItem('assistant', 'أهلًا بك! أنا مساعدك الذكي Mosaedi AI. كيف أقدر أساعدك اليوم؟')
  ];
  String server = 'http://10.0.2.2:8000';
  String userId = 'demo-user';
  bool busy = false;
  String status = 'جاهز للمحادثة';

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      server = p.getString('server') ?? server;
      userId = p.getString('userId') ?? userId;
    });
  }

  Future<void> openSettings() async {
    final serverCtl = TextEditingController(text: server);
    final userCtl = TextEditingController(text: userId);
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('إعدادات الاتصال'),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: serverCtl, decoration: const InputDecoration(labelText: 'عنوان الخادم')),
        const SizedBox(height: 12),
        TextField(controller: userCtl, decoration: const InputDecoration(labelText: 'معرّف تجريبي للمستخدم')),
        const SizedBox(height: 10),
        const Text('هذه نسخة تجريبية؛ تسجيل Google الفعلي يحتاج إعداد Firebase والتحقق من الرمز في الخادم.', style: TextStyle(fontSize: 12, color: Colors.white70)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
      ],
    ));
    if (result == true) {
      final p = await SharedPreferences.getInstance();
      await p.setString('server', serverCtl.text.trim());
      await p.setString('userId', userCtl.text.trim().isEmpty ? 'demo-user' : userCtl.text.trim());
      setState(() { server = serverCtl.text.trim(); userId = userCtl.text.trim().isEmpty ? 'demo-user' : userCtl.text.trim(); status = 'تم حفظ الإعدادات'; });
    }
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || busy) return;
    setState(() { messages.add(ChatItem('user', text)); input.clear(); busy = true; status = 'يفكر الآن…'; });
    try {
      final resp = await http.post(
        Uri.parse('$server/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'messages': messages.map((m) => m.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 70));
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200) {
        setState(() {
          messages.add(ChatItem('assistant', '${data['text']}\n\n— ${data['provider']} · الحصة التجريبية المتبقية: ${data['remaining_demo_quota']}'));
          status = 'متصل';
        });
      } else {
        setState(() { messages.add(ChatItem('assistant', 'تعذر إكمال الطلب: ${data['detail'] ?? resp.statusCode}')); status = 'تعذر الاتصال'; });
      }
    } catch (_) {
      setState(() { messages.add(ChatItem('assistant', 'لم أستطع الاتصال بالخادم. تأكد أنه يعمل وأن عنوان الخادم صحيح من الإعدادات.')); status = 'غير متصل'; });
    } finally {
      setState(() => busy = false);
      await Future.delayed(const Duration(milliseconds: 100));
      if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() { input.dispose(); scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        title: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(gradient: const LinearGradient(colors: [brand, Color(0xFF25C2A0)]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.auto_awesome_rounded, color: Colors.white)),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mosaedi AI', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('مساعدك الذكي', style: TextStyle(fontSize: 11, color: Colors.white60)),
          ]),
        ]),
        actions: [IconButton(onPressed: openSettings, icon: const Icon(Icons.tune_rounded), tooltip: 'الإعدادات')],
      ),
      body: SafeArea(child: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF24204B), Color(0xFF142B3B)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(.07)),
          ),
          child: Row(children: [
            const Icon(Icons.bolt_rounded, color: Color(0xFF9B91FF), size: 28),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('جاهز لمساعدتك', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(status, style: const TextStyle(fontSize: 12, color: Colors.white60)),
            ])),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: busy ? Colors.orange : Colors.greenAccent, shape: BoxShape.circle)),
          ]),
        ),
        Expanded(child: ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, i) {
            final m = messages[i];
            final mine = m.role == 'user';
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mine ? const Color(0xFF5148C9) : panel,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(mine ? 18 : 5), bottomRight: Radius.circular(mine ? 5 : 18),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(.05)),
                ),
                child: Text(m.text, style: const TextStyle(height: 1.5)),
              ),
            );
          },
        )),
        if (busy) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator(minHeight: 2)),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(color: bg, border: Border(top: BorderSide(color: Colors.white12))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: TextField(
              controller: input,
              minLines: 1, maxLines: 5,
              onSubmitted: (_) => send(),
              decoration: const InputDecoration(hintText: 'اكتب رسالتك هنا...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
            )),
            const SizedBox(width: 8),
            SizedBox(height: 50, width: 50, child: FilledButton(
              onPressed: busy ? null : send,
              style: FilledButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Icon(Icons.arrow_upward_rounded),
            )),
          ]),
        ),
      ])),
    ),
  );
}
