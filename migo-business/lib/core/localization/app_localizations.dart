// mobile/lib/core/localization/app_localizations.dart
// NEW FILE - English & Arabic Translations
// Created: Nov 09, 2026

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  bool get isArabic => locale.languageCode == 'ar';

  // =========================================================================
  // TRANSLATION DICTIONARY
  // =========================================================================
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General
      'app_name': 'MIGO',
      'loading': 'Loading...',
      'error': 'Something went wrong',
      'retry': 'Retry',
      'save': 'Save',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'success': 'Success',
      
      // New Demand Form
      'new_demand': 'New Demand',
      'product_name': 'What do you want to buy?',
      'category': 'Category',
      'quantity': 'Quantity (How many?)',
      'target_price': 'Target Price',
      'description': 'Description (Optional)',
      'delivery_date': 'Preferred Delivery Date',
      'create_demand': 'Post Demand',
      'demand_posted_success': 'Demand posted successfully!',
      
      // My Demands
      'my_demands': 'My Demands',
      'waiting_for_people': 'Waiting for more people',
      'people_want_this': 'people want this',
      'receiving_offers': 'Receiving offers from shops',
      'order_placed': 'Order placed successfully',
      'expired_try_again': 'Expired - try again',
      'your_demand': 'Your Demand',
      'view_group': 'View Group',
      
      // Business App
      'business_demands': 'Customer Demands',
      'target_price_range': 'Target Price Range',
      'total_quantity': 'Total Quantity',
      'place_bid': 'Place Bid',
      
      // Admin Panel (if used)
      'demand_settings': 'Demand Settings',
      'threshold': 'Minimum People Required',
      'expiry_days': 'Expiry (Days)',
      'private_bulk_min': 'Private Bulk Minimum Quantity',
    },
    'ar': {
      // General
      'app_name': 'ميجو',
      'loading': 'جاري التحميل...',
      'error': 'حدث خطأ ما',
      'retry': 'إعادة المحاولة',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'submit': 'إرسال',
      'success': 'نجاح',
      
      // New Demand Form
      'new_demand': 'طلب جديد',
      'product_name': 'ماذا تريد أن تشتري؟',
      'category': 'الفئة',
      'quantity': 'الكمية (كم عدد؟)',
      'target_price': 'السعر المستهدف',
      'description': 'الوصف (اختياري)',
      'delivery_date': 'تاريخ التسليم المفضل',
      'create_demand': 'نشر الطلب',
      'demand_posted_success': 'تم نشر الطلب بنجاح!',
      
      // My Demands
      'my_demands': 'طلباتي',
      'waiting_for_people': 'في انتظار المزيد من الناس',
      'people_want_this': 'أشخاص يريدون هذا',
      'receiving_offers': 'تتلقى عروضاً من المتاجر',
      'order_placed': 'تم تقديم الطلب بنجاح',
      'expired_try_again': 'انتهت الصلاحية - حاول مرة أخرى',
      'your_demand': 'طلبك',
      'view_group': 'عرض المجموعة',
      
      // Business App
      'business_demands': 'طلبات العملاء',
      'target_price_range': 'نطاق السعر المستهدف',
      'total_quantity': 'الكمية الإجمالية',
      'place_bid': 'تقديم عرض',
      
      // Admin Panel
      'demand_settings': 'إعدادات الطلب',
      'threshold': 'الحد الأدنى للأشخاص المطلوبين',
      'expiry_days': 'انتهاء الصلاحية (أيام)',
      'private_bulk_min': 'الحد الأدنى للكمية بالجملة',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}