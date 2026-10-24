import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kriptoanaliz/ads/ads_controller.dart';
import 'package:kriptoanaliz/l10n/app_localizations.dart';
import 'package:kriptoanaliz/models/credit_breakdown.dart';
import 'package:kriptoanaliz/models/credit_package.dart';
import 'package:kriptoanaliz/models/home_data.dart';
import 'package:kriptoanaliz/models/member.dart';
import 'package:kriptoanaliz/models/subscription_plan.dart';
import 'package:kriptoanaliz/providers/auth_provider.dart';
import 'package:kriptoanaliz/providers/credit_package_provider.dart';
import 'package:kriptoanaliz/providers/subscription_provider.dart';
import 'package:kriptoanaliz/screens/account_screen.dart';
import 'package:kriptoanaliz/screens/credit_packages_screen.dart';
import 'package:kriptoanaliz/screens/subscription_screen.dart';
import 'package:kriptoanaliz/widgets/credit_summary.dart';
import 'package:kriptoanaliz/widgets/insufficient_credit_dialog.dart';

import 'helpers/home_fakes.dart';

// Noon, 12 calendar days ahead in local time: the "N days left" count is calendar-day based, so a
// time-of-day dependent value (now + 12d 3h) made these tests fail late in the evening.
final _renew = (() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + 12, 12).toUtc();
})();

Map<String, dynamic> _memberJson([Map<String, dynamic> extra = const {}]) => {
  'id': 1,
  'email': 'a@b.c',
  'role': 'free',
  'credit_balance': 25,
  ...extra,
};

Member _member({CreditBreakdown credits = CreditBreakdown.none}) => Member(
  id: 1,
  email: 'a@b.c',
  role: 'free',
  creditBalance: 25,
  credits: credits,
);

CreditBreakdown get _full => CreditBreakdown(
  planCredits: 4,
  planCreditTotal: 10,
  purchasedCredits: 21,
  renewAt: _renew,
);

class _NoAds extends AdsController {
  @override
  AdsState build() => const AdsState();
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Member? member,
  Brightness brightness = Brightness.light,
  String locale = 'tr',
  double textScale = 1.0,
  Size size = const Size(360, 740),
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => FakeAuth(member ?? _member())),
        adsControllerProvider.overrideWith(_NoAds.new),
        ...overrides,
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
          brightness: brightness,
        ),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('model parsing', () {
    test('full payload', () {
      final m = Member.fromJson(
        _memberJson({
          'plan_credits': 4,
          'plan_credit_total': 10,
          'purchased_credits': 21,
          'credits_renew_at': '2026-11-05T00:00:00Z',
        }),
      );
      expect(m.creditBalance, 25);
      expect(m.credits.planCredits, 4);
      expect(m.credits.planCreditTotal, 10);
      expect(m.credits.purchasedCredits, 21);
      expect(m.credits.renewAt, DateTime.utc(2026, 11, 5));
      expect(m.credits.planFraction, closeTo(0.4, 1e-9));
    });

    test('partial payload (only package amount + renew)', () {
      final m = Member.fromJson(
        _memberJson({
          'plan_credit_total': 300,
          'credits_renew_at': '2026-11-05T10:00:00+03:00',
        }),
      );
      expect(m.credits.hasPlan, isFalse);
      expect(m.credits.planCreditTotal, 300);
      expect(m.credits.renewAt, DateTime.utc(2026, 11, 5, 7));
      expect(m.credits.planFraction, isNull);
    });

    test('old server: nothing present', () {
      final m = Member.fromJson(_memberJson());
      expect(m.credits.isEmpty, isTrue);
    });

    test('garbage values are ignored, nested credits object accepted', () {
      final m = Member.fromJson(
        _memberJson({
          'plan_credits': 'x',
          'credits_renew_at': 'not a date',
          'credits': {'purchased_credits': 7},
        }),
      );
      expect(m.credits.planCredits, isNull);
      expect(m.credits.renewAt, isNull);
      expect(m.credits.purchasedCredits, 7);
    });

    test('HomeCredits carries the breakdown, old payload stays valid', () {
      final c = HomeCredits.tryParse({
        'balance': 25,
        'is_pro': false,
        'plan_credits': 4,
        'plan_credit_total': 10,
        'purchased_credits': 21,
        'credits_renew_at': '2026-11-05T00:00:00Z',
      })!;
      expect(c.balance, 25);
      expect(c.breakdown.planCredits, 4);
      expect(c.breakdown.purchasedCredits, 21);
      final old = HomeCredits.tryParse({'balance': 3, 'is_pro': true})!;
      expect(old.breakdown.isEmpty, isTrue);
    });

    test('daysUntilRenewal counts calendar days and never goes negative', () {
      final now = DateTime(2026, 10, 24, 23, 0);
      final b = CreditBreakdown(renewAt: DateTime(2026, 11, 5, 12).toUtc());
      expect(b.daysUntilRenewal(now), 12);
      expect(
        CreditBreakdown(
          renewAt: DateTime(2026, 10, 1).toUtc(),
        ).daysUntilRenewal(now),
        0,
      );
      expect(CreditBreakdown.none.daysUntilRenewal(now), isNull);
    });

    test('setCreditBalance drops the stale split, keeps package/renewal', () {
      final c = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => FakeAuth(_member(credits: _full))),
        ],
      );
      addTearDown(c.dispose);
      c.read(authProvider.notifier).setCreditBalance(20);
      final m = c.read(authProvider).member!;
      expect(m.creditBalance, 20);
      expect(m.credits.planCredits, isNull);
      expect(m.credits.planCreditTotal, 10);
      expect(m.credits.renewAt, _renew);
    });
  });

  group('packages screen card', () {
    final overrides = [
      creditPackageListProvider.overrideWith(
        (ref) async => const <CreditPackage>[],
      ),
    ];

    testWidgets('shows values, progress, renewal and policy (tr)', (t) async {
      await _pump(
        t,
        const CreditPackagesScreen(),
        member: _member(credits: _full),
        overrides: overrides,
      );
      expect(find.text('Kredilerin'), findsOneWidget);
      expect(find.text('Toplam: 25'), findsOneWidget);
      expect(find.text('Aylık krediler 4 / 10'), findsOneWidget);
      expect(
        t
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('creditSummaryProgress')),
            )
            .value,
        closeTo(0.4, 1e-9),
      );
      expect(find.textContaining('Yenilenme:'), findsOneWidget);
      expect(find.textContaining('12 gün sonra'), findsOneWidget);
      expect(
        find.text('Satın alınan krediler 21 — süresiz geçerli'),
        findsOneWidget,
      );
      expect(
        find.textContaining('paketindeki kredi sayısına (10) tamamlanır'),
        findsOneWidget,
      );
      expect(
        find.textContaining('önce aylık krediler harcanır'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('old server: total + generic policy only', (t) async {
      await _pump(
        t,
        const CreditPackagesScreen(),
        member: _member(),
        overrides: overrides,
      );
      expect(find.text('Toplam: 25'), findsOneWidget);
      expect(find.byKey(const Key('creditSummaryMonthly')), findsNothing);
      expect(find.byKey(const Key('creditSummaryProgress')), findsNothing);
      expect(find.byKey(const Key('creditSummaryRenewal')), findsNothing);
      expect(find.byKey(const Key('creditSummaryPurchased')), findsNothing);
      expect(find.textContaining('(Ücretsiz: 10, Pro: 300)'), findsOneWidget);
    });

    testWidgets('english and spanish render', (t) async {
      await _pump(
        t,
        const CreditPackagesScreen(),
        member: _member(credits: _full),
        locale: 'en',
        overrides: overrides,
      );
      expect(find.text('Monthly credits 4 / 10'), findsOneWidget);
      expect(find.textContaining('in 12 days'), findsOneWidget);
      await _pump(
        t,
        const CreditPackagesScreen(),
        member: _member(credits: _full),
        locale: 'es',
        overrides: overrides,
      );
      expect(find.text('Créditos mensuales 4 / 10'), findsOneWidget);
    });

    for (final dark in [false, true]) {
      testWidgets('no overflow at 360dp / 1.6x (dark=$dark)', (t) async {
        await _pump(
          t,
          const CreditPackagesScreen(),
          member: _member(credits: _full),
          brightness: dark ? Brightness.dark : Brightness.light,
          textScale: 1.6,
          overrides: overrides,
        );
        expect(t.takeException(), isNull);
        expect(find.text('Kredilerin'), findsOneWidget);
      });
    }
  });

  group('subscription screen', () {
    testWidgets('plan line uses the real amount, no overflow', (t) async {
      await _pump(
        t,
        const SubscriptionScreen(),
        textScale: 1.6,
        overrides: [
          subscriptionPlanListProvider.overrideWith(
            (ref) async => [
              const SubscriptionPlan(
                id: 1,
                name: 'Pro',
                price: '99',
                durationDays: 30,
                monthlyCredit: 300,
              ),
            ],
          ),
        ],
      );
      expect(
        find.textContaining(
          'Her ay 300 kredi · devretmez, yenilenme gününde 300 krediye tamamlanır',
        ),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
  });

  group('compact summary (account)', () {
    testWidgets('policy line + monthly split, dark, 1.6x', (t) async {
      await _pump(
        t,
        Scaffold(
          body: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CreditSummary(
                member: _member(credits: _full),
                compact: true,
              ),
            ),
          ),
        ),
        brightness: Brightness.dark,
        textScale: 1.6,
      );
      expect(find.text('Aylık krediler 4 / 10'), findsOneWidget);
      expect(find.textContaining('Aylık krediler devretmez'), findsOneWidget);
      expect(find.byKey(const Key('creditSummaryTotal')), findsNothing);
      expect(t.takeException(), isNull);
    });
  });

  group('insufficient credit dialog line', () {
    Future<void> open(WidgetTester t, Member m) async {
      await _pump(
        t,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showInsufficientCreditDialog(context),
            child: const Text('open'),
          ),
        ),
        member: m,
        locale: 'en',
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    testWidgets('renewal soon -> renewal date line', (t) async {
      final soon = DateTime.now().toUtc().add(const Duration(days: 3));
      await open(
        t,
        _member(credits: CreditBreakdown(purchasedCredits: 5, renewAt: soon)),
      );
      expect(
        find.textContaining('Your monthly credits renew on'),
        findsOneWidget,
      );
      expect(find.textContaining('never expire'), findsNothing);
    });

    testWidgets('purchased credits, renewal far -> reminder line', (t) async {
      await open(t, _member(credits: _full));
      expect(
        find.text('Your 21 purchased credits never expire.'),
        findsOneWidget,
      );
    });

    testWidgets('nothing known -> no line', (t) async {
      await open(t, _member());
      expect(find.byKey(const Key('creditRenewalNote')), findsNothing);
    });
  });

  accountTests();

  test('monthly_reset gets a friendly label, unknown types do not', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    expect(
      creditTransactionLabel(l10n, 'monthly_reset'),
      'Aylık kredi yenileme',
    );
    expect(creditTransactionLabel(l10n, 'purchase'), isNull);
  });
}

void accountTests() {
  testWidgets('account screen shows the split and the short policy', (t) async {
    await _pump(
      t,
      const AccountScreen(),
      member: _member(credits: _full),
      textScale: 1.6,
    );
    expect(find.text('Aylık krediler 4 / 10'), findsOneWidget);
    expect(find.textContaining('Aylık krediler devretmez'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
