part of controllers;

class ProductDetailsController extends GetxController {
  late final Product product;
  @override
  void onInit() {
    super.onInit();
    product = Get.arguments;
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
