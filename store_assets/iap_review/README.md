# App Store Connect IAP review screenshots

1320x2868 PNG, RGB (no alpha), plain app screens (English, dark theme, iOS
profile insets, no captions/frames). Demo data only.

- credits.png   Buy credits, top: balance, packs 1-3 (+ start of Maks Paket)
- credits_2.png Buy credits, scrolled to end: Plus/Maks/Mega packs ($17.99/$39.99/$74.99), "How credits work"
  (all five packs cannot fit one screen; the two files together show all five)
- pro.png       Pro subscription (free user, iOS): plan "Aylik Pro" $19.99 / per month, Subscribe,
  auto-renew + Apple ID note, Manage subscription, Restore purchases, Privacy Policy / Terms of Use
- pro_top.png   Pro screen top: hero, benefits, start of Free vs Pro table (extra)

Regenerate:

    IAP_REVIEW=1 STORE_SHOT_PROFILE=ios flutter test test/store_screenshots/iap_review_test.dart
    python tool/iap_review_finalize.py
    rm -r store_assets/iap_review/raw
