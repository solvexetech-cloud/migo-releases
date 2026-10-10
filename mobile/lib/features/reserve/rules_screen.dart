// ═══════════════════════════════════════════════════════
// MIGO — Rules Screen (PHASE H)
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/reservation_rules_model.dart';
import '../../services/reservation_service.dart';
import '../../core/localization/locale_provider.dart';

class RulesScreen extends StatefulWidget {
  final ReservationRulesModel rules;
  final bool requireAcceptance;

  const RulesScreen({
    super.key,
    required this.rules,
    this.requireAcceptance = true,
  });

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  bool _scrolledToBottom = false;
  bool _accepted = false;
  bool _saving = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (!widget.requireAcceptance) {
      _scrolledToBottom = true;
      _accepted = true;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrolledToBottom) return;
    if (!_scrollController.hasClients) return;

    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    if (current >= max - 50) {
      setState(() => _scrolledToBottom = true);
    }
  }

  Future<void> _handleAccept() async {
    if (!_accepted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showError('Please sign in to continue');
      return;
    }

    setState(() => _saving = true);

    try {
      await ReservationService.instance.acceptRules(uid, widget.rules.version);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleProvider.instance.locale;
    final rulesText = widget.rules.textForLocale(locale);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rules.title),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Version badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Version ${widget.rules.version}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Rules content (scrollable)
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rulesText,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!_scrolledToBottom && widget.requireAcceptance)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                          Text(
                            'Scroll to bottom to accept',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Accept section
          if (widget.requireAcceptance)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Checkbox
                    InkWell(
                      onTap: _scrolledToBottom
                          ? () => setState(() => _accepted = !_accepted)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _accepted,
                              onChanged: _scrolledToBottom
                                  ? (v) =>
                                      setState(() => _accepted = v ?? false)
                                  : null,
                              activeColor: const Color(0xFF7C3AED),
                            ),
                            Expanded(
                              child: Text(
                                'I have read and accept the Reserve Rules',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _scrolledToBottom
                                      ? Colors.black87
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Accept button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _accepted && !_saving ? _handleAccept : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'I Accept',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}