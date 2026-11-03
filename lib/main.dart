import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'pattern.dart';

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

const flameOn = Color(0xFFF26B1D);
const quranFont = 'AmiriQuran';
const kTotalAyat = 6236;

class Rank {
  final String name;
  final double min;
  final Color color;
  final int stars;
  const Rank(this.name, this.min, this.color, this.stars);
}

const ranks = [
  Rank('مبتدئ', 0.0, Color(0xFF14513E), 1),
  Rank('مواظب', 0.05, Color(0xFF0E7C66), 2),
  Rank('قارئ', 0.15, Color(0xFF1B6FA8), 3),
  Rank('ثابت', 0.30, Color(0xFF4B54C4), 4),
  Rank('مُجِدّ', 0.50, Color(0xFF8E44AD), 5),
  Rank('مُتقِن', 0.75, Color(0xFFC2571A), 6),
  Rank('نجم القراءة', 1.0, Color(0xFFB03A5B), 7),
  Rank('همّة عالية', 2.0, Color(0xFFB8860B), 8),
];

int rankIndexFor(double score) {
  var r = 0;
  for (var i = 0; i < ranks.length; i++) {
    if (score >= ranks[i].min) r = i;
  }
  return r;
}

final ValueNotifier<int> rankIndex = ValueNotifier(0);
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color accent(BuildContext c) {
  final base = ranks[rankIndex.value].color;
  return isDark(c) ? Color.lerp(base, Colors.white, 0.4)! : base;
}

Color cardColor(BuildContext c) =>
    isDark(c) ? const Color(0xFF16231E) : Colors.white;
Color mutedColor(BuildContext c) =>
    isDark(c) ? Colors.white60 : Colors.black54;

Future<void> toggleTheme() async {
  final dark = themeMode.value != ThemeMode.dark;
  themeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
  final p = await SharedPreferences.getInstance();
  await p.setBool('dark', dark);
}

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final p = await SharedPreferences.getInstance();
  themeMode.value =
      (p.getBool('dark') ?? false) ? ThemeMode.dark : ThemeMode.light;
  rankIndex.value = rankIndexFor(p.getDouble('score') ?? 0.0);
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final base = ranks[rankIndex.value].color;
    final bg = dark ? const Color(0xFF0F1A16) : const Color(0xFFF6F8F6);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: base, brightness: b),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: dark ? Color.lerp(base, Colors.white, 0.4) : base,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: rankIndex,
      builder: (context, _, __) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (context, mode, _) {
            return MaterialApp(
              title: 'القرآن الكريم',
              debugShowCheckedModeBanner: false,
              theme: _theme(Brightness.light),
              darkTheme: _theme(Brightness.dark),
              themeMode: mode,
              builder: (context, child) => Directionality(
                  textDirection: TextDirection.rtl, child: child!),
              home: const HomePage(),
            );
          },
        );
      },
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
  int? lastSurah;
  double lastFrac = 0;
  Map<int, double> progress = {};
  double khatma = 0;
  double score = 0;
  int doneCount = 0;
  int khatmaCount = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _loadLast() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getInt('last_surah');
    final f = p.getDouble('last_frac') ?? 0.0;
    final prog = <int, double>{};
    double readAyat = 0;
    int totalAyat = 0;
    int done = 0;
    final q = quran;
    for (var i = 1; i <= 114; i++) {
      final v = p.getDouble('max_$i') ?? 0.0;
      prog[i] = v;
      final n = q?[i]?.length ?? 0;
      totalAyat += n;
      readAyat += v * n;
      if (v >= 0.97) done++;
    }
    final k = totalAyat == 0 ? 0.0 : readAyat / totalAyat;
    final sc = p.getDouble('score') ?? k;
    await p.setDouble('score', sc);
    if (!mounted) return;
    rankIndex.value = rankIndexFor(sc);
    setState(() {
      lastSurah = s;
      lastFrac = f;
      progress = prog;
      khatma = k;
      score = sc;
      doneCount = done;
      khatmaCount = p.getInt('khatma_count') ?? 0;
    });
  }

  Future<void> _init() async {
    try {
      final q = await loadQuran();
      final s = await StreakService.load();
      if (!mounted) return;
      setState(() {
        quran = q;
        streak = s;
      });
      await _loadLast();
    } catch (e) {
      if (!mounted) return;
      setState(() => error =
          'تعذّر تحميل نص القرآن. تأكد من وجود الملف assets/quran.txt');
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
    await _loadLast();
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بدء ختمة جديدة؟'),
        content: const Text(
            'سيُمسح تقدّمك في الختمة وعلامات السور المكتملة ومكان التوقف. لن يتأثر الاستريك ولا رتبتك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ابدأ من جديد'),
          ),
        ],
      ),
    );
    if (ok == true) await _resetKhatma();
  }

  Future<void> _resetKhatma() async {
    final p = await SharedPreferences.getInstance();
    if (khatma >= 0.97) {
      await p.setInt('khatma_count', (p.getInt('khatma_count') ?? 0) + 1);
    }
    for (var i = 1; i <= 114; i++) {
      await p.remove('max_$i');
    }
    await p.remove('last_surah');
    await p.remove('last_frac');
    await _loadLast();
  }

  Future<void> _confirmResetRank() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('البدء من الصفر؟'),
        content: const Text(
            'سترجع إلى رتبة «مبتدئ»، ويُمسح تقدّمك في الختمة وعدد ختماتك ومكان التوقف. لن يتأثر الاستريك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ابدأ من الصفر'),
          ),
        ],
      ),
    );
    if (ok == true) await _resetAll();
  }

  Future<void> _resetAll() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('score', 0.0);
    for (var i = 1; i <= 114; i++) {
      await p.remove('max_$i');
    }
    await p.remove('last_surah');
    await p.remove('last_frac');
    await p.remove('khatma_count');
    await _loadLast();
  }

  void _about() {
    showAboutDialog(
      context: context,
      applicationName: 'القرآن الكريم',
      children: const [
        Text(
            'نص القرآن الكريم من مشروع تنزيل (tanzil.net) بموجب رخصة Creative Commons Attribution 3.0، وهو غير معدّل.'),
        SizedBox(height: 8),
        Text('الخط: Amiri Quran بموجب رخصة SIL Open Font License.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final last = lastSurah;
    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'الوضع الليلي',
            onPressed: toggleTheme,
          ),
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
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: 115,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Column(
                        children: [
                          RankCard(
                            score: score,
                            onReset: _confirmResetRank,
                          ),
                          StreakBadge(streak: streak),
                          KhatmaCard(
                            value: khatma,
                            done: doneCount,
                            khatmaCount: khatmaCount,
                            onReset: _confirmReset,
                          ),
                          if (last != null && last >= 1 && last <= 114)
                            ContinueCard(
                              surah: last,
                              frac: lastFrac,
                              onTap: () => _open(last),
                            ),
                        ],
                      );
                    }
                    return SurahTile(
                      number: i,
                      ayahCount: quran![i]?.length ?? 0,
                      progress: progress[i] ?? 0.0,
                      onTap: () => _open(i),
                    );
                  },
                ),
    );
  }
}

class RankCard extends StatelessWidget {
  final double score;
  final VoidCallback onReset;
  const RankCard({super.key, required this.score, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final acc = accent(context);
    final idx = rankIndexFor(score);
    final rank = ranks[idx];
    final nextRank = idx + 1 < ranks.length ? ranks[idx + 1] : null;
    final progress = nextRank == null
        ? 1.0
        : ((score - rank.min) / (nextRank.min - rank.min))
            .clamp(0.0, 1.0)
            .toDouble();
    final remainPct =
        nextRank == null ? 0 : ((nextRank.min - score) * 100).ceil();
    final note = nextRank == null
        ? 'وصلت إلى أعلى رتبة، بارك الله فيك'
        : 'باقٍ ${arabicDigits(remainPct < 1 ? 1 : remainPct)}٪ من القرآن للوصول إلى «${nextRank.name}»';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: acc.withOpacity(0.5), width: 1.4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color.lerp(rank.color, Colors.white, 0.3)!,
                      rank.color,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rank.color.withOpacity(0.4),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('رتبتك',
                        style: TextStyle(
                            fontSize: 12, color: mutedColor(context))),
                    Text(rank.name,
                        style: TextStyle(
                            fontFamily: quranFont, fontSize: 24, color: acc)),
                    Row(
                      children: [
                        for (var i = 0; i < ranks.length; i++)
                          Icon(
                            i < rank.stars ? Icons.star : Icons.star_border,
                            size: 14,
                            color: acc,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('${arabicDigits((score * 100).floor())}٪',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: acc)),
                  Text('مما قرأته',
                      style: TextStyle(
                          fontSize: 12, color: mutedColor(context))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: acc.withOpacity(0.15),
              color: acc,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(note,
                style: TextStyle(fontSize: 13, color: mutedColor(context))),
          ),
          if (score > 0)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt, size: 20),
                label: const Text('ابدأ الرتب من جديد'),
                style: TextButton.styleFrom(foregroundColor: acc),
              ),
            ),
        ],
      ),
    );
  }
}

class NumberBadge extends StatelessWidget {
  final int number;
  final bool done;
  const NumberBadge({super.key, required this.number, required this.done});

  @override
  Widget build(BuildContext context) {
    final acc = accent(context);
    final onAcc = isDark(context) ? const Color(0xFF0F1A16) : Colors.white;
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final a in [0.0, math.pi / 4])
            Transform.rotate(
              angle: a,
              child: Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: done ? acc : acc.withOpacity(0.10),
                  border: Border.all(color: acc, width: 1.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          done
              ? Icon(Icons.check, size: 18, color: onAcc)
              : Text(
                  arabicDigits(number),
                  style: TextStyle(
                      fontSize: 12,
                      color: acc,
                      fontWeight: FontWeight.w600),
                ),
        ],
      ),
    );
  }
}

class SurahTile extends StatelessWidget {
  final int number;
  final int ayahCount;
  final double progress;
  final VoidCallback onTap;
  const SurahTile({
    super.key,
    required this.number,
    required this.ayahCount,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final acc = accent(context);
    final done = progress >= 0.97;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                NumberBadge(number: number, done: done),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سورة ${surahNames[number - 1]}',
                        style: const TextStyle(
                            fontSize: 20, fontFamily: quranFont),
                      ),
                      Text(
                        '${arabicDigits(ayahCount)} آية',
                        style: TextStyle(
                            fontSize: 13, color: mutedColor(context)),
                      ),
                    ],
                  ),
                ),
                if (done)
                  Icon(Icons.check_circle, color: acc)
                else if (progress > 0)
                  Text(
                    '${arabicDigits((progress * 100).round())}٪',
                    style: TextStyle(color: acc, fontSize: 14),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KhatmaCard extends StatelessWidget {
  final double value;
  final int done;
  final int khatmaCount;
  final VoidCallback onReset;
  const KhatmaCard({
    super.key,
    required this.value,
    required this.done,
    required this.khatmaCount,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final acc = accent(context);
    final dark = isDark(context);
    final summary = khatmaCount > 0
        ? '${arabicDigits(done)} من ١١٤ سورة مكتملة  •  ختمات مكتملة: ${arabicDigits(khatmaCount)}'
        : '${arabicDigits(done)} من ١١٤ سورة مكتملة';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories, color: acc),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('تقدّمك في الختمة',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              Text(
                '${arabicDigits((value * 100).round())}٪',
                style: TextStyle(
                    color: acc, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: acc.withOpacity(0.15),
              color: acc,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: TextStyle(fontSize: 13, color: mutedColor(context)),
          ),
          if (value > 0)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt, size: 20),
                label: const Text('ابدأ ختمة جديدة'),
                style: TextButton.styleFrom(foregroundColor: acc),
              ),
            ),
        ],
      ),
    );
  }
}

class ContinueCard extends StatelessWidget {
  final int surah;
  final double frac;
  final VoidCallback onTap;
  const ContinueCard({
    super.key,
    required this.surah,
    required this.frac,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final acc = accent(context);
    final percent = (frac * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: acc.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.bookmark, color: acc),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تابع القراءة: سورة ${surahNames[surah - 1]}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Text(
                  '${arabicDigits(percent)}٪',
                  style: TextStyle(color: acc, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StreakBadge extends StatelessWidget {
  final StreakData streak;
  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final lit = streak.doneToday;
    final color = lit ? flameOn : Colors.grey;
    final message = lit
        ? 'قرأت اليوم، استمر'
        : streak.count > 0
            ? 'اقرأ اليوم لتحافظ على الاستريك'
            : 'ابدأ استريكك اليوم';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? Colors.white12 : Colors.black12),
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
                style: TextStyle(fontSize: 15, color: mutedColor(context))),
          ),
        ],
      ),
    );
  }
}

class SurahHeader extends StatelessWidget {
  final int surah;
  final int count;
  const SurahHeader({super.key, required this.surah, required this.count});

  @override
  Widget build(BuildContext context) {
    final acc = accent(context);
    final rank = ranks[rankIndex.value];
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 14),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: acc.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: acc.withOpacity(0.6), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'سورة ${surahNames[surah - 1]}',
            style: TextStyle(fontFamily: quranFont, fontSize: 30, color: acc),
          ),
          const SizedBox(height: 2),
          Text(
            '${arabicDigits(count)} آية',
            style: TextStyle(fontSize: 13, color: mutedColor(context)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < rank.stars; i++)
                Icon(Icons.star, size: 12, color: acc),
            ],
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
  double fontSize = 28;
  int? newStreak;
  Rank? rankUp;
  final ScrollController ctrl = ScrollController();
  SharedPreferences? prefs;
  double _lastFrac = 0;
  double _maxFrac = 0;
  double _score = 0;

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_onScroll);
    _init();
    _checkStreak();
  }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    prefs = p;
    final f = p.getDouble('font_size');
    final sameSurah = p.getInt('last_surah') == widget.surah;
    final frac = sameSurah ? (p.getDouble('last_frac') ?? 0.0) : 0.0;
    if (!sameSurah) {
      await p.setInt('last_surah', widget.surah);
      await p.setDouble('last_frac', 0.0);
    }
    _lastFrac = frac;
    _maxFrac = p.getDouble('max_${widget.surah}') ?? 0.0;
    _score = p.getDouble('score') ?? 0.0;
    if (!mounted) return;
    setState(() {
      if (f != null) fontSize = f;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ctrl.hasClients) return;
      final max = ctrl.position.maxScrollExtent;
      if (max <= 0) {
        _recordMax(1.0);
        return;
      }
      if (frac > 0) ctrl.jumpTo(frac * max);
    });
  }

  void _recordMax(double v) {
    if (v <= _maxFrac) return;
    final delta = (v - _maxFrac) * widget.ayat.length / kTotalAyat;
    _maxFrac = v;
    prefs?.setDouble('max_${widget.surah}', v);
    _addScore(delta);
  }

  void _addScore(double delta) {
    final p = prefs;
    if (p == null) return;
    final before = _score;
    _score += delta;
    p.setDouble('score', _score);
    final rb = rankIndexFor(before);
    final ra = rankIndexFor(_score);
    if (ra > rb) {
      rankIndex.value = ra;
      if (mounted) setState(() => rankUp = ranks[ra]);
    }
  }

  void _onScroll() {
    if (!ctrl.hasClients) return;
    final max = ctrl.position.maxScrollExtent;
    if (max <= 0) return;
    final frac = (ctrl.offset / max).clamp(0.0, 1.0).toDouble();
    _recordMax(frac);
    if ((frac - _lastFrac).abs() < 0.004) return;
    _lastFrac = frac;
    prefs?.setDouble('last_frac', frac);
  }

  @override
  void dispose() {
    prefs?.setDouble('last_frac', _lastFrac);
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _changeFont(double delta) async {
    final next = (fontSize + delta).clamp(18.0, 48.0).toDouble();
    setState(() => fontSize = next);
    final p = await SharedPreferences.getInstance();
    await p.setDouble('font_size', next);
  }

  Future<void> _checkStreak() async {
    final n = await StreakService.markReadToday();
    if (n != null && mounted) setState(() => newStreak = n);
  }

  @override
  Widget build(BuildContext context) {
    final ayat = widget.ayat;
    final dark = isDark(context);
    final acc = accent(context);
    final textColor =
        dark ? const Color(0xFFEDE8D5) : const Color(0xFF1B1B1B);
    final up = rankUp;
    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${surahNames[widget.surah - 1]}'),
        actions: [
          IconButton(
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'الوضع الليلي',
            onPressed: toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'تصغير الخط',
            onPressed: () => _changeFont(-2),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'تكبير الخط',
            onPressed: () => _changeFont(2),
          ),
        ],
      ),
      body: Stack(
        children: [
          PatternScroll(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SurahHeader(surah: widget.surah, count: ayat.length),
                Text.rich(
                  TextSpan(
                    children: [
                      for (var i = 0; i < ayat.length; i++) ...[
                        TextSpan(text: ayat[i]),
                        TextSpan(
                          text: ' \uFD3F${arabicDigits(i + 1)}\uFD3E ',
                          style: TextStyle(
                              color: acc, fontSize: fontSize * 0.75),
                        ),
                      ],
                    ],
                  ),
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontFamily: quranFont,
                    fontSize: fontSize,
                    height: 2.2,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          if (newStreak != null)
            Positioned.fill(
              child: FlameOverlay(
                count: newStreak!,
                onDone: () => setState(() => newStreak = null),
              ),
            ),
          if (up != null)
            Positioned.fill(
              child: RankUpOverlay(
                rank: up,
                onDone: () => setState(() => rankUp = null),
              ),
            ),
        ],
      ),
    );
  }
}

class RankUpOverlay extends StatefulWidget {
  final Rank rank;
  final VoidCallback onDone;
  const RankUpOverlay({super.key, required this.rank, required this.onDone});

  @override
  State<RankUpOverlay> createState() => _RankUpOverlayState();
}

class _RankUpOverlayState extends State<RankUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  late final Animation<double> scale =
      CurvedAnimation(parent: c, curve: Curves.elasticOut);
  Timer? timer;

  @override
  void initState() {
    super.initState();
    c.forward();
    timer = Timer(const Duration(milliseconds: 3800), widget.onDone);
  }

  @override
  void dispose() {
    timer?.cancel();
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rank = widget.rank;
    return GestureDetector(
      onTap: widget.onDone,
      child: Container(
        color: Colors.black.withOpacity(0.72),
        child: Center(
          child: ScaleTransition(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color.lerp(rank.color, Colors.white, 0.3)!,
                        rank.color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rank.color.withOpacity(0.6),
                        blurRadius: 50,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: Colors.white, size: 76),
                ),
                const SizedBox(height: 18),
                const Text(
                  'ترقية!',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.amber,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rank.name,
                  style: const TextStyle(
                    fontFamily: quranFont,
                    fontSize: 38,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < rank.stars; i++)
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FlameOverlay extends StatefulWidget {
  final int count;
  final VoidCallback onDone;
  const FlameOverlay({super.key, required this.count, required this.onDone});

  @override
  State<FlameOverlay> createState() => _FlameOverlayState();
}

class _FlameOverlayState extends State<FlameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final Animation<double> scale = Tween<double>(begin: 0.2, end: 1.0)
      .animate(CurvedAnimation(
          parent: c,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
  late final Animation<double> glow = CurvedAnimation(
      parent: c, curve: const Interval(0.4, 1.0, curve: Curves.easeIn));
  Timer? timer;

  @override
  void initState() {
    super.initState();
    c.forward();
    timer = Timer(const Duration(milliseconds: 3200), widget.onDone);
  }

  @override
  void dispose() {
    timer?.cancel();
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDone,
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: AnimatedBuilder(
            animation: c,
            builder: (_, __) {
              final g = glow.value.clamp(0.0, 1.0).toDouble();
              final color = Color.lerp(Colors.grey, flameOn, g)!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: scale.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: flameOn.withOpacity(0.55 * g),
                            blurRadius: 70 * g,
                            spreadRadius: 8 * g,
                          ),
                        ],
                      ),
                      child: Icon(Icons.local_fire_department,
                          size: 150, color: color),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Opacity(
                    opacity: g,
                    child: Text(
                      arabicDigits(widget.count),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: g,
                    child: const Text(
                      'يوماً متتالياً',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
