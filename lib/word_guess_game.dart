import 'package:flutter/material.dart';
import 'package:kelime_avcisi/widgets/interstitial_ad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turkish/turkish.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'widgets/guess_rows.dart';
import 'widgets/game_keyboard.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' show pi, cos, sin;
import 'package:confetti/confetti.dart';
import 'widgets/level_selection_dialog.dart';
import 'widgets/banner_ad_widget.dart';
import 'widgets/reward_ad.dart';
import 'package:google_fonts/google_fonts.dart';

enum GameLevel {
  easy, // 4 harf
  medium, // 5 harf
  hard, // 6 harf
}

class WordGuessGame extends StatefulWidget {
  const WordGuessGame({super.key});

  @override
  State<WordGuessGame> createState() => _WordGuessGameState();
}

class _WordGuessGameState extends State<WordGuessGame> {
  int wordLength = 5;
  int maxAttempts = 5;
  bool hasUsedVideoChance = false;
  bool showAnswer = false;
  GameLevel? currentLevel;

  String targetWord = "KALEM";
  List<String> attempts = [];
  Set<String> usedLetters = {};
  int currentAttempt = 0;
  int totalAttempts = 0;
  int gamesPlayed = 0;
  bool showHowToPlay = true;

  final _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  final ScrollController _scrollController = ScrollController();

  final RewardAdManager _rewardAdManager = RewardAdManager();
  final InterstitialAdManager _interstitialAdManager = InterstitialAdManager();

  @override
  void initState() {
    super.initState();
    attempts = List.filled(maxAttempts, '', growable: true);

    // Seviye seçim dialogunu göster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLevelSelectionDialog();
    });
    _loadStatistics();
    _rewardAdManager.loadRewardedAd(); // Reklamı yükle
    _interstitialAdManager.loadInterstitialAd();
    _loadWords();
    SharedPreferences.getInstance().then((prefs) {
      showHowToPlay = prefs.getBool('showHowToPlay') ?? true;
      if (showHowToPlay) {
        _showHowToPlay();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    _interstitialAdManager.dispose();
    super.dispose();
  }

  void _showLevelSelectionDialog() {
    showDialog<void>(
      context: this.context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) =>
          LevelSelectionDialog(onLevelSelected: _startGameWithLevel),
    );
  }

  void _startGameWithLevel(GameLevel level) {
    setState(() {
      currentLevel = level;
      wordLength = level == GameLevel.easy
          ? 4
          : level == GameLevel.medium
          ? 5
          : 6;
      maxAttempts = 5; // Seviye değişiminde de 5 ile başla
      attempts = List.filled(
        maxAttempts,
        '',
        growable: true,
      ); // Deneme sayısını sıfırla
      currentAttempt = 0; // Deneme sayısını sıfırla
      hasUsedVideoChance = false;
      showAnswer = false;
      usedLetters.clear();
    });

    _loadWords(); // Yeni kelime yükle
  }

  Future<void> _loadWords() async {
    // SQLite FFI'yi başlat
    sqfliteFfiInit();
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'word_database.db');

    // Veritabanı dosyasının varlığını kontrol et
    if (!await File(path).exists()) {
      ByteData data = await rootBundle.load('assets/word_database.db');
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes);
    }

    // Veritabanını aç
    final db = await openDatabase(path);
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT word FROM words WHERE LENGTH(word) = ? ORDER BY RANDOM() LIMIT 1",
      [wordLength],
    );

    if (result.isNotEmpty) {
      setState(() {
        targetWord = result.first['word']
            .toString()
            .replaceAll("â", "a")
            .replaceAll("î", "i")
            .replaceAll("û", "u")
            .toUpperCaseTr();
        print("Yeni kelime: $targetWord"); // Debug için
      });
    }

    await db.close();
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalAttempts = prefs.getInt('totalAttempts') ?? 0;
      gamesPlayed = prefs.getInt('gamesPlayed') ?? 0;
    });
  }

  Future<void> _saveStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalAttempts', totalAttempts);
    await prefs.setInt('gamesPlayed', gamesPlayed);
  }

  void _onKeyTap(String letter) {
    if (currentAttempt >= maxAttempts) return;

    setState(() {
      if (attempts[currentAttempt].length < wordLength) {
        attempts[currentAttempt] = attempts[currentAttempt] + letter;
      }
    });
  }

  void _onDelete() {
    if (currentAttempt >= maxAttempts) return;

    setState(() {
      if (attempts[currentAttempt].isNotEmpty) {
        attempts[currentAttempt] = attempts[currentAttempt].substring(
          0,
          attempts[currentAttempt].length - 1,
        );
      }
    });
  }

  void _scrollToCurrentAttempt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Her bir tahmin satırının yaklaşık yüksekliği
      const double guessRowHeight = 70.0;

      // Scroll pozisyonunu, mevcut tahmini merkeze alacak şekilde hesapla
      double scrollPosition =
          (currentAttempt * guessRowHeight) -
          (_scrollController.position.viewportDimension / 2) +
          (guessRowHeight / 2);

      // Scroll pozisyonunu sınırla
      scrollPosition = scrollPosition.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<bool> _checkWordInDatabase(String word) async {
    // SQLite FFI'yi başlat
    sqfliteFfiInit();

    // Veritabanı dosyasının varlığını kontrol et
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'word_database.db');

    // Veritabanını aç
    final db = await openDatabase(path);

    // Kelimeyi kontrol et
    var result = await db.rawQuery(
      "SELECT * FROM words WHERE UPPER(REPLACE(REPLACE(REPLACE(word, 'â', 'a'), 'î', 'i'), 'û', 'u')) = ?  LIMIT 1",
      [word],
    );
    await db.close();

    return result.isNotEmpty; // Kelime veritabanında varsa true döner
  }

  void _onSubmit(BuildContext context) async {
    if (currentAttempt >= maxAttempts) return;
    if (attempts[currentAttempt].length != wordLength) return;

    bool wordExists = await _checkWordInDatabase(attempts[currentAttempt]);
    if (!wordExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kelime mevcut değil'),
          duration: const Duration(seconds: 2),
        ),
      );
      return; // İşlemi durdur
    }
    setState(() {
      if (attempts[currentAttempt] == targetWord) {
        totalAttempts += currentAttempt + 1;
        gamesPlayed++;
        _saveStatistics();
        _showSuccessDialog();
        _getBackgroundColor(currentAttempt, 0);
      } else {
        currentAttempt++;
        if (currentAttempt >= maxAttempts) {
          gamesPlayed++;
          totalAttempts += maxAttempts;
          _saveStatistics();
          _showGameOverDialog();
        }
      }
    });
    // Gönderim sonrası, klavyedeki kullanılan harfleri güncelle (gönderilen tahmini her zaman dahil et)
    _setUsedLetters(includeCurrent: true);

    _scrollToCurrentAttempt();
  }

  void _showGameOverDialog() {
    showDialog<void>(
      context: this.context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          'Oyun Bitti!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              showAnswer ? "Yanıt: $targetWord" : 'Maalesef bilemediniz 😔',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _resetGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    'Yeni Oyun',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                if (!showAnswer)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showAnswer = true;
                        hasUsedVideoChance = true;
                      });

                      Navigator.pop(dialogContext);
                      _showGameOverDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64748B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      'Yanıtı Gör',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            if (!hasUsedVideoChance) // Video hakkı kullanılmamışsa göster
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _watchVideoForExtraAttempt();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  'Bir deneme hakkı al',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _watchVideoForExtraAttempt() {
    _rewardAdManager.showRewardedAd(incrementAttempt);
  }

  Color _getBackgroundColor(int row, int col) {
    if (row >= currentAttempt || attempts[row].isEmpty) {
      return Colors.transparent;
    }

    String letter = attempts[row][col];

    int targetCount = targetWord.split('').where((c) => c == letter).length;

    List<int> correctPositions = [];
    for (int i = 0; i < wordLength; i++) {
      if (targetWord[i] == letter && attempts[row][i] == letter) {
        correctPositions.add(i);
      }
    }

    if (correctPositions.contains(col)) {
      return Colors.green;
    }

    int remainingYellow = targetCount - correctPositions.length;
    if (remainingYellow > 0) {
      // Bu harfin bu pozisyona kadar kaç kez sarı yapıldığını say
      int yellowCount = 0;
      for (int i = 0; i < col; i++) {
        if (attempts[row][i] == letter && !correctPositions.contains(i)) {
          yellowCount++;
        }
      }

      if (yellowCount < remainingYellow) {
        return Colors.yellow;
      }
    }

    return Colors.grey.shade300;
  }

  void _setUsedLetters({bool includeCurrent = false}) {
    // Sadece gönderilmiş tahminlerden (currentAttempt öncesi) veya
    // includeCurrent == true ise mevcut tahmini de dahil ederek kullanılmış harfleri al
    int takeCount = currentAttempt + (includeCurrent ? 1 : 0);
    Set<String> allUsedLetters = attempts
        .take(takeCount)
        .expand((attempt) => attempt.split(''))
        .toSet();
    setState(() {
      usedLetters = allUsedLetters;
    });
  }

  Color _getKeyColor(String letter) {
    if (!usedLetters.contains(letter)) {
      return Colors.grey.shade300;
    }

    bool isGreen = false;
    bool isYellow = false;

    // En son durumu bulmak için tüm tahminleri kontrol et
    for (int i = 0; i < currentAttempt; i++) {
      if (attempts[i].contains(letter)) {
        // Doğru pozisyonda mı kontrol et
        for (int j = 0; j < wordLength; j++) {
          if (targetWord[j] == letter && attempts[i][j] == letter) {
            isGreen = true; // Doğru harf, doğru pozisyon bulundu
            break;
          }
        }
        // Kelimede var ama pozisyon yanlış
        if (!isGreen && targetWord.contains(letter)) {
          isYellow = true;
        }
      }
    }

    if (isGreen) return Colors.green.shade400;
    if (isYellow) return Colors.yellow.shade600;
    return Colors.grey.shade500; // Kullanılmış ve kelimede olmayan
  }

  void _showSuccessDialog() {
    _confettiController.play();
    showDialog<void>(
      context: this.context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Stack(
        alignment: Alignment.center,
        children: [
          AlertDialog(
            title: Text(
              'Tebrikler! 🎉',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kelimeyi ${currentAttempt + 1} denemede buldunuz!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _resetGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: Text(
                    'Yeni Oyun',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            maxBlastForce: 50,
            minBlastForce: 30,
            gravity: 0.3,
            createParticlePath: drawStar,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      currentAttempt = 0;
      maxAttempts = 5; // Her zaman 5 ile başla
      attempts = List.filled(maxAttempts, '', growable: true);
      hasUsedVideoChance = false;
      showAnswer = false;
      usedLetters.clear();
    });
    if (gamesPlayed % 5 == 0) {
      _interstitialAdManager.showInterstitialAd();
    }
    _loadWords(); // Aynı seviyede yeni kelime yükle
  }

  void _showHowToPlay() {
    showDialog(
      context: this.context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            "Nasıl Oynanır?",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: const Color(0xFF1E293B),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "1. Bir kelime tahmininde bulunun. Seçilen zorluk seviyesine göre 4, 5 veya 6 olabilir.",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "2. Kelimede var olan ve yeri doğru olan harfler yeşil renkte gösterilir. Var olan ama yeri yanlış olan harfler sarı renkte gösterilir.",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "3. Kelimede olmayan harfler gri renkte gösterilir. Tahmin haklarınızı kullanarak kelimeyi bulmaya çalışın.",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.setBool('showHowToPlay', false);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
              ),
              child: Text(
                "Tamam, anladım",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStatistics() {
    showDialog<void>(
      context: this.context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          'İstatistikler',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Toplam Oyun', gamesPlayed.toString()),
            const SizedBox(height: 10),
            _buildStatRow(
              'Ortalama Tahmin',
              gamesPlayed > 0
                  ? (totalAttempts / gamesPlayed).toStringAsFixed(1)
                  : '0',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
            ),
            child: Text(
              'Kapat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  void incrementAttempt() {
    setState(() {
      maxAttempts++;
      attempts.add("");
      hasUsedVideoChance = true;
      showAnswer = true;
      gamesPlayed--;
      _scrollToCurrentAttempt();
      _saveStatistics();
      //currentAttempt++; // Deneme sayısını artır
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x406366F1),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            toolbarHeight: 80,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Kelime Avcısı',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  size: 28,
                  color: Colors.white,
                ),
                onPressed: _showHowToPlay,
                tooltip: 'Nasıl Oynanır',
              ),
              IconButton(
                icon: const Icon(Icons.speed, size: 28, color: Colors.white),
                onPressed: _showLevelSelectionDialog,
                tooltip: 'Seviye Seç',
              ),
              IconButton(
                icon: const Icon(
                  Icons.bar_chart,
                  size: 28,
                  color: Colors.white,
                ),
                onPressed: _showStatistics,
                tooltip: 'İstatistikler',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: GuessRows(
                          currentAttempt: currentAttempt,
                          maxAttempts: maxAttempts,
                          wordLength: wordLength,
                          attempts: attempts,
                          getBackgroundColor: _getBackgroundColor,
                          scrollController: _scrollController,
                        ),
                      ),
                    ),
                    GameKeyboard(
                      onKeyTap: _onKeyTap,
                      onDelete: _onDelete,
                      onSubmit: () => _onSubmit(context),
                      getKeyColor: _getKeyColor,
                    ),
                    const SizedBox(
                      height: 10,
                    ), // Keyboard ile banner arası boşluk
                  ],
                ),
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  maxBlastForce: 80,
                  minBlastForce: 30,
                  gravity: 0.3,
                ),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

Path drawStar(Size size) {
  double centerX = size.width / 2;
  double centerY = size.height / 2;
  double radius = size.width / 2;

  Path path = Path();
  for (int i = 0; i < 5; i++) {
    double angle = (i * 4 * pi) / 5;
    Offset point = Offset(
      centerX + radius * cos(angle),
      centerY + radius * sin(angle),
    );
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}
