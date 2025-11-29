import 'package:flutter/material.dart';

class KeyboardKey extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  final Color? color;

  const KeyboardKey({
    super.key,
    required this.letter,
    required this.onTap,
    this.color,
  });

  @override
  State<KeyboardKey> createState() => _KeyboardKeyState();
}

class _KeyboardKeyState extends State<KeyboardKey> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 30, maxHeight: 60),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
                decoration: BoxDecoration(
                  gradient: _getGradient(widget.color),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isPressed
                      ? [
                          BoxShadow(
                            color: (widget.color ?? Colors.grey[300]!)
                                .withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: (widget.color ?? Colors.grey[300]!)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    widget.letter,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getTextColor(widget.color),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  LinearGradient _getGradient(Color? baseColor) {
    final color = baseColor ?? Colors.grey[300]!;

    // Enhanced gradients for game colors
    if (baseColor == Colors.green.shade400 ||
        baseColor == Colors.green ||
        (baseColor != null && baseColor.value == Colors.green.value)) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      );
    } else if (baseColor == Colors.yellow.shade600 ||
        baseColor == Colors.yellow) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      );
    } else if (baseColor == Colors.grey.shade400 ||
        baseColor == Colors.grey[300]) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey[200]!, Colors.grey[300]!],
      );
    }

    // Default gradient
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color.withOpacity(0.9), color],
    );
  }

  Color _getTextColor(Color? baseColor) {
    if (baseColor == Colors.green.shade400 ||
        baseColor == Colors.green ||
        baseColor == Colors.yellow.shade600 ||
        baseColor == Colors.yellow) {
      return Colors.white;
    }
    return Colors.black87;
  }
}

class DeleteButton extends StatefulWidget {
  final VoidCallback onDelete;

  const DeleteButton({super.key, required this.onDelete});

  @override
  State<DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<DeleteButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onDelete();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 60,
        height: 45,
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isPressed
              ? [
                  const BoxShadow(
                    color: Color(0x40EF4444),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x50EF4444),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: const Center(
          child: Text(
            'Sil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class SubmitButton extends StatefulWidget {
  final VoidCallback onSubmit;

  const SubmitButton({super.key, required this.onSubmit});

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onSubmit();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 60,
        height: 45,
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isPressed
              ? [
                  const BoxShadow(
                    color: Color(0x4010B981),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x5010B981),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: const Center(
          child: Text(
            'Onayla',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
