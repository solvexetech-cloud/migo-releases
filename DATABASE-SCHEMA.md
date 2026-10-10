# MIGO — DATABASE SCHEMA
# Version: 1.3.1
# Last Updated: October 7, 2026
# Firestore Region: me-central1 (Doha)

## 📋 OVERVIEW
MIGO uses Firebase Firestore as primary database.
All timestamps use FieldValue.serverTimestamp() (UTC).

## 🗂️ COLLECTIONS

### 1. users/{uid}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| email | string | yes | Auth email |
| displayName | string | yes | |
| phone | string | no | |
| coins | number | yes | Default 0 |
| loyaltyLevel | string | no | bronze/silver/gold/platinum |
| country | string | no | |
| city | string | no | |
| currency | string | yes | QAR/INR |
| locale | string | yes | en/ml |
| role | string | yes | See Role System |
| referralCode | string | yes | Unique 6-char |
| referredBy | string | no | |
| hasCompletedFirstClaim | bool | yes | Default false |
| currentAreaId | string | no | B3.7 auto-detected |
| currentCountryCode | string | no | QA/IN |
| fcmToken | string | no | Push token |
| fcmPlatform | string | no | android/ios |
| fcmTokenUpdatedAt | timestamp | no | |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |

### 2. businesses/{id}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| ownerUid | string | yes | FK users.uid |
| name | string | yes | |
| category | string | yes | FK categories.slug |
| addressLine | string | yes | |
| city | string | yes | |
| country | string | yes | |
| currency | string | yes | |
| description | string | no | |
| phone | string | yes | |
| whatsapp | string | no | |
| lat | number | no | |
| lng | number | no | |
| logoUrl | string | no | Cloudinary |
| coverUrl | string | no | Cloudinary |
| photos | array | no | Cloudinary URLs |
| openTime | string | no | "09:00" |
| closeTime | string | no | "22:00" |
| website | string | no | |
| mapUrl | string | no | |
| status | string | yes | pending/approved/suspended |
| verified | bool | yes | Default false |
| countryCode | string | yes | B3 QA/IN |
| zoneId | string | no | B3 zone slug |
| areaId | string | no | B3 area slug |
| agencyUid | string | no | B3 FK agencies |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |

### 3. offers/{id}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| businessId | string | yes | FK businesses.id |
| businessName | string | yes | Denormalized |
| title | string | yes | |
| description | string | yes | |
| originalPrice | number | yes | |
| offerPrice | number | yes | |
| currency | string | yes | |
| type | string | yes | standard/flash/group/hidden_gem/birthday |
| startAt | timestamp | yes | |
| endAt | timestamp | yes | Auto-hide after |
| category | string | yes | FK categories.slug |
| imageUrl | string | no | |
| terms | string | no | |
| dailyLimit | number | no | null = unlimited |
| totalLimit | number | no | null = unlimited |
| claimedCount | number | yes | Default 0 |
| status | string | yes | draft/live/expired/paused |
| countryCode | string | yes | B3 denormalized |
| zoneId | string | no | B3 denormalized |
| areaId | string | yes | B3 denormalized |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |

### 4. claims/{id}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| userUid | string | yes | FK users.uid |
| businessId | string | yes | FK businesses.id |
| businessName | string | yes | Denormalized |
| offerId | string | yes | FK offers.id |
| offerTitle | string | yes | Denormalized |
| originalPrice | number | yes | Snapshot |
| offerPrice | number | yes | Snapshot |
| currency | string | yes | |
| claimedAt | timestamp | yes | |
| expiresAt | timestamp | yes | Auto-expire QR |
| status | string | yes | active/redeemed/expired |
| redeemedAt | timestamp | no | |
| redeemedBy | string | no | |
| source | string | no | app/referral/web |

### 5. reviews/{id}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| userUid | string | yes | FK users.uid |
| userName | string | yes | Denormalized |
| businessId | string | yes | FK businesses.id |
| offerId | string | no | |
| claimId | string | no | Verified purchase |
| rating | number | yes | 1-5 |
| comment | string | no | |
| isPositive | bool | yes | rating >= 4 |
| createdAt | timestamp | yes | |

### 6. referrals/{id}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| referrerUid | string | yes | FK users.uid |
| referrerCode | string | yes | |
| referredUid | string | yes | FK users.uid |
| referredCode | string | no | |
| status | string | yes | pending/completed/rewarded |
| rewardAmount | number | yes | Coins |
| createdAt | timestamp | yes | |
| completedAt | timestamp | no | |

### 7. notifications/{id}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| userUid | string | yes | FK users.uid |
| title | string | yes | |
| body | string | yes | |
| type | string | yes | claim/offer/system/referral |
| data | map | no | Deep link |
| read | bool | yes | Default false |
| createdAt | timestamp | yes | |

### 8. coin_transactions/{id}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| uid | string | yes | FK users.uid |
| amount | number | yes | +/- |
| type | string | yes | earn/spend/referral/bonus |
| description | string | yes | |
| relatedId | string | no | |
| createdAt | timestamp | yes | |

### 9. saved_offers/{uid_offerId}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| userUid | string | yes | |
| offerId | string | yes | |
| businessId | string | yes | Denormalized |
| createdAt | timestamp | yes | |

### 10. saved_businesses/{uid_businessId}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| userUid | string | yes | |
| businessId | string | yes | |
| createdAt | timestamp | yes | |

### 11. group_deals/{offerId}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| businessId | string | yes | |
| participantUids | array | yes | |
| minParticipants | number | yes | |
| maxParticipants | number | yes | |
| currentCount | number | yes | |
| status | string | yes | open/success/failed |
| expiresAt | timestamp | yes | |
| createdAt | timestamp | yes | |

### 12. categories/{slug}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| name | string | yes | |
| icon | string | yes | Emoji |
| order | number | yes | |
| active | bool | yes | |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |
| createdBy | string | yes | FK users.uid |

### 13. countries/{code}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| code | string | yes | ISO |
| name | string | yes | |
| flag | string | yes | Emoji |
| currency | string | yes | |
| locale | string | yes | |
| order | number | yes | |
| active | bool | yes | |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |
| createdBy | string | yes | |

### 14. zones/{slug}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| countryCode | string | yes | FK countries.code |
| name | string | yes | |
| slug | string | yes | |
| order | number | yes | |
| active | bool | yes | |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |
| createdBy | string | yes | |

### 15. areas/{slug}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| zoneSlug | string | yes | FK zones.slug |
| name | string | yes | |
| slug | string | yes | |
| agencyUid | string | no | FK agencies.id |
| order | number | yes | |
| active | bool | yes | |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |
| createdBy | string | yes | |

### 16. agencies/{id}
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| ownerUid | string | yes | FK users.uid |
| name | string | yes | |
| email | string | yes | |
| phone | string | yes | |
| areaIds | array | yes | Area slugs |
| countryCode | string | yes | |
| zoneSlug | string | yes | |
| revenueShare | number | yes | Default 0.40 |
| status | string | yes | active/suspended/pending |
| contractStart | timestamp | no | |
| contractEnd | timestamp | no | |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |

## 🔮 FUTURE COLLECTIONS (PHASE C/D)
- plans/{id}, subscriptions/{id}, payments/{id}
- revenue_transactions/{id}, agency_payouts/{id}
- staff/{uid}
- customer_behavior/{id}, category_stats/{id}
- ad_campaigns/{id}, ad_impressions/{id}

## 🎯 DENORMALIZATION STRATEGY
Intentionally denormalized fields for performance:
| Source | To | Field |
|--------|-----|-------|
| businesses.name | offers | businessName |
| businesses.id | claims | businessId |
| businesses.name | claims | businessName |
| offers.title | claims | offerTitle |
| offers.prices | claims | originalPrice/offerPrice (snapshot) |
| users.displayName | reviews | userName |
| offers.areaId | offers | areaId |

## 🔐 ROLE SYSTEM (6 tiers)
1. super_admin — Everything
2. admin — Country/State
3. agency — One area
4. moderator — Reviews/offers/users
5. business — Own shop
6. customer — Shopping

## 📊 INDEX SUMMARY
Total composite indexes: 17
- offers: 6, claims: 4, reviews: 3, referrals: 2
- notifications: 1, saved_offers: 1, saved_businesses: 1
Config: firestore.indexes.json

END OF SCHEMA

═══════════════════════════════════════════════════════
## 💰 REVENUE COLLECTIONS (C2 — October 2026)
═══════════════════════════════════════════════════════

### plans/{id}
ID = slug (free/starter/growth/pro)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| name | string | yes | Display name |
| priceMonthly | number | yes | 0 for free |
| currency | string | yes | QAR/INR |
| offersPerMonth | number | yes | -1 = unlimited |
| features | array | yes | Feature list |
| order | number | yes | Sort order |
| active | bool | yes | |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |

**Seeded plans:** free, starter, growth, pro
**Security:** read public, write admin, delete super_admin

---

### subscriptions/{id}
Auto-generated ID

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| businessId | string | yes | FK businesses.id |
| ownerUid | string | yes | FK users.uid |
| planId | string | yes | FK plans.id |
| status | string | yes | active/expired/cancelled/trial |
| startedAt | timestamp | yes | |
| expiresAt | timestamp | yes | |
| autoRenew | bool | yes | Default true |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |

**Security:** read admin/mod/owner, write admin

---

### payments/{id}
Manual entry by admin

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| businessId | string | yes | FK businesses.id |
| businessName | string | yes | Denormalized |
| ownerUid | string | yes | FK users.uid |
| subscriptionId | string | no | FK subscriptions.id |
| amount | number | yes | |
| currency | string | yes | QAR/INR |
| method | string | yes | cash/bank_transfer/qpay/stripe |
| type | string | yes | subscription/per_offer/commission |
| status | string | yes | pending/completed/failed/refunded |
| paidAt | timestamp | yes | |
| periodStart | timestamp | no | |
| periodEnd | timestamp | no | |
| notes | string | no | |
| recordedBy | string | yes | FK users.uid |
| createdAt | timestamp | yes | |

**Indexes:** businessId+paidAt DESC, status+paidAt DESC, type+paidAt DESC, currency+paidAt DESC
**Security:** read admin/mod, write admin/mod, delete admin

---

### revenue_transactions/{id}
Unified revenue log

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| source | string | yes | subscription/per_offer/commission/ad |
| businessId | string | no | FK businesses.id |
| agencyUid | string | no | FK agencies.id |
| amount | number | yes | Gross |
| currency | string | yes | |
| migoShare | number | yes | MIGO cut |
| agencyShare | number | yes | Agency cut |
| referralShare | number | yes | Referrer cut |
| paymentId | string | no | FK payments.id |
| periodMonth | string | no | "2026-10" |
| createdAt | timestamp | yes | |

**Indexes:** source+createdAt DESC, agencyUid+periodMonth, businessId+createdAt DESC
**Security:** read admin/mod, write admin/mod, delete admin

---

### agency_payouts/{id}
Auto-generated ID

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| agencyUid | string | yes | FK agencies.id |
| agencyName | string | yes | Denormalized |
| amount | number | yes | |
| currency | string | yes | |
| periodMonth | string | yes | "2026-10" |
| status | string | yes | pending/processing/paid/failed |
| method | string | no | bank_transfer/cash |
| paidAt | timestamp | no | |
| reference | string | no | |
| notes | string | no | |
| createdAt | timestamp | yes | |
| updatedAt | timestamp | yes | |

**Security:** read admin/own-agency, write admin, delete super_admin

═══════════════════════════════════════════════════════
END OF REVENUE SECTION
═══════════════════════════════════════════════════════
