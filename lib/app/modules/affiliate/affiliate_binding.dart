import 'package:get/get.dart';

import 'affiliate_controller.dart';

class AffiliateBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<AffiliateController>(() => AffiliateController()),
      ];
}
