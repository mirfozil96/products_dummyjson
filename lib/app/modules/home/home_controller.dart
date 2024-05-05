part of '../controllers.dart';

class HomeController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    getProductsApi();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // * API: Products

  RxBool isLoading = false.obs;
  final List<Product> products = [];
  Future<void> getProductsApi({bool handleErrors = true}) async {
    isLoading.value = true;
    final apiHelper = ApiHelper(
      serviceName: "Products",
      endPoint: ApiPaths.products,
      showErrorDialog: handleErrors,
    );
    final result = await apiHelper.get();
    result.fold((l) {
      Log.error(l);
    }, (r) {
      try {
        products.clear();
        products.addAll(ProductsModel.fromJson(r).products);
      } catch (error, stack) {
        // FirebaseCrashlytics.instance.recordError(error, stack);
      }
    });
    isLoading.value = false;
  }
}
