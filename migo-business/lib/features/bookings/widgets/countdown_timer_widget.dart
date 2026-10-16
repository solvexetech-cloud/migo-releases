// ═══════════════════════════════════════════════════════
// MIGO — Countdown Timer Widget (PHASE H)
// ═══════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime expiresAt;
  final DateTime bookedAt;
  final VoidCallback? onExpired;
  final bool compact;

  const CountdownTimerWidget({
    super.key,
    required this.expiresAt,
    required this.bookedAt,
    this.onExpired,
    this.compact = false,
  });

  @override
  State<CountdownTimerWidget> createState() =>
      _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _updateRemaining();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    if (!mounted) return;

    final now = DateTime.now();
    final remaining = widget.expiresAt.difference(now);

    if (remaining.isNegative) {
      setState(() {
        _remaining = Duration.zero;
        _expired = true;
      });
      _timer?.cancel();
      widget.onExpired?.call();
    } else {
      setState(() {
        _remaining = remaining;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _remainingPercent {
    final total = widget.expiresAt.difference(widget.bookedAt).inSeconds;
    if (total <= 0) return 0;
    final left = _remaining.inSeconds;
    return (left / total).clamp(0.0, 1.0);
  }

  Color _getColor() {
    if (_expired) return Colors.grey;
    final pct = _remainingPercent;
    if (pct > 0.5) return const Color(0xFF10B981);
    if (pct > 0.2) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _formatDuration() {
    if (_expired) return 'Expired';
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);

    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _expired ? Icons.timer_off : Icons.timer_outlined,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _expired ? Icons.timer_off : Icons.timer_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _expired ? 'Expired' : 'Expires in:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatDuration(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _remainingPercent,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}