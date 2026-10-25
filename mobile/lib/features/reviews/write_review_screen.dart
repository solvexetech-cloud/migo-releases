import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/migo_colors.dart';
import '../../models/claim_model.dart';
import '../../models/review_model.dart';
import '../../services/firestore_service.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key, required this.claim});
  final ClaimModel claim;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final isAr = LocaleProvider.instance.locale == 'ar';

    if (_comment.text.trim().length < 5) {
      setState(() => _error = isAr
          ? 'يرجى كتابة 5 أحرف على الأقل عن تجربتك.'
          : 'Please write at least 5 characters about your experience.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = isAr ? 'أنت غير مسجل الدخول.' : 'You are not signed in.');
      return;
    }

    setState(() => _loading = true);
    try {
      final review = ReviewModel.newDraft(
        userUid: user.uid,
        userDisplayName: user.email ?? (isAr ? 'مستخدم ميجو' : 'MIGO User'),
        businessId: widget.claim.businessId,
        businessName: widget.claim.businessName,
        rating: _rating,
        comment: _comment.text.trim(),
        claimId: widget.claim.id,
        offerId: widget.claim.offerId,
        offerTitle: widget.claim.offerTitle,
        verifiedVisit: true,
      );

      await FirestoreService.instance.createReview(review);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr
              ? 'شكرًا لمراجعتك! تم منحك +10 عملات.'
              : 'Thanks for your review! +10 coins awarded.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = isAr ? 'فشل: $e' : 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        final isAr = LocaleProvider.instance.locale == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(title: Text(isAr ? 'اكتب مراجعة' : 'Write a review')),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MigoColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: MigoColors.dividerLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.claim.businessName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.claim.offerTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: MigoColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: MigoColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: MigoColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAr ? 'زيارة موثقة' : 'VERIFIED VISIT',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: MigoColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isAr ? 'تقييمك' : 'Your rating',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final filled = i < _rating;
                        return IconButton(
                          onPressed: () => setState(() => _rating = i + 1),
                          icon: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 40,
                            color: MigoColors.accent,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _ratingLabel(_rating, isAr),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MigoColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isAr ? 'تجربتك' : 'Your experience',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _comment,
                      maxLines: 6,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'ماذا أعجبك؟ ماذا يمكن أن يكون أفضل؟'
                            : 'What did you like? What could be better?',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: MigoColors.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isAr ? 'نشر المراجعة' : 'Post review'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _ratingLabel(int rating, bool isAr) {
    switch (rating) {
      case 1:
        return isAr ? 'ضعيف' : 'Poor';
      case 2:
        return isAr ? 'أقل من المتوسط' : 'Below average';
      case 3:
        return isAr ? 'مقبول' : 'Okay';
      case 4:
        return isAr ? 'جيد' : 'Good';
      case 5:
        return isAr ? 'ممتاز' : 'Excellent';
      default:
        return '';
    }
  }
}