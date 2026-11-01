import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

const surahNames = [
  'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف',
  'الأنفال', 'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
  'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون',
  'النور', 'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
  'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر',
  'غافر', 'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية', 'الأحقاف', 'محمد',
  'الفتح', 'الحجرات', 'ق', 'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن',
  'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة', 'الصف', 'الجمعة',
  'المنافقون', 'التغابن', 'الطلاق', 'التحريم', 'الملك', 'القلم', 'الحاقة',
  'المعارج', 'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة', 'الإنسان',
  'المرسلات', 'النبأ', 'النازعات', 'عبس', 'التكوير', 'الانفطار', 'المطففين',
  'الانشقاق', 'البروج', 'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
  'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين', 'العلق', 'القدر', 'البينة',
  'الزلزلة', 'العاديات', 'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل',
  'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص',
  'الفلق', 'الناس',
];

const green = Color(0xFF14513E);
const flameOn = Color(0xFFF26B1D);

String arabicDigits(int n) {
  const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class StreakData {
  final int count;
  final bool doneToday;
  const StreakData(this.count, this.doneToday);
}

class StreakService {
  static Future<StreakData> load() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getString('last_date');
    final streak = p.getInt('streak') ?? 0;
    final now = DateTime.now();
    final today = dateKey(now);
    final yesterday = dateKey(DateTime(now.year, now.month, now.day - 1));
    if (last == today) return StreakData(streak, true);
    if (last == yesterday) return StreakData(streak, false);
    return const StreakData(0, false);
  }

  static Future<int?> markReadToday() async {
    final current = await load();
    if (current.doneToday) return null;
    final p = await SharedPreferences.getInstance();
    final next = current.count + 1;
    await p.setString('last_date', dateKey(DateTime.now()));
    await p.setInt('streak', next);
    return next;
  }
}

Future<Map<int, List<String>>> loadQuran() async {
  final raw = await rootBundle.loadString('assets/quran.txt');
  final map = <int, List<String>>{};
  for (final line in raw.split('\n')) {
    final l = line.trim();
    if (l.isEmpty || l.startsWith('#')) continue;
    final i1 = l.indexOf('|');
    if (i1 < 0) continue;
    final i2 = l.indexOf('|', i1 + 1);
    if (i2 < 0) continue;
    final s = int.tryParse(l.substring(0, i1));
    if (s == null) continue;
    (map[s] ??= []).add(l.substring(i2 + 1));
  }
  return map;
}

void main() => runApp(const QuranApp());

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'القرآن الكريم',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF6F8F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F8F6),
          foregroundColor: green,
          elevation: 0,
        ),
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<int, List<String>>? quran;
  StreakData streak = const StreakData(0, false);
  String? error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final q = await loadQuran();
      final s = await StreakService.load();
      setState(() {
        quran = q;
        streak = s;
      });
    } catch (e) {
      setState(() => error = 'تعذّر تحميل نص القرآن. تأكد من وجود الملف assets/quran.txt');
    }
  }

  Future<void> _open(int n) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadPage(surah: n, ayat: quran![n] ?? const []),
      ),
    );
    final s = await StreakService.load();
    if (mounted) setState(() => streak = s);
  }

  void _about() {
    showAboutDialog(
      context: context,
      applicationName: 'القرآن الكريم',
      children: const [
        Text('نص القرآن الكريم من مشروع تنزيل (tanzil.net) بموجب رخصة Creative Commons Attribution 3.0، وهو غير معدّل.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'عن التطبيق',
            onPressed: _about,
          ),
        ],
      ),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error!, textAlign: TextAlign.center),
              ),
            )
          : quran == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    StreakBadge(streak: streak),
                    Expanded(
                      child: ListView.separated(
                        itemCount: 114,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: green.withOpacity(0.1),
                            child: Text(arabicDigits(i + 1),
                                style: const TextStyle(
                                    color: green, fontSize: 13)),
                          ),
                          title: Text('سورة ${surahNames[i]}',
                              style: const TextStyle(fontSize: 18)),
                          onTap: () => _open(i + 1),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class StreakBadge extends StatelessWidget {
  final StreakData streak;
  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final lit = streak.doneToday;
    final color = lit ? flameOn : Colors.grey;
    final message = lit
        ? 'قرأت اليوم، استمر'
        : streak.count > 0
            ? 'اقرأ اليوم لتحافظ على الاستريك'
            : 'ابدأ استريكك اليوم';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, size: 40, color: color),
          const SizedBox(width: 6),
          Text(arabicDigits(streak.count),
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 15, color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}

class ReadPage extends StatefulWidget {
  final int surah;
  final List<String> ayat;
  const ReadPage({super.key, required this.surah, required this.ayat});

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  double fontSize = 26;
  int? newStreak;

  @override
  void initState() {
    super.initState();
    _loadFont();
    _checkStreak();
  }

  Future<void> _loadFont() async {
    final p = await SharedPreferences.getInstance();
    final f = p.getDouble('font_size');
    if (f !=
