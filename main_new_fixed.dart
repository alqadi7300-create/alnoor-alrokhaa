import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QadiApp());
}

const teacherPassword = 'alwsabi730034735';

const grades = <String>[
  'الأول الثانوي',
  'الثاني الثانوي',
  'الثالث الثانوي',
];

const subjects = <String>[
  'الكيمياء',
  'الفيزياء',
  'الأحياء',
];

const questionTypes = <String>[
  'اختيار من متعدد',
  'صح أو خطأ',
  'إجابة قصيرة',
];

class QadiApp extends StatelessWidget {
  const QadiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'برنامج محمد القاضي التعليمي العلمي',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomePage(),
    );
  }
}

Widget rtl(Widget child) =>
    Directionality(textDirection: TextDirection.rtl, child: child);

class AppStorage {
  static Future<SharedPreferences> get prefs =>
      SharedPreferences.getInstance();

  static Future<List<Map<String, dynamic>>> _get(String key) async {
    final p = await prefs;
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> _save(
      String key, List<Map<String, dynamic>> value) async {
    final p = await prefs;
    await p.setString(key, jsonEncode(value));
  }

  static Future<List<Map<String, dynamic>>> getStudents() => _get('students');
  static Future<void> saveStudents(List<Map<String, dynamic>> v) => _save('students', v);
  static Future<List<Map<String, dynamic>>> getBooks() => _get('books');
  static Future<void> saveBooks(List<Map<String, dynamic>> v) => _save('books', v);
  static Future<List<Map<String, dynamic>>> getExams() => _get('exams');
  static Future<void> saveExams(List<Map<String, dynamic>> v) => _save('exams', v);
  static Future<List<Map<String, dynamic>>> getResults() => _get('results');
  static Future<void> saveResults(List<Map<String, dynamic>> v) => _save('results', v);

  static Future<void> saveStudentSession(Map<String, dynamic> student) async {
    final p = await prefs;
    await p.setString('student_session', jsonEncode(student));
    await p.remove('teacher_session');
  }

  static Future<Map<String, dynamic>?> getStudentSession() async {
    final p = await prefs;
    final raw = p.getString('student_session');
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveTeacherSession() async {
    final p = await prefs;
    await p.setBool('teacher_session', true);
    await p.remove('student_session');
  }

  static Future<bool> getTeacherSession() async {
    final p = await prefs;
    return p.getBool('teacher_session') ?? false;
  }

  static Future<void> clearSession() async {
    final p = await prefs;
    await p.remove('student_session');
    await p.remove('teacher_session');
  }
}

// ================= الرئيسية =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool checking = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final teacher = await AppStorage.getTeacherSession();
    if (teacher) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TeacherHomePage()));
      return;
    }
    final student = await AppStorage.getStudentSession();
    if (student != null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentHomePage(student: student)));
      return;
    }
    if (mounted) setState(() => checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return rtl(
        Scaffold(
          appBar: AppBar(
            title: const Text('برنامج محمد القاضي التعليمي العلمي'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 18),
              const Icon(Icons.school, size: 90),
              const SizedBox(height: 18),
              const Text(
                'برنامج محمد القاضي التعليمي العلمي',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'ادعم التعليم فالتعليم للجميع',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 28),
              _go(context, 'دخول الطالب', Icons.person, const StudentLoginPage()),
              _gap(),
              _go(context, 'دخول المعلم', Icons.admin_panel_settings,
                  const TeacherLoginPage()),
              _gap(),
              _go(context, 'عن الأستاذ محمد القاضي', Icons.info_outline,
                  const TeacherBioPage()),
            ],
          ),
        ),
      );
  }

  Widget _go(BuildContext c, String t, IconData i, Widget p) => SizedBox(
        height: 58,
        child: FilledButton.icon(
          onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => p)),
          icon: Icon(i),
          label: Text(t, style: const TextStyle(fontSize: 18)),
        ),
      );

  Widget _gap() => const SizedBox(height: 12);
}

// ================= دخول الطالب =================

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});

  @override
  State<StudentLoginPage> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final controller = TextEditingController();
  String error = '';
  bool loading = false;

  Future<void> login() async {
    final code = controller.text.trim();
    if (code.isEmpty) {
      setState(() => error = 'أدخل كود الطالب');
      return;
    }
    setState(() {
      loading = true;
      error = '';
    });
    final students = await AppStorage.getStudents();
    Map<String, dynamic>? student;
    for (final s in students) {
      if (s['code']?.toString() == code) {
        student = s;
        break;
      }
    }
    if (!mounted) return;
    setState(() => loading = false);
    if (student == null) {
      setState(() => error = 'كود الطالب غير صحيح');
      return;
    }
    await AppStorage.saveStudentSession(student!);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => StudentHomePage(student: student!)),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('دخول الطالب'), centerTitle: true),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 35),
                const Icon(Icons.person, size: 90),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'كود الطالب',
                    hintText: 'أدخل الكود الخاص بك',
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 12),
                if (error.isNotEmpty)
                  Text(error,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('دخول'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ================= بوابة الطالب =================

class StudentHomePage extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentHomePage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final name = student['name']?.toString() ?? 'الطالب';
    final grade = student['grade']?.toString() ?? grades.first;
    return rtl(
      Scaffold(
        appBar: AppBar(title: const Text('بوابة الطالب'), centerTitle: true, actions: [IconButton(tooltip: 'تسجيل الخروج', icon: const Icon(Icons.logout), onPressed: () async { await AppStorage.clearSession(); if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (_) => false); })]),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      child: Icon(Icons.person, size: 44),
                    ),
                    const SizedBox(height: 10),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold)),
                    Text('الصف: $grade'),
                    Text('الكود: ${student['code'] ?? ''}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _go(context, 'الكتب والمذكرات', Icons.menu_book,
                SubjectPage(grade: grade)),
            _gap(),
            _go(context, 'الاختبارات', Icons.assignment,
                ExamPage(grade: grade, student: student)),
            _gap(),
            _go(context, 'درجاتي السابقة', Icons.bar_chart,
                ResultsPage(student: student)),
          ],
        ),
      ),
    );
  }

  Widget _go(BuildContext c, String t, IconData i, Widget p) => SizedBox(
        height: 56,
        child: FilledButton.icon(
          onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => p)),
          icon: Icon(i),
          label: Text(t),
        ),
      );

  Widget _gap() => const SizedBox(height: 10);
}

// ================= المواد والكتب =================

class SubjectPage extends StatelessWidget {
  final String grade;

  const SubjectPage({super.key, required this.grade});

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: Text('مواد $grade'), centerTitle: true),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text('اختر المادة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              for (final subject in subjects) ...[
                SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PdfBookPage(grade: grade, subject: subject),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book),
                    label: Text(subject),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      );
}

class PdfBookPage extends StatefulWidget {
  final String grade;
  final String subject;

  const PdfBookPage({
    super.key,
    required this.grade,
    required this.subject,
  });

  @override
  State<PdfBookPage> createState() => _PdfBookPageState();
}

class _PdfBookPageState extends State<PdfBookPage> {
  List<Map<String, dynamic>> books = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    final all = await AppStorage.getBooks();
    final filtered = all
        .where((b) =>
            b['grade']?.toString() == widget.grade &&
            b['subject']?.toString() == widget.subject)
        .toList();
    if (!mounted) return;
    setState(() {
      books = filtered;
      loading = false;
    });
  }

  Future<void> openPdf(Map<String, dynamic> book) async {
    final path = book['path']?.toString();
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ملف PDF غير موجود')));
      }
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          title: book['title']?.toString() ?? 'ملف PDF',
          bytes: bytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: Text(widget.subject), centerTitle: true),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : books.isEmpty
                  ? const Center(
                      child: Text('لا توجد كتب أو مذكرات مضافة حاليًا'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: books.length,
                      itemBuilder: (_, i) {
                        final b = books[i];
                        return Card(
                          child: ListTile(
                            leading:
                                const Icon(Icons.picture_as_pdf, size: 36),
                            title: Text(b['title']?.toString() ?? 'PDF'),
                            subtitle: Text(
                                '${b['grade'] ?? ''} - ${b['subject'] ?? ''}'),
                            trailing: const Icon(Icons.arrow_back_ios),
                            onTap: () => openPdf(b),
                          ),
                        );
                      },
                    ),
        ),
      );
}

class PdfViewerPage extends StatelessWidget {
  final String title;
  final Uint8List bytes;

  const PdfViewerPage({
    super.key,
    required this.title,
    required this.bytes,
  });

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: Text(title), centerTitle: true),
          body: PdfPreview(
            build: (_) async => bytes,
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: title.endsWith('.pdf') ? title : '$title.pdf',
          ),
        ),
      );
}

// ================= اختبارات الطالب =================

class ExamPage extends StatefulWidget {
  final String grade;
  final Map<String, dynamic> student;

  const ExamPage({super.key, required this.grade, required this.student});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  List<Map<String, dynamic>> exams = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadExams();
  }

  Future<void> loadExams() async {
    final all = await AppStorage.getExams();
    final filtered =
        all.where((e) => e['grade']?.toString() == widget.grade).toList();
    if (!mounted) return;
    setState(() {
      exams = filtered;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('الاختبارات'), centerTitle: true),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : exams.isEmpty
                  ? const Center(child: Text('لا توجد اختبارات متاحة حاليًا'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: exams.length,
                      itemBuilder: (_, i) {
                        final e = exams[i];
                        final questions =
                            List<Map<String, dynamic>>.from(e['questions'] ?? []);
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.assignment, size: 35),
                            title: Text(e['title']?.toString() ?? 'اختبار'),
                            subtitle: Text(
                                '${e['subject'] ?? ''} - ${questions.length} أسئلة'),
                            trailing: const Icon(Icons.arrow_back_ios),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TakeExamPage(exam: e, student: widget.student),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      );
}

// ================= حل الاختبار =================

class TakeExamPage extends StatefulWidget {
  final Map<String, dynamic> exam;
  final Map<String, dynamic> student;

  const TakeExamPage({super.key, required this.exam, required this.student});

  @override
  State<TakeExamPage> createState() => _TakeExamPageState();
}

class _TakeExamPageState extends State<TakeExamPage> {
  final Map<int, dynamic> answers = {};
  bool saving = false;

  Future<void> submitExam() async {
    if (saving) return;
    final questions =
        List<Map<String, dynamic>>.from(widget.exam['questions'] ?? []);
    int score = 0;

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final type = q['type']?.toString() ?? questionTypes.first;
      if (type == 'صح أو خطأ') {
        if (answers[i]?.toString() == q['correctText']?.toString()) score++;
      } else if (type == 'إجابة قصيرة') {
        final a = answers[i]?.toString().trim().toLowerCase() ?? '';
        final c = q['correctText']?.toString().trim().toLowerCase() ?? '';
        if (a.isNotEmpty && a == c) score++;
      } else {
        if (answers[i] == q['correct']) score++;
      }
    }

    setState(() => saving = true);
    final results = await AppStorage.getResults();
    results.add({
      'id': const Uuid().v4(),
      'studentCode': widget.student['code']?.toString() ?? '',
      'studentName': widget.student['name']?.toString() ?? '',
      'grade': widget.exam['grade']?.toString() ?? '',
      'examTitle': widget.exam['title']?.toString() ?? '',
      'subject': widget.exam['subject']?.toString() ?? '',
      'score': score,
      'total': questions.length,
      'date': DateTime.now().toIso8601String(),
    });
    await AppStorage.saveResults(results);
    if (!mounted) return;
    setState(() => saving = false);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تم إنهاء الاختبار'),
        content: Text('درجتك: $score من ${questions.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Widget questionWidget(Map<String, dynamic> q, int index) {
    final type = q['type']?.toString() ?? questionTypes.first;
    final text = q['question']?.toString() ?? '';

    if (type == 'صح أو خطأ') {
      return Card(
        child: Column(
          children: [
            ListTile(
              title: Text('${index + 1}. $text',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            RadioListTile<String>(
              value: 'صح',
              groupValue: answers[index]?.toString(),
              title: const Text('صح'),
              onChanged: (v) => setState(() => answers[index] = v),
            ),
            RadioListTile<String>(
              value: 'خطأ',
              groupValue: answers[index]?.toString(),
              title: const Text('خطأ'),
              onChanged: (v) => setState(() => answers[index] = v),
            ),
          ],
        ),
      );
    }

    if (type == 'إجابة قصيرة') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${index + 1}. $text',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                onChanged: (v) => answers[index] = v,
                decoration: const InputDecoration(labelText: 'اكتب إجابتك'),
              ),
            ],
          ),
        ),
      );
    }

    final options = List<String>.from(q['options'] ?? []);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}. $text',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            ...List.generate(
              options.length,
              (j) => RadioListTile<int>(
                value: j,
                groupValue: answers[index] as int?,
                title: Text(options[j]),
                onChanged: (v) => setState(() => answers[index] = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions =
        List<Map<String, dynamic>>.from(widget.exam['questions'] ?? []);
    return rtl(
      Scaffold(
        appBar: AppBar(
          title: Text(widget.exam['title']?.toString() ?? 'الاختبار'),
          centerTitle: true,
        ),
        body: questions.isEmpty
            ? const Center(child: Text('لا توجد أسئلة في هذا الاختبار'))
            : ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Card(
                    child: ListTile(
                      title: Text(widget.exam['subject']?.toString() ?? ''),
                      subtitle: Text('عدد الأسئلة: ${questions.length}'),
                    ),
                  ),
                  ...List.generate(
                    questions.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: questionWidget(questions[i], i),
                    ),
                  ),
                  SizedBox(
                    height: 55,
                    child: FilledButton.icon(
                      onPressed: saving ? null : submitExam,
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                          saving ? 'جارٍ الحفظ...' : 'إنهاء الاختبار وتسليم الإجابات'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ================= النتائج =================

class ResultsPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const ResultsPage({super.key, required this.student});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<Map<String, dynamic>> results = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final all = await AppStorage.getResults();
    final filtered = all
        .where((r) =>
            r['studentCode']?.toString() ==
            widget.student['code']?.toString())
        .toList()
        .reversed
        .toList();
    if (!mounted) return;
    setState(() {
      results = filtered;
      loading = false;
    });
  }

  Future<void> _shareResult(Map<String, dynamic> r) async {
    final score = r['score']?.toString() ?? '0';
    final total = r['total']?.toString() ?? '0';
    final percent = (double.tryParse(total) ?? 0) == 0
        ? 0
        : ((double.tryParse(score) ?? 0) / (double.tryParse(total) ?? 1)) * 100;
    final date = r['date']?.toString() ?? '';
    final html = '''
<html><head><meta charset="utf-8"></head><body dir="rtl" style="font-family:Arial;">
<h2>برنامج محمد القاضي التعليمي العلمي</h2>
<h3>تقرير نتيجة الطالب</h3>
<p><b>اسم الطالب:</b> ${_escapePdf(widget.student['name']?.toString() ?? '')}</p>
<p><b>الصف:</b> ${_escapePdf(r['grade']?.toString() ?? '')}</p>
<p><b>المادة:</b> ${_escapePdf(r['subject']?.toString() ?? '')}</p>
<p><b>الاختبار:</b> ${_escapePdf(r['examTitle']?.toString() ?? '')}</p>
<p><b>الدرجة:</b> $score من $total</p>
<p><b>النسبة:</b> ${percent.toStringAsFixed(1)}%</p>
<p><b>التاريخ:</b> ${_escapePdf(date)}</p>
<hr><p>تم إنشاء التقرير من التطبيق.</p>
</body></html>''';
    try {
      final bytes = await Printing.convertHtml(html: html);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'نتيجة_${widget.student['name'] ?? 'الطالب'}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء أو مشاركة PDF: $e')),
        );
      }
    }
  }

  String _escapePdf(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('\"', '&quot;');

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('درجاتي السابقة'), centerTitle: true),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : results.isEmpty
                  ? const Center(child: Text('لا توجد نتائج محفوظة حتى الآن'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final r = results[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.bar_chart),
                            title: Text(r['examTitle']?.toString() ?? 'اختبار'),
                            subtitle: Text(
                              '${r['subject'] ?? ''}\nالدرجة: ${r['score']} من ${r['total']}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'إرسال النتيجة PDF',
                              icon: const Icon(Icons.picture_as_pdf),
                              onPressed: () => _shareResult(r),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      );
}

// ================= دخول المعلم =================

class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  State<TeacherLoginPage> createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends State<TeacherLoginPage> {
  final controller = TextEditingController();
  String error = '';

  Future<void> login() async {
    if (controller.text.trim() != teacherPassword) {
      setState(() => error = 'رمز المعلم غير صحيح');
      return;
    }
    await AppStorage.saveTeacherSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TeacherHomePage()),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('دخول المعلم'), centerTitle: true),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 35),
                const Icon(Icons.admin_panel_settings, size: 90),
                const SizedBox(height: 22),
                TextField(
                  controller: controller,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: 'رمز المعلم'),
                ),
                const SizedBox(height: 12),
                if (error.isNotEmpty)
                  Text(error, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(onPressed: login, child: const Text('دخول')),
                ),
              ],
            ),
          ),
        ),
      );
}

// ================= لوحة المعلم =================

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('لوحة المعلم'), centerTitle: true, actions: [IconButton(tooltip: 'تسجيل الخروج', icon: const Icon(Icons.logout), onPressed: () async { await AppStorage.clearSession(); if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (_) => false); })]),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Icon(Icons.school, size: 58),
                      SizedBox(height: 8),
                      Text('إدارة الطلاب والكتب والاختبارات والنتائج'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _go(context, 'إدارة الطلاب', Icons.people, const StudentsAdminPage()),
              _gap(),
              _go(context, 'إدارة الكتب والمذكرات', Icons.picture_as_pdf,
                  const BooksAdminPage()),
              _gap(),
              _go(context, 'إدارة الاختبارات', Icons.assignment,
                  const ExamsAdminPage()),
              _gap(),
              _go(context, 'نتائج الطلاب', Icons.bar_chart, const AllResultsPage()),
            ],
          ),
        ),
      );

  Widget _go(BuildContext c, String t, IconData i, Widget p) => SizedBox(
        height: 56,
        child: FilledButton.icon(
          onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => p)),
          icon: Icon(i),
          label: Text(t),
        ),
      );

  Widget _gap() => const SizedBox(height: 10);
}

// ================= إدارة الطلاب =================

class StudentsAdminPage extends StatefulWidget {
  const StudentsAdminPage({super.key});

  @override
  State<StudentsAdminPage> createState() => _StudentsAdminPageState();
}

class _StudentsAdminPageState extends State<StudentsAdminPage> {
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await AppStorage.getStudents();
    if (mounted) setState(() => students = data);
  }

  String createCode() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(5);
  }

  Future<void> addStudent() async {
    final nameController = TextEditingController();
    var selectedGrade = grades.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة طالب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الطالب'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGrade,
                decoration: const InputDecoration(labelText: 'الصف الدراسي'),
                items: grades
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedGrade = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (ok != true) {
      nameController.dispose();
      return;
    }

    final name = nameController.text.trim();
    nameController.dispose();
    if (name.isEmpty) return;

    final code = createCode();
    students.add({
      'id': const Uuid().v4(),
      'name': name,
      'grade': selectedGrade,
      'code': code,
    });
    await AppStorage.saveStudents(students);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('تم إنشاء الطالب. الكود: $code')));
  }

  Future<void> deleteStudent(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: Text('هل تريد حذف "${students[index]['name']}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    students.removeAt(index);
    await AppStorage.saveStudents(students);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('إدارة الطلاب'), centerTitle: true),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: addStudent,
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة طالب'),
          ),
          body: students.isEmpty
              ? const Center(child: Text('لا يوجد طلاب مضافون'))
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final s = students[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(s['name']?.toString() ?? ''),
                        subtitle:
                            Text('${s['grade']}\nالكود: ${s['code']}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => deleteStudent(i),
                        ),
                      ),
                    );
                  },
                ),
        ),
      );
}

// ================= إدارة الكتب =================

class BooksAdminPage extends StatefulWidget {
  const BooksAdminPage({super.key});

  @override
  State<BooksAdminPage> createState() => _BooksAdminPageState();
}

class _BooksAdminPageState extends State<BooksAdminPage> {
  List<Map<String, dynamic>> books = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await AppStorage.getBooks();
    if (!mounted) return;
    setState(() {
      books = data;
      loading = false;
    });
  }

  Future<void> addBook() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked == null || picked.files.single.path == null) return;

    final source = File(picked.files.single.path!);
    final titleController = TextEditingController();
    var grade = grades.first;
    var subject = subjects.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة كتاب أو مذكرة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(labelText: 'اسم الكتاب أو المذكرة'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: grade,
                  decoration: const InputDecoration(labelText: 'الصف الدراسي'),
                  items: grades
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => grade = v);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration: const InputDecoration(labelText: 'المادة'),
                  items: subjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => subject = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (ok != true) {
      titleController.dispose();
      return;
    }

    final title = titleController.text.trim().isEmpty
        ? source.path.split(Platform.pathSeparator).last
        : titleController.text.trim();
    titleController.dispose();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final destination = File('${dir.path}/${const Uuid().v4()}.pdf');
      await source.copy(destination.path);

      books.add({
        'id': const Uuid().v4(),
        'title': title,
        'grade': grade,
        'subject': subject,
        'path': destination.path,
        'date': DateTime.now().toIso8601String(),
      });
      await AppStorage.saveBooks(books);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الملف بنجاح')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  Future<void> deleteBook(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الملف'),
        content: Text('هل تريد حذف "${books[index]['title']}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;

    final path = books[index]['path']?.toString();
    if (path != null && path.isNotEmpty) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    books.removeAt(index);
    await AppStorage.saveBooks(books);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(
              title: const Text('إدارة الكتب والمذكرات'), centerTitle: true),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: addBook,
            icon: const Icon(Icons.add),
            label: const Text('إضافة PDF'),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : books.isEmpty
                  ? const Center(child: Text('لم تتم إضافة كتب أو مذكرات بعد'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: books.length,
                      itemBuilder: (_, i) {
                        final b = books[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf, size: 38),
                            title: Text(b['title']?.toString() ?? ''),
                            subtitle: Text('${b['grade']} - ${b['subject']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteBook(i),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      );
}

// ================= إنشاء السؤال =================

Future<Map<String, dynamic>?> addQuestionDialog(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) async {
  final qController =
      TextEditingController(text: initial?['question']?.toString() ?? '');
  final optionControllers = List.generate(
    4,
    (i) => TextEditingController(
        text: List<String>.from(initial?['options'] ?? const []).length > i
            ? List<String>.from(initial?['options'] ?? const [])[i]
            : ''),
  );
  final correctTextController =
      TextEditingController(text: initial?['correctText']?.toString() ?? '');
  var type = initial?['type']?.toString() ?? questionTypes.first;
  var correct = int.tryParse(initial?['correct']?.toString() ?? '') ?? 0;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(initial == null ? 'إضافة سؤال' : 'تعديل سؤال'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'نوع السؤال'),
                items: questionTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => type = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'نص السؤال'),
              ),
              if (type == 'اختيار من متعدد') ...[
                const SizedBox(height: 10),
                for (var i = 0; i < 4; i++) ...[
                  TextField(
                    controller: optionControllers[i],
                    decoration: InputDecoration(labelText: 'الخيار ${i + 1}'),
                  ),
                  const SizedBox(height: 7),
                ],
                DropdownButtonFormField<int>(
                  value: correct,
                  decoration:
                      const InputDecoration(labelText: 'الإجابة الصحيحة'),
                  items: List.generate(
                    4,
                    (i) => DropdownMenuItem(
                        value: i, child: Text('الخيار ${i + 1}')),
                  ),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => correct = v);
                  },
                ),
              ] else if (type == 'صح أو خطأ') ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: ['صح', 'خطأ']
                          .contains(correctTextController.text)
                      ? correctTextController.text
                      : 'صح',
                  decoration:
                      const InputDecoration(labelText: 'الإجابة الصحيحة'),
                  items: const [
                    DropdownMenuItem(value: 'صح', child: Text('صح')),
                    DropdownMenuItem(value: 'خطأ', child: Text('خطأ')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => correctTextController.text = v);
                    }
                  },
                ),
              ] else ...[
                const SizedBox(height: 10),
                TextField(
                  controller: correctTextController,
                  decoration:
                      const InputDecoration(labelText: 'الإجابة النموذجية'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final question = qController.text.trim();
              if (question.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اكتب نص السؤال')));
                return;
              }

              if (type == 'اختيار من متعدد') {
                final options =
                    optionControllers.map((c) => c.text.trim()).toList();
                if (options.any((x) => x.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('أكمل جميع الخيارات')));
                  return;
                }
                Navigator.pop(dialogContext, {
                  'type': type,
                  'question': question,
                  'options': options,
                  'correct': correct,
                  'correctText': options[correct],
                });
              } else {
                final answer = correctTextController.text.trim();
                if (answer.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('أدخل الإجابة الصحيحة')));
                  return;
                }
                Navigator.pop(dialogContext, {
                  'type': type,
                  'question': question,
                  'options': <String>[],
                  'correct': 0,
                  'correctText': answer,
                });
              }
            },
            child: Text(initial == null ? 'إضافة' : 'حفظ'),
          ),
        ],
      ),
    ),
  );

  qController.dispose();
  for (final c in optionControllers) {
    c.dispose();
  }
  correctTextController.dispose();
  return result;
}

// ================= إدارة الاختبارات =================

class ExamsAdminPage extends StatefulWidget {
  const ExamsAdminPage({super.key});

  @override
  State<ExamsAdminPage> createState() => _ExamsAdminPageState();
}

class _ExamsAdminPageState extends State<ExamsAdminPage> {
  List<Map<String, dynamic>> exams = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await AppStorage.getExams();
    if (!mounted) return;
    setState(() {
      exams = data;
      loading = false;
    });
  }

  Future<Map<String, dynamic>?> examDialog({
    Map<String, dynamic>? old,
  }) async {
    final titleController =
        TextEditingController(text: old?['title']?.toString() ?? '');
    var grade = old?['grade']?.toString() ?? grades.first;
    var subject = old?['subject']?.toString() ?? subjects.first;
    final questions = List<Map<String, dynamic>>.from(
        (old?['questions'] as List?) ?? const []);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(old == null ? 'إنشاء اختبار جديد' : 'تعديل الاختبار'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'اسم الاختبار'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: grade,
                    decoration: const InputDecoration(labelText: 'الصف الدراسي'),
                    items: grades
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => grade = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: subject,
                    decoration: const InputDecoration(labelText: 'المادة'),
                    items: subjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => subject = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('الأسئلة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  if (questions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('لم تتم إضافة أسئلة بعد'),
                    ),
                  ...List.generate(
                    questions.length,
                    (i) {
                      final q = questions[i];
                      return Card(
                        child: ListTile(
                          title: Text('${i + 1}. ${q['question']}'),
                          subtitle: Text(q['type']?.toString() ?? ''),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final edited = await addQuestionDialog(
                                    context,
                                    initial: q,
                                  );
                                  if (edited != null) {
                                    setDialogState(
                                        () => questions[i] = edited);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    setDialogState(() => questions.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final q = await addQuestionDialog(context);
                      if (q != null) setDialogState(() => questions.add(q));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة سؤال'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty || questions.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('أدخل اسم الاختبار وأضف سؤالًا واحدًا على الأقل')));
                  return;
                }
                Navigator.pop(dialogContext, {
                  'id': old?['id'] ?? const Uuid().v4(),
                  'title': title,
                  'grade': grade,
                  'subject': subject,
                  'questions': questions,
                  'date': old?['date'] ?? DateTime.now().toIso8601String(),
                });
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    return result;
  }

  Future<void> addExam() async {
    final e = await examDialog();
    if (e == null) return;
    exams.add(e);
    await AppStorage.saveExams(exams);
    if (mounted) setState(() {});
  }

  Future<void> editExam(int index) async {
    final e = await examDialog(old: exams[index]);
    if (e == null) return;
    exams[index] = e;
    await AppStorage.saveExams(exams);
    if (mounted) setState(() {});
  }

  Future<void> deleteExam(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الاختبار'),
        content: Text('هل تريد حذف "${exams[index]['title']}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    exams.removeAt(index);
    await AppStorage.saveExams(exams);
    if (mounted) setState(() {});
  }

  Future<void> previewExam(Map<String, dynamic> exam) async {
    final questions =
        List<Map<String, dynamic>>.from(exam['questions'] ?? []);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamPreviewPage(exam: exam, questions: questions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(title: const Text('إدارة الاختبارات'), centerTitle: true),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: addExam,
            icon: const Icon(Icons.add),
            label: const Text('إنشاء اختبار'),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : exams.isEmpty
                  ? const Center(child: Text('لا توجد اختبارات مضافة حتى الآن'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: exams.length,
                      itemBuilder: (_, i) {
                        final e = exams[i];
                        final qs =
                            List<Map<String, dynamic>>.from(e['questions'] ?? []);
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.assignment, size: 36),
                            title: Text(e['title']?.toString() ?? ''),
                            subtitle: Text(
                                '${e['grade']} - ${e['subject']}\nعدد الأسئلة: ${qs.length}'),
                            isThreeLine: true,
                            onTap: () => previewExam(e),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                    tooltip: 'تعديل',
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => editExam(i)),
                                IconButton(
                                    tooltip: 'حذف',
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => deleteExam(i)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      );
}

// ================= معاينة وتصدير الاختبار =================

class ExamPreviewPage extends StatelessWidget {
  final Map<String, dynamic> exam;
  final List<Map<String, dynamic>> questions;

  const ExamPreviewPage({
    super.key,
    required this.exam,
    required this.questions,
  });

  Future<Uint8List> buildPdf() async {
    final lines = <String>[
      'برنامج محمد القاضي التعليمي العلمي',
      'الاختبار: ${exam['title'] ?? ''}',
      'الصف: ${exam['grade'] ?? ''}',
      'المادة: ${exam['subject'] ?? ''}',
      '',
    ];

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      lines.add('${i + 1}. ${q['question'] ?? ''}');
      final type = q['type']?.toString() ?? '';
      if (type == 'اختيار من متعدد') {
        final options = List<String>.from(q['options'] ?? []);
        for (var j = 0; j < options.length; j++) {
          lines.add('   ${String.fromCharCode(65 + j)}- ${options[j]}');
        }
      } else if (type == 'صح أو خطأ') {
        lines.add('   (صح)     (خطأ)');
      } else {
        lines.add('   الإجابة: __________________________');
      }
      lines.add('');
    }

    return Printing.convertHtml(
      html: '<html><body dir="rtl"><pre>${_escape(lines.join('\n'))}</pre></body></html>',
    );
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(
            title: const Text('معاينة الاختبار'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'تصدير PDF',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () async {
                  final bytes = await buildPdf();
                  if (!context.mounted) return;
                  await Printing.layoutPdf(onLayout: (_) async => bytes);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Text(
                        'برنامج محمد القاضي التعليمي العلمي',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('الاختبار: ${exam['title'] ?? ''}'),
                      Text('المادة: ${exam['subject'] ?? ''}'),
                      Text('الصف: ${exam['grade'] ?? ''}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                questions.length,
                (i) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: _questionView(questions[i], i),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _questionView(Map<String, dynamic> q, int i) {
    final type = q['type']?.toString() ?? '';
    final children = <Widget>[
      Text('${i + 1}. ${q['question'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
    ];

    if (type == 'اختيار من متعدد') {
      final options = List<String>.from(q['options'] ?? []);
      children.addAll(List.generate(
        options.length,
        (j) => Text('${String.fromCharCode(65 + j)}- ${options[j]}'),
      ));
    } else if (type == 'صح أو خطأ') {
      children.add(const Text('صح  ☐      خطأ  ☐'));
    } else {
      children.add(const Text('الإجابة: __________________________'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

// ================= جميع النتائج =================

class AllResultsPage extends StatefulWidget {
  const AllResultsPage({super.key});

  @override
  State<AllResultsPage> createState() => _AllResultsPageState();
}

class _AllResultsPageState extends State<AllResultsPage> {
  List<Map<String, dynamic>> results = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await AppStorage.getResults();
    if (!mounted) return;
    setState(() {
      results = data;
      loading = false;
    });
  }

  Future<void> deleteResult(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف النتيجة'),
        content: const Text('هل تريد حذف هذه النتيجة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    results.removeAt(index);
    await AppStorage.saveResults(results);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar:
              AppBar(title: const Text('نتائج جميع الطلاب'), centerTitle: true),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : results.isEmpty
                  ? const Center(child: Text('لا توجد نتائج حتى الآن'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final r = results[i];
                        return Card(
                          child: ListTile(
                            leading:
                                const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(
                                r['studentName']?.toString() ?? 'طالب'),
                            subtitle: Text(
                              '${r['examTitle'] ?? 'اختبار'}\n'
                              '${r['grade'] ?? ''} - ${r['subject'] ?? ''}\n'
                              'الدرجة: ${r['score'] ?? 0} من ${r['total'] ?? 0}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteResult(i),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      );
}

// ================= السيرة =================

class TeacherBioPage extends StatelessWidget {
  const TeacherBioPage({super.key});

  @override
  Widget build(BuildContext context) => rtl(
        Scaffold(
          appBar: AppBar(
              title: const Text('الأستاذ محمد القاضي'), centerTitle: true),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CircleAvatar(
                radius: 65,
                child: Icon(Icons.person, size: 75),
              ),
              const SizedBox(height: 18),
              const Text(
                'الأستاذ محمد القاضي',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'أستاذ الكيمياء والفيزياء والأحياء بمدرسة النور الأساسية الثانوية بالروحاء - وصاب السافل.\n\n'
                    'بكالوريوس تربية تخصص كيمياء فيزيائية.\n\n'
                    'هذا البرنامج تعليمي محلي يعمل دون الحاجة إلى اتصال بالإنترنت، ويتيح للمعلم إدارة الطلاب والكتب والاختبارات والنتائج.',
                    style: TextStyle(fontSize: 18, height: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'الهاتف: 774470090\n'
                    'البريد الإلكتروني: alwsabi97@gmail.com\n\n'
                    'ادعم التعليم فالتعليم للجميع',
                    style: TextStyle(fontSize: 18, height: 1.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
