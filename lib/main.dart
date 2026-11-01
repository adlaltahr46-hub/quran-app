import 'dart:async';
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

const green = Color(0xFF14513E);
const greenLight = Color(0xFF7FD1AE);
const flameOn = Color(0xFFF26B1D);

final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color accent(BuildContext c) => isDark(c) ? greenLight : green;

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
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? const Color(0xFF0F1A16) : const Color(0xFFF6F8F6);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: b),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: dark ? greenLight : green,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'القرآن الكريم',
          debugShowCheckedModeBanner: false,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: mode,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const HomePage(),
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
    if (!mounted) return;
    setState(() {
      lastSurah = s;
      lastFrac = f;
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

  void _about() {
    showAboutDialog(
      context: context,
      applicationName: 'القرآن الكريم',
      children: const [
        Text(
            'نص القرآن الكريم من مشروع تنزيل (tanzil.net) بموجب رخصة Creative Commons Attribution 3.0، وهو غير معدّل.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final acc = accent(context);
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
              : Column(
                  children: [
                    StreakBadge(streak: streak),
                    if (last != null && last >= 1 && last <= 114)
                      ContinueCard(
                        surah: last,
                        frac: lastFrac,
                        onTap: () => _open(last),
                      ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: 114,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: acc.withOpacity(0.12),
                            child: Text(arabicDigits(i + 1),
                                style: TextStyle(color: acc, fontSize: 13)),
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A2A24) : Colors.white,
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
                style: TextStyle(
                    fontSize: 15,
                    color: dark ? Colors.white70 : Colors.black54)),
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
  final ScrollController ctrl = ScrollController();
  SharedPreferences? prefs;
  double _lastFrac = 0;

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
    if (!mounted) return;
    setState(() {
      if (f != null) fontSize = f;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || frac <= 0 || !ctrl.hasClients) return;
      ctrl.jumpTo(frac * ctrl.position.maxScrollExtent);
    });
  }

  void _onScroll() {
    if (!ctrl.hasClients) return;
    final max = ctrl.position.maxScrollExtent;
    if (max <= 0) return;
    final frac = (ctrl.offset / max).clamp(0.0, 1.0).toDouble();
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
    final next = (fontSize + delta).clamp(18.0, 44.0).toDouble();
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
            child: Text.rich(
              TextSpan(
                children: [
                  for (var i = 0; i < ayat.length; i++) ...[
                    TextSpan(text: ayat[i]),
                    TextSpan(
                      text: ' \uFD3F${arabicDigits(i + 1)}\uFD3E ',
                      style: TextStyle(color: acc, fontSize: fontSize * 0.75),
                    ),
                  ],
                ],
              ),
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: fontSize, height: 2.0, color: textColor),
            ),
          ),
          if (newStreak != null)
            Positioned.fill(
              child: FlameOverlay(
                count: newStreak!,
                onDone: () => setState(() => newStreak = null),
              ),
            ),
        ],
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
