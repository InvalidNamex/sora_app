import 'package:get/get.dart';

import 'affiliate_management_controller.dart';

class AffiliateManagementBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        Bind.lazyPut<AffiliateManagementController>(
            () => AffiliateManagementController()),
      ];
}
