import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/data/ticker_api.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/providers/guest_market_provider.dart';
import 'package:kriptoanaliz/providers/store_price_provider.dart';
import 'package:kriptoanaliz/providers/subscription_provider.dart';
import 'package:kriptoanaliz/screens/guest_benefits_screen.dart';
import 'package:kriptoanaliz/screens/subscription_screen.dart';
import 'package:kriptoanaliz/widgets/home/home_sections.dart';

import 'helpers/home_fakes.dart';
import 'helpers/home_harness.dart';

/// What the public `/api/home` returns for a guest: shared parts filled,
/// member-only parts empty.
Map<String, dynamic> publicHomeJson() => fullHomeJson()
  ..['movers'] = <dynamic>[]
  ..['last_analysis'] = null
  ..['credits'] = null;

const _freeMember = Member(
  id: 1,
  name: 'Ayse',
  email: 'a@b.c',
  role: 'user',
  creditBalance: 80,
);
const _proMember = Member(
  id: 1,
  name: 'Ayse',
  email: 'a@b.c',
  role: 'pro',
  creditBalance: 80,
);

Future<AppLocalizations> _l10n(String locale) =>
    AppLocalizations.delegate.load(Locale(locale));

void main() {
  group('guest home uses the public /home with the same sections', () {
    testWidgets('same sections as members, member-only ones locked', (
      tester,
    ) async {
      final h = await pumpHome(
        tester,
        member: null,
        handler: okHome(publicHomeJson()),
      );
      expect(h.api.publicCalls, 1);
      expect(h.api.calls, 0, reason: 'no token-bound call for guests');
      final l10n = await _l10n('en');

      // Sign-in prompt replaces the credits band.
      expect(find.text(l10n.homeGuestUnlock), findsOneWidget);
      // Same shared sections as the signed-in page.
      expect(find.text('Fear & Greed'), findsOneWidget);
      expect(find.text('Market'), findsOneWidget);
      expect(find.textContaining('GAIN0'), findsWidgets);
      expect(find.text('Latest signals from Radar'), findsOneWidget);
      expect(find.text('Upcoming events'), findsOneWidget);
      expect(find.text('Term of the day'), findsOneWidget);
      // Member-only sections are locked, not rendered.
      expect(find.byKey(const ValueKey('locked-watchlist')), findsOneWidget);
      expect(find.byKey(const ValueKey('locked-analysis')), findsOneWidget);
      expect(find.text('Your latest deep analysis'), findsOneWidget);
      expect(find.text('Open my watchlist'), findsNothing);
      expect(find.text('Short-term pressure remains downward.'), findsNothing);
      // Quick actions exist, account-only ones carry a lock.
      expect(find.byKey(const ValueKey('quick-deep')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-alerts')), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      // No Pro upsell for guests.
      expect(find.byKey(const ValueKey('home-pro-promo')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('layout order matches the member page', (tester) async {
      await pumpHome(tester, member: null, handler: okHome(publicHomeJson()));
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      final order = [
        y('Sign in to unlock analysis, watchlist and alerts'),
        y('Fear & Greed'),
        y('Market'),
        y('My watchlist'),
        y('Latest signals from Radar'),
        y('Your latest deep analysis'),
        y('Upcoming events'),
        y('Term of the day'),
      ];
      final sorted = [...order]..sort();
      expect(order, sorted);
    });

    for (final locked in [
      const ValueKey('locked-watchlist'),
      const ValueKey('locked-analysis'),
      const ValueKey('quick-deep'),
      const ValueKey('quick-alerts'),
      const ValueKey('guest-card-benefits'),
    ]) {
      testWidgets('tapping $locked opens the benefits page', (tester) async {
        await pumpHome(tester, member: null, handler: okHome(publicHomeJson()));
        final target = find.byKey(locked);
        await tester.ensureVisible(target);
        await tester.pump();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(find.byType(GuestBenefitsScreen), findsOneWidget);
      });
    }

    testWidgets('falls back to the exchange ticker when /home fails', (
      tester,
    ) async {
      final h = await pumpHome(
        tester,
        member: null,
        handler: () => Future.error(Exception('401')),
        // Replaces the harness default (null) with usable ticker data.
        guestMarket: guestMarketProvider.overrideWith(
          (ref) async => buildGuestMarket(const {
            'BTCUSDT': TickerQuote(
              lastPrice: 82000,
              changePercent: 1.2,
              quoteVolume: 9e9,
            ),
            'ETHUSDT': TickerQuote(
              lastPrice: 3000,
              changePercent: 4.5,
              quoteVolume: 5e9,
            ),
          }),
        ),
      );
      expect(h.api.publicCalls, 1);
      expect(find.textContaining('ETH'), findsWidgets);
      expect(find.byKey(const ValueKey('locked-watchlist')), findsOneWidget);
      expect(find.byType(HomeErrorCard), findsNothing);
    });

    testWidgets('an empty public payload also falls back', (tester) async {
      final json = emptyHomeJson()..['credits'] = null;
      await pumpHome(
        tester,
        member: null,
        handler: okHome(json),
        guestMarket: guestMarketProvider.overrideWith(
          (ref) async => buildGuestMarket(const {
            'ETHUSDT': TickerQuote(
              lastPrice: 3000,
              changePercent: 4.5,
              quoteVolume: 5e9,
            ),
          }),
        ),
      );
      expect(find.textContaining('ETH'), findsWidgets);
    });

    testWidgets('error card with retry when both sources fail', (tester) async {
      await pumpHome(
        tester,
        member: null,
        handler: () => Future.error(Exception('x')),
        guestMarket: guestMarketProvider.overrideWith(
          (ref) async => throw Exception('x'),
        ),
      );
      expect(find.byType(HomeErrorCard), findsOneWidget);
      // The sign-in prompt stays usable.
      expect(find.text('Log in / Sign up'), findsOneWidget);
    });

    for (final locale in ['en', 'tr', 'es']) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        testWidgets('no overflow at 360dp / 1.6x ($locale, $brightness)', (
          tester,
        ) async {
          await pumpHome(
            tester,
            member: null,
            locale: locale,
            brightness: brightness,
            textScale: 1.6,
            size: const Size(360, 780),
            handler: okHome(publicHomeJson()),
          );
          expect(tester.takeException(), isNull);
          final list = find.byType(ListView).first;
          for (var i = 0; i < 6; i++) {
            await tester.drag(list, const Offset(0, -700));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  });

  group('Pro upgrade card', () {
    testWidgets('free member sees it prominently below the credits band', (
      tester,
    ) async {
      final h = await pumpHome(
        tester,
        member: _freeMember,
        handler: okHome(fullHomeJson()),
        extraOverrides: [
          subscriptionPlanListProvider.overrideWith((ref) async => []),
          storePricesProvider.overrideWith((ref, ids) async => {}),
        ],
      );
      final promo = find.byKey(const ValueKey('home-pro-promo'));
      expect(promo, findsOneWidget);
      expect(find.text('Upgrade to Pro'), findsOneWidget);
      expect(find.text('See Pro benefits'), findsOneWidget);
      // Below the band, above the market sections.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('home-credits-chip'))).dy,
        lessThan(tester.getTopLeft(promo).dy),
      );
      expect(
        tester.getTopLeft(promo).dy,
        lessThan(tester.getTopLeft(find.text('Fear & Greed')).dy),
      );
      expect(h.api.publicCalls, 0);

      await tester.tap(promo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SubscriptionScreen), findsOneWidget);
    });

    testWidgets('Pro member does not see it', (tester) async {
      final json = fullHomeJson()
        ..['credits'] = {'balance': 300, 'is_pro': true};
      await pumpHome(tester, member: _proMember, handler: okHome(json));
      expect(find.byKey(const ValueKey('home-pro-promo')), findsNothing);
      expect(find.text('Upgrade to Pro'), findsNothing);
    });

    testWidgets('guest sees the sign-in prompt instead', (tester) async {
      await pumpHome(tester, member: null, handler: okHome(publicHomeJson()));
      expect(find.byKey(const ValueKey('home-pro-promo')), findsNothing);
      expect(find.text('Log in / Sign up'), findsOneWidget);
    });

    for (final locale in ['en', 'tr', 'es']) {
      testWidgets('free member card fits at 360dp / 1.6x ($locale)', (
        tester,
      ) async {
        await pumpHome(
          tester,
          member: _freeMember,
          locale: locale,
          textScale: 1.6,
          size: const Size(360, 780),
          handler: okHome(fullHomeJson()),
        );
        expect(find.byKey(const ValueKey('home-pro-promo')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
