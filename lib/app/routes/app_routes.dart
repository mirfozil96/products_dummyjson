part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const PRODUCT_DETAILS = _Paths.HOME + _Paths.PRODUCT_DETAILS;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const PRODUCT_DETAILS = '/product-details';
}
