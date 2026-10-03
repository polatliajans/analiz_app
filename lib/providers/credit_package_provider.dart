import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/credit_package_api.dart';
import '../data/purchase_api.dart';
import '../models/credit_package.dart';

final creditPackageApiProvider = Provider<CreditPackageApi>((ref) => CreditPackageApi());
final purchaseApiProvider = Provider<PurchaseApi>((ref) => PurchaseApi());

final creditPackageListProvider = FutureProvider<List<CreditPackage>>((ref) async {
  return ref.read(creditPackageApiProvider).fetchActivePackages();
});
