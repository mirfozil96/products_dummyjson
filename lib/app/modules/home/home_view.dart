part of views;

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: true,
        backgroundColor: Colors.black87,
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const AppLoader()
            : ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                physics: const BouncingScrollPhysics(),
                itemCount: controller.products.length,
                itemBuilder: (context, index) {
                  final currentProduct = controller.products[index];
                  return InkWell(
                      onTap: () {
                        Get.toNamed(Routes.PRODUCT_DETAILS,
                            arguments: currentProduct);
                      },
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          border: Border.all(color: Colors.black54),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Hero(
                                  tag: currentProduct.id,
                                  child: FadeInImage.assetNetwork(
                                    image: currentProduct.thumbnail,
                                    placeholder:
                                        "assets/product-placeholder.png",
                                    width: 120,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    placeholderErrorBuilder:
                                        (context, error, stackTrace) {
                                      return const SizedBox(
                                        width: 120,
                                        height: 110,
                                      );
                                    },
                                    imageErrorBuilder:
                                        (context, error, stackTrace) {
                                      return const SizedBox(
                                        width: 120,
                                        height: 110,
                                      );
                                    },
                                  )),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentProduct.title,
                                  maxLines: 1,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "\$" + currentProduct.price.toString(),
                                  maxLines: 2,
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  currentProduct.description,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ))
                          ],
                        ),
                      ));
                },
              ),
      ),
    );
  }
}
