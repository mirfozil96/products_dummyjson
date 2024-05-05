import 'package:get/get.dart';

import '../modules/bindings.dart';
import '../modules/views.dart';

// ignore_for_file: constant_identifier_names

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
      children: [
        GetPage(
          name: _Paths.PRODUCT_DETAILS,
          page: () => const ProductDetailsView(),
          binding: ProductDetailsBinding(),
        ),
      ],
    ),
  ];
}
