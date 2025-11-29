import 'package:flutter/material.dart';

class GuessRows extends StatelessWidget {
  final int maxAttempts;
  final int wordLength;
  final List<String> attempts;
  final Function(int, int) getBackgroundColor;
  final ScrollController scrollController;
  final int currentAttempt;

  const GuessRows({
    super.key,
    required this.maxAttempts,
    required this.wordLength,
    required this.attempts,
    required this.getBackgroundColor,
    required this.scrollController,
    required this.currentAttempt,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = 45.0;
    double availableWidth = screenWidth - (padding * 2);
    double cellSize = availableWidth / wordLength;

    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          for (int i = 0; i < maxAttempts; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_right,
                    color: currentAttempt == i
                        ? const Color(0xFF6366F1)
                        : Colors.transparent,
                    size: 28,
                  ),
                  for (int j = 0; j < wordLength; j++)
                    Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: getBackgroundColor(i, j) ==
                                    Colors.transparent
                                ? const Color(0xFFE2E8F0)
                                : getBackgroundColor(i, j),
                            width: 2.5,
                          ),
                          color: getBackgroundColor(i, j),
                          boxShadow: getBackgroundColor(i, j) !=
                                  Colors.transparent
                              ? [
                                  BoxShadow(
                                    color: getBackgroundColor(i, j)
                                        .withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          i < attempts.length && attempts[i].length > j
                              ? attempts[i][j]
                              : '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: getBackgroundColor(i, j) ==
                                    Colors.transparent
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
