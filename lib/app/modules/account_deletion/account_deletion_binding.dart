import 'package:get/get.dart';

import 'account_deletion_controller.dart';

class AccountDeletionBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<AccountDeletionController>(AccountDeletionController.new),
  ];
}
