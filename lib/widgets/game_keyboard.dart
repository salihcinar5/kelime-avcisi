import 'package:flutter/material.dart';
import 'keyboard_key.dart';

class GameKeyboard extends StatelessWidget {
  final Function(String) onKeyTap;
  final Function() onDelete;
  final Function() onSubmit;
  final Function(String) getKeyColor;

  const GameKeyboard({
    super.key,
    required this.onKeyTap,
    required this.onDelete,
    required this.onSubmit,
    required this.getKeyColor,
  });

  @override
  Widget build(BuildContext context) {
    const List<List<String>> keyboardLayout = [
      ['E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'Ğ', 'Ü'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ş', 'İ'],
      ['ENTER', 'Z', 'C', 'V', 'B', 'N', 'M', 'Ö', 'Ç', 'BACKSPACE'],
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keyboardLayout
          .map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((letter) {
                  if (letter == 'BACKSPACE') {
                    return Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 50, // Minimum yükseklik
                            maxHeight: 80, // Maksimum yükseklik
                          ),
                          child: ElevatedButton(
                            onPressed: onDelete,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Icon(
                              Icons.backspace,
                              color: Colors.red,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else if (letter == 'ENTER') {
                    return Expanded(
                      flex: 2, // ENTER tuşu için daha geniş bir alan
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 50, // Minimum yükseklik
                            maxHeight: 70, // Maksimum yükseklik
                            minWidth: 40,
                            maxWidth: 40,
                          ),
                          child: ElevatedButton(
                            onPressed: onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Expanded(
                      flex: 1, // Normal tuşlar için standart boyut
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: KeyboardKey(
                          letter: letter,
                          onTap: () => onKeyTap(letter),
                          color: getKeyColor(letter),
                        ),
                      ),
                    );
                  }
                }).toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}
