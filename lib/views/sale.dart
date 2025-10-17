import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobilepos/helpers/printer_helper.dart';
import 'package:mobilepos/models/product.dart';
import 'package:mobilepos/models/sale_response.dart';
import 'package:mobilepos/services/api_service.dart';
import 'package:mobilepos/static/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalePage extends StatefulWidget {
  final List<ProductTemplate> products;
  final List<Category> categories;
  final List<Partner> partners;

  const SalePage({
    super.key,
    required this.products,
    required this.categories,
    required this.partners,
  });

  @override
  State<SalePage> createState() => _SalePageState();
}

/// Cart item stores parent + variant info; variantId == 0 means "no variant"
class CartItem {
  final int parentId;
  final int variantId;
  final String title;
  final double? price;
  final String? currency;
  final String? imageBase64; // base64 encoded image string (data:... or plain base64)
  int qty;

  CartItem({
    required this.parentId,
    required this.variantId,
    required this.title,
    this.price,
    this.currency,
    this.imageBase64,
    this.qty = 1,
  });
}

class _SalePageState extends State<SalePage> {
  String? _selectedCategory; // null = All
  // key: variantId (unique per product product.product id). If variantId = 0 -> parent only
  final Map<int, CartItem> _cart = {};
  Partner? _selectedPartner;
  int? _userId;
  late final ApiService _apiService;
  final MobileScannerController _scannerController = MobileScannerController();
  

  @override
  void initState() {
    super.initState();
    _loadSession();

    final dio = Dio(BaseOptions(baseUrl: api_root_url));
    _apiService = ApiService(dio);
  }

  // new method to load prefs
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userId = prefs.getInt('user_id');
      });
      // optional: debug print
      debugPrint('Loaded prefs: user_id=$_userId');
    } catch (e) {
      debugPrint('Error loading prefs: $e');
    }
  }

  List<ProductTemplate> get _filteredProducts {
    if (_selectedCategory == null || _selectedCategory == 'All') return widget.products;
    return widget.products.where((p) => (p.category ?? '') == _selectedCategory).toList();
  }

  List<String> get _categoryNames {
    final names = <String>['All'];
    for (final c in widget.categories) {
      final n = c.name.trim();
      if (n.isNotEmpty && !names.contains(n)) names.add(n);
    }
    return names;
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final isLandscape = mq.orientation == Orientation.landscape;
    const tabletBreakpoint = 900;
    final isTablet = width >= tabletBreakpoint;
    if (isTablet) return isLandscape ? 6 : 4;
    return isLandscape ? 4 : 2;
  }

  double _calculateChildAspectRatio(BuildContext context, int crossAxisCount) {
    final mq = MediaQuery.of(context);
    final totalWidth = mq.size.width;
    final itemWidth = (totalWidth - 16 - (crossAxisCount - 1) * 8) / crossAxisCount;
    const targetHeight = 200.0;
    return itemWidth / targetHeight;
  }

  // total amount and items
  double get _totalAmount {
    double sum = 0;
    for (final ci in _cart.values) {
      sum += (ci.price ?? 0) * ci.qty;
    }
    return sum;
  }

  int get _totalItems {
    int t = 0;
    for (final ci in _cart.values) t += ci.qty;
    return t;
  }

  // Aggregate quantity across all variants for a parent product
  int _parentQty(int parentId) {
    int q = 0;
    for (final ci in _cart.values) {
      if (ci.parentId == parentId) q += ci.qty;
    }
    return q;
  }

  // Helpers to safely read variant fields (works whether variant is typed or Map)
  int _variantId(dynamic variant) {
    try {
      return (variant as dynamic).id as int;
    } catch (_) {
      return (variant as Map)['id'] as int;
    }
  }

  String _variantName(dynamic variant) {
    try {
      return (variant as dynamic).name?.toString() ?? '';
    } catch (_) {
      return (variant as Map)['name']?.toString() ?? '';
    }
  }

  double? _variantPrice(dynamic variant) {
    try {
      final p = (variant as dynamic).list_price;
      return p is num ? p.toDouble() : null;
    } catch (_) {
      final p = (variant as Map)['list_price'];
      return p is num ? p.toDouble() : null;
    }
  }

  String? _variantCurrency(dynamic variant) {
    try {
      return (variant as dynamic).currency?.toString();
    } catch (_) {
      return (variant as Map)['currency']?.toString();
    }
  }

  String? _variantImage(dynamic variant) {
    try {
      return (variant as dynamic).image?.toString();
    } catch (_) {
      return (variant as Map)['image']?.toString();
    }
  }

  // Add variant to cart (variantId must be unique across all products)
  void _addVariantToCart({
    required int parentId,
    required int variantId,
    required String title,
    double? price,
    String? currency,
    String? imageBase64,
  }) {
    setState(() {
      if (_cart.containsKey(variantId)) {
        _cart[variantId]!.qty += 1;
      } else {
        _cart[variantId] = CartItem(
          parentId: parentId,
          variantId: variantId,
          title: title,
          price: price,
          currency: currency,
          imageBase64: imageBase64,
          qty: 1,
        );
      }
    });
  }

  // Decrease or remove by variantId
  void _decreaseVariant(int variantId) {
    if (!_cart.containsKey(variantId)) return;
    setState(() {
      _cart[variantId]!.qty -= 1;
      if (_cart[variantId]!.qty <= 0) _cart.remove(variantId);
    });
  }

  // UI: open variant picker or add direct
  void _onProductTap(ProductTemplate p) {
    final variants = (p.variants ?? <dynamic>[]);
    if (variants.isEmpty) {
      // treat parent as single item with variantId 0+parentId to avoid clash (use negative key)
      final key = -p.id; // negative parent id means "parent-only"
      _addVariantToCart(
        parentId: p.id,
        variantId: key,
        title: p.name,
        price: p.list_price,
        currency: p.currency,
        imageBase64: p.image,
      );
      return;
    }

    if (variants.length == 1) {
      final v = variants.first;
      final vId = _variantId(v);
      final name = _variantName(v);
      final price = _variantPrice(v) ?? p.list_price;
      final currency = _variantCurrency(v) ?? p.currency;
      final image = _variantImage(v) ?? p.image;
      _addVariantToCart(parentId: p.id, variantId: vId, title: name, price: price, currency: currency, imageBase64: image);
      return;
    }

    // multiple variants - show bottom sheet to select
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 6, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Select Variant', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: variants.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final v = variants[i];
                    final vId = _variantId(v);
                    final name = _variantName(v);
                    final price = _variantPrice(v) ?? p.list_price;
                    final currency = _variantCurrency(v) ?? p.currency;
                    final image = _variantImage(v) ?? p.image;
                    return ListTile(
                      leading: _buildImageFromBase64(image, width: 48, height: 48),
                      title: Text(name),
                      subtitle: Text(price != null ? '${price.toString()} ${currency ?? ''}' : 'Price N/A'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _addVariantToCart(parentId: p.id, variantId: vId, title: name, price: price, currency: currency, imageBase64: image);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build an Image widget from a base64 string. Accepts data URI or raw base64.
  Widget _buildImageFromBase64(String? base64String, {double? width=54, double? height=54}) {
    const defaultIcon = Icon(Icons.broken_image, size: 48, color: Colors.grey);

    if (base64String == null || base64String.trim().isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(child: defaultIcon),
      );
    }

    try {
      // Handle data URI prefix
      final commaIndex = base64String.indexOf(',');
      final payload = (commaIndex >= 0) ? base64String.substring(commaIndex + 1) : base64String;
      final bytes = base64Decode(payload);

      // If decoded successfully, show the image
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(child: defaultIcon),
      );
    } catch (e) {
      // If decoding fails, show default icon
      return Center(child: defaultIcon);
    }
  }

  ImageProvider? _partnerImageProvider(Partner p) {
    final base64String = p.image;
    if (base64String == null || base64String.trim().isEmpty) return null;
    try {
      final commaIndex = base64String.indexOf(',');
      final payload = (commaIndex >= 0) ? base64String.substring(commaIndex + 1) : base64String;
      final bytes = base64Decode(payload);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  // Cart detail sheet
  void _openCartDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, void Function(void Function()) setModalState) {
            final entries = _cart.entries.toList();
            return SafeArea(
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.6,
                minChildSize: 0.25,
                builder: (context, scrollController) {
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6))),
                        const SizedBox(height: 12),
                        Text('Cart (${_totalItems} items)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: entries.isEmpty
                              ? const Center(child: Text('Cart is empty'))
                              : ListView.separated(
                                  controller: scrollController,
                                  itemCount: entries.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, i) {
                                    final pair = entries[i];
                                    final variantId = pair.key;
                                    final ci = pair.value;
                                    return ListTile(
                                      leading: _buildImageFromBase64(ci.imageBase64, width: 30, height: 30),
                                      title: Text(ci.title),
                                      subtitle: Text('${ci.price?.toStringAsFixed(2) ?? '0.00'} ${ci.currency ?? ''}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () {
                                            setState(() => _decreaseVariant(variantId));
                                            setModalState(() {});
                                          }),
                                          Text('${ci.qty}'),
                                          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
                                            setState(() {
                                              _cart[variantId]!.qty += 1;
                                            });
                                            setModalState(() {});
                                          }),
                                          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {
                                            setState(() => _cart.remove(variantId));
                                            setModalState(() {});
                                          }),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text('Total: ${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _onPayment,
                          icon: const Icon(Icons.payment),
                          label: const Text('Proceed to Payment'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Customer selector
  Future<void> _onCustomer() async {
    final Partner? chosen = await showModalBottomSheet<Partner>(
      context: context,
      builder: (_) {
        final partners = widget.partners;
        return SafeArea(
          child: Column(
            children: [
              Container(width: 48, height: 6, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6))),
              Expanded(
                child: ListView.separated(
                  itemCount: partners.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = partners[i];
                    return ListTile(
                      leading: CircleAvatar(radius: 20, backgroundColor: Colors.grey[200], backgroundImage: _partnerImageProvider(p)),
                      title: Text(p.name),
                      subtitle: Text(p.email ?? ''),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (chosen != null) setState(() => _selectedPartner = chosen);
  }

  // _onPayment method
  Future<void> _onPayment() async {
    // 1) basic checks
    if (_selectedPartner == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a customer first')));
      return;
    }
    if (_userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not found. Please login again.')));
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    // 2) aggregate quantities by parentId
    final Map<int, int> saleOrdersCounts = {};
    for (final ci in _cart.values) {
      saleOrdersCounts.update(ci.variantId, (existing) => existing + ci.qty, ifAbsent: () => ci.qty);
    }

    // 3) convert keys to strings
    final Map<String, int> saleOrdersJson =
        saleOrdersCounts.map((k, v) => MapEntry(k.toString(), v));

    // 4) build payload
    final Map<String, dynamic> rpcPayload = {
      'jsonrpc': '2.0',
      'params': {
        'user_id': _userId,
        'customer_id': _selectedPartner!.id,
        'sale_orders': saleOrdersJson,
      }
    };

    // 5) confirm order with user
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cartEntries = _cart.values.toList();
        return AlertDialog(
          title: const Text('Confirm Order'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cartEntries.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final ci = cartEntries[index];
                      return Row(
                        children: [
                          _buildImageFromBase64(ci.imageBase64, width: 48, height: 48),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ci.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Qty: ${ci.qty} × Unit: ${ci.price?.toStringAsFixed(2) ?? '0.00'}'),
                              ],
                            ),
                          ),
                          Text('${((ci.price ?? 0) * ci.qty).toStringAsFixed(2)}'),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(thickness: 1.2),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_totalAmount.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
          ],
        );
      },
    );

    if (confirm != true) return;

    // 6) send request with loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final SaleOrderResponse resp = await _apiService.createSaleOrder(rpcPayload);
      Navigator.of(context).pop(); // remove loading

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(resp.status.toLowerCase() == 'success' ? 'Order Created' : 'Error'),
          content: SingleChildScrollView(
            child: Text(
              resp.status.toLowerCase() == 'success'
                  ? 'Order successfully created.\n\nPress "Print" to print payslip.\nPress "OK" to not print the payslip.'
                  : 'Order creation failed.\n\nCheck internet or contact support.',
            ),
          ),
          actions: resp.status.toLowerCase() == 'success'
              ? [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // 7) request permission & get printers
                      final printers = await BluetoothHelper.getPairedPrinters();

                      if (printers.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No paired printers found')),
                        );
                        return;
                      }

                      // Show printer selection dialog
                      final selectedPrinter = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Select a Printer'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: printers.length,
                                itemBuilder: (context, index) {
                                  final printer = printers[index];
                                  final name = printer['name'] ?? 'Unknown';
                                  final address = printer['address'] ?? 'N/A';
                                  return ListTile(
                                    title: Text(name),
                                    subtitle: Text(address),
                                    onTap: () => Navigator.of(context).pop(printer),
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );

                      if (selectedPrinter == null) return; // user canceled

                      final printerName = selectedPrinter['name'] ?? 'Unknown';
                      final printerAddress = selectedPrinter['address'];

                      final printConfirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirm Print'),
                          content: Text('Print using "$printerName"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Print'),
                            ),
                          ],
                        ),
                      );

                      if (printConfirm == true && printerAddress != null) {
                        final items = _buildReceiptItemsFromCart();
                        final receipt = generateReceipt(
                          customerName: _selectedPartner?.name ?? 'Customer',
                          products: items,
                          totalAmount: _totalAmount,
                          charPerLine: 48,
                        );

                        final ok = await BluetoothHelper.smartPrint(receipt, address: printerAddress);

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Receipt printed' : 'Printing failed'),
                        ));
                      }


                    },
                    child: const Text('Print'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
        ),
      );

      // 8) clear cart
      if (resp.status.toLowerCase() == 'success') {
        setState(() {
          _cart.clear();
          _selectedPartner = null;
        });
      }
    } catch (e) {
      Navigator.of(context).pop(); // remove loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      print("Error on payment: $e");
    }
  }

  // _onSearchByBarcode method
  void _onSearchByBarcode() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Search by Barcode'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter barcode',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final input = controller.text.trim();
              if (input.isEmpty || int.tryParse(input) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number')),
                );
                return;
              }

              final barcode = int.parse(input);

              // Search product by barcode inside variants
              ProductTemplate? foundProduct;
              ProductVariant? foundVariant;

              for (final product in widget.products) {
                if (product.variants != null) {
                  for (final variant in product.variants!) {
                    if (variant.barcode != null && int.tryParse(variant.barcode.toString()) == barcode) {
                      foundProduct = product;
                      foundVariant = variant;
                      break;
                    }
                  }
                }
                if (foundVariant != null) break;
              }

              Navigator.of(context).pop(); // close dialog

              if (foundProduct == null || foundVariant == null) {
                // show alert if not found
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Product Not Found'),
                    content: Text('No product exists with barcode $barcode'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                    ],
                  ),
                );
              } else {
                // Add variant to cart directly
                _addVariantToCart(
                  parentId: foundProduct.id,
                  variantId: foundVariant.id,
                  title: foundVariant.name,
                  price: foundVariant.list_price ?? foundProduct.list_price,
                  currency: foundVariant.currency ?? foundProduct.currency,
                  imageBase64: foundVariant.image ?? foundProduct.image,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added "${foundVariant.name}" to cart')),
                );
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  // _onScanBarcode method
  void _onScanBarcode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Scan Barcode/QR')),
          body: MobileScanner(
            controller: _scannerController,
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final code = barcodes.first.rawValue;
              if (code == null) return;

              // Stop the camera to avoid black screen
              await _scannerController.stop();

              // Close scanner
              Navigator.of(context).pop();

              // Process the scanned code
              final barcode = int.tryParse(code);
              if (barcode == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scanned code is not a valid number')),
                );
                return;
              }

              // Search product by barcode inside variants
              ProductTemplate? foundProduct;
              ProductVariant? foundVariant;

              for (final product in widget.products) {
                if (product.variants != null) {
                  for (final variant in product.variants!) {
                    if (variant.barcode != null &&
                        int.tryParse(variant.barcode.toString()) == barcode) {
                      foundProduct = product;
                      foundVariant = variant;
                      break;
                    }
                  }
                }
                if (foundVariant != null) break;
              }

              if (foundProduct == null || foundVariant == null) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Product Not Found'),
                    content: Text('No product exists with barcode $barcode'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK')),
                    ],
                  ),
                );
              } else {
                _addVariantToCart(
                  parentId: foundProduct.id,
                  variantId: foundVariant.id,
                  title: foundVariant.name,
                  price: foundVariant.list_price ?? foundProduct.list_price,
                  currency: foundVariant.currency ?? foundProduct.currency,
                  imageBase64: foundVariant.image ?? foundProduct.image,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added "${foundVariant.name}" to cart')),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildReceiptItemsFromCart() {
    return _cart.values.map((ci) {
      final lineAmount = (ci.price ?? 0) * ci.qty;
      return {
        'name': ci.title,
        'qty': ci.qty,
        'amount': lineAmount,
      };
    }).toList();
  }

  /// Generate printable receipt text for a thermal text printer.
  /// - customerName: customer display name
  /// - products: list of maps {name, qty, amount}
  /// - totalAmount: total double
  /// - charPerLine: characters per line (commonly 32 or 48) - adjust for your printer
  String generateReceipt({
    required String customerName,
    required List<Map<String, dynamic>> products,
    required double totalAmount,
    int charPerLine = 32,
  }) {
    final sb = StringBuffer();

    // Basic header (center-ish)
    sb.writeln('Yoma POS Receipt');
    sb.writeln('='.padRight(charPerLine, '='));
    sb.writeln('Customer: $customerName');
    sb.writeln('-'.padRight(charPerLine, '-'));

    // Column headings (adjust if needed)
    // We'll reserve columns: name | qty | amount
    // qtyWidth and amountWidth chosen to fit typical numeric sizes
    final int qtyWidth = 5;         // width for qty column (centered)
    final int amountWidth = 10;     // width for amount column (right aligned)
    final int nameWidth = charPerLine - qtyWidth - amountWidth;

    // Header row
    final headerName = 'Item';
    final headerQty = 'Qty';
    final headerAmt = 'Amt';
    sb.writeln(
      headerName.padRight(nameWidth) +
      _centerText(headerQty, qtyWidth) +
      headerAmt.padLeft(amountWidth),
    );
    sb.writeln('-'.padRight(charPerLine, '-'));

    // Items
    for (final item in products) {
      final name = (item['name'] ?? '').toString();
      final qty = item['qty'] ?? 0;
      final amountVal = (item['amount'] is num) ? (item['amount'] as num).toDouble() : double.tryParse(item['amount'].toString()) ?? 0.0;

      sb.writeln(_formatLine(name, qty, amountVal, nameWidth: nameWidth, qtyWidth: qtyWidth, amountWidth: amountWidth));
    }

    sb.writeln('-'.padRight(charPerLine, '-'));

    // Total line: label left, total amount right
    final totalLabel = 'Total:';
    final totalStr = totalAmount.toStringAsFixed(2);
    final leftPart = totalLabel.padRight(charPerLine - totalStr.length);
    sb.writeln(leftPart + totalStr);

    sb.writeln('='.padRight(charPerLine, '='));
    sb.writeln('Thank you for your purchase!');
    sb.writeln('='.padRight(charPerLine, '='));

    return sb.toString();
  }

  /// Formats a single receipt line with left-aligned name (wrap if too long),
  /// centered qty, and right-aligned amount.
  String _formatLine(String name, dynamic qty, double amount,
      {required int nameWidth, required int qtyWidth, required int amountWidth}) {
    final lines = _wrapText(name, nameWidth);

    final qtyStr = qty.toString();
    final amtStr = amount.toStringAsFixed(2);

    String result = '';
    for (int i = 0; i < lines.length; i++) {
      final namePart = lines[i].padRight(nameWidth);

      // Only show qty and amount on the first line
      final qtyPart = (i == 0) ? _centerText(qtyStr, qtyWidth) : ' ' * qtyWidth;
      final amtPart = (i == 0) ? amtStr.padLeft(amountWidth) : ' ' * amountWidth;

      result += namePart + qtyPart + amtPart + '\n';
    }

    return result.trimRight(); // remove trailing newline
  }

  /// Wrap text into multiple lines according to max width
  List<String> _wrapText(String text, int maxWidth) {
    final List<String> lines = [];
    int start = 0;

    while (start < text.length) {
      final end = (start + maxWidth < text.length) ? start + maxWidth : text.length;
      lines.add(text.substring(start, end));
      start += maxWidth;
    }

    return lines;
  }

  /// Helper: truncate string and add ellipsis if needed
  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    if (maxLen <= 1) return text.substring(0, maxLen);
    return text.substring(0, maxLen - 1) + '…';
  }

  /// Helper: center text in a field of width `w`
  String _centerText(String text, int w) {
    if (text.length >= w) return text.substring(0, w);
    final left = ((w - text.length) / 2).floor();
    final right = w - text.length - left;
    return ' ' * left + text + ' ' * right;
  }


  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _calculateCrossAxisCount(context);
    final childAspectRatio = _calculateChildAspectRatio(context, crossAxisCount);
    final categoryNames = _categoryNames;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: SafeArea(
          child: Column(
            children: [
              // Row 1 - title + icons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: [
                    const Expanded(child: Text('Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.search), onPressed: () {_onSearchByBarcode();}),
                    Stack(
                      children: [
                        IconButton(icon: const Icon(Icons.qr_code), onPressed: () {_onScanBarcode();}),
                        if (_totalItems > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text('$_totalItems', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Row 2 - categories
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryNames.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final name = categoryNames[index];
                    final selected = (_selectedCategory == null && name == 'All') || (_selectedCategory == name);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = (name == 'All') ? null : name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                        child: Center(child: Text(name, style: TextStyle(color: selected ? Colors.white : Colors.black87))),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: widget.products.isEmpty
            ? const Center(child: Text('No products found.'))
            : GridView.builder(
                itemCount: _filteredProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: childAspectRatio),
                itemBuilder: (context, index) {
                  final p = _filteredProducts[index];
                  final int parentQty = _parentQty(p.id);

                  // Determine if single variant (display qty per variant) or multiple
                  final variants = (p.variants ?? <dynamic>[]);
                  int? singleVariantId;
                  if (variants.length == 1) {
                    singleVariantId = _variantId(variants.first);
                  }

                  final singleQty = (singleVariantId != null && _cart.containsKey(singleVariantId)) ? _cart[singleVariantId]!.qty : 0;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _onProductTap(p),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image area
                          Expanded(
                            flex: 6,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              child: _buildImageFromBase64(p.image, width: double.infinity, height: double.infinity),
                            ),
                          ),

                          // Info area
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(p.list_price != null ? '${p.list_price} ${p.currency ?? ''}' : 'Price N/A', style: TextStyle(color: Colors.grey[800])),
                                      if (parentQty > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                                          child: Text('x$parentQty'),
                                        )
                                      else if (singleQty > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                                          child: Text('x$singleQty'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),

      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(_totalAmount.toStringAsFixed(2), style: const TextStyle(fontSize: 18)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _openCartDetail,
                    icon: const Icon(Icons.shopping_cart),
                    label: Text('Cart ($_totalItems)'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(120, 44)),
                  ),
                ],
              ),
            ),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _onCustomer,
                      icon: _selectedPartner != null ? CircleAvatar(radius: 12, backgroundImage: _partnerImageProvider(_selectedPartner!)) : const Icon(Icons.person_outline),
                      label: Text(_selectedPartner?.name ?? 'Customer'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _onPayment,
                      icon: const Icon(Icons.payment),
                      label: const Text('Payment'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
