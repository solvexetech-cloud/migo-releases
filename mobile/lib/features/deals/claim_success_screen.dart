import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../core/theme/migo_colors.dart';
import '../../core/theme/migo_gradients.dart';
import '../../core/theme/migo_shadows.dart';
import '../../models/offer_model.dart';
import 'my_claims_screen.dart';

class ClaimSuccessScreen extends StatefulWidget {
  const ClaimSuccessScreen({
    super.key,
    required this.offer,
    this.coinsAwarded = 5,
  });

  final OfferModel offer;
  final int coinsAwarded;

  @override
  State<ClaimSuccessScreen> createState() => _ClaimSuccessScreenState();
}

class _ClaimSuccessScreenState extends State<ClaimSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
      duration: const Duration(milliseconds: 1800),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleCtrl,
      curve: Curves.elasticOut,
    );

    // Fire confetti + scale in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      _scaleCtrl.forward();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MigoColors.backgroundLight,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Success check icon
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: MigoGradients.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                MigoColors.success.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                                      const Text(
                    'Offer Activated!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: MigoColors.textPrimaryLight,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can view this offer and its QR code in your Active Deals. Show it at the business to redeem.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: MigoColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                 
                  const SizedBox(height: 32),

                  // Offer summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MigoColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: MigoShadows.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.offer.businessName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.offer.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: MigoColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '${widget.offer.currency} ${widget.offer.originalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                                color: MigoColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.offer.currency} ${widget.offer.offerPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: MigoColors.primary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: MigoColors.success
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SAVE ${widget.offer.currency} ${widget.offer.savings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: MigoColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // View QR button
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const MyClaimsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('View Active Deals'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Back to home'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti overlay
          ConfettiWidget(
            confettiController: _confetti,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.04,
            numberOfParticles: 24,
            gravity: 0.25,
            shouldLoop: false,
            colors: const [
              MigoColors.primary,
              MigoColors.accent,
              MigoColors.success,
              Color(0xFFE85D5D),
              Color(0xFFF0C566),
            ],
          ),
        ],
      ),
    );
  }
}