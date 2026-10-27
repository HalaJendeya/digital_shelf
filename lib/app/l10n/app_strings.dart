import 'package:flutter/widgets.dart';

import '../../core/error/app_exception.dart';

/// UI strings for Arabic and English. Server content (product names, error
/// messages) is already localized through the `Accept-Language` header.
class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;
  bool get _ar => languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;

  static AppStrings of(BuildContext context) => AppStrings(Localizations.localeOf(context).languageCode);

  // Navigation
  String get home => _t('الرئيسية', 'Home');
  String get categories => _t('الأقسام', 'Categories');
  String get cart => _t('السلة', 'Cart');
  String get account => _t('حسابي', 'Account');
  String get search => _t('بحث', 'Search');
  String get favorites => _t('المفضلة', 'Favorites');
  String get orders => _t('طلباتي', 'My orders');

  // Common
  String get retry => _t('إعادة المحاولة', 'Retry');
  String get seeAll => _t('عرض الكل', 'See all');
  String get cancel => _t('إلغاء', 'Cancel');
  String get confirm => _t('تأكيد', 'Confirm');
  String get save => _t('حفظ', 'Save');
  String get close => _t('إغلاق', 'Close');
  String get loading => _t('جارٍ التحميل…', 'Loading…');
  String get requiredField => _t('هذا الحقل مطلوب', 'This field is required');
  String get language => _t('اللغة', 'Language');
  String get arabic => 'العربية';
  String get english => 'English';

  // Errors
  String get networkError => _t(
    'تعذّر الاتصال بالإنترنت. تحقق من الشبكة وحاول مجددًا.',
    'No internet connection. Check your network and try again.',
  );
  String get timeoutError =>
      _t('استغرق الخادم وقتًا طويلًا. حاول مجددًا.', 'The server took too long to respond. Please try again.');
  String get serverError =>
      _t('حدث خطأ في الخادم. حاول لاحقًا.', 'Something went wrong on the server. Please try later.');
  String get unknownError => _t('حدث خطأ غير متوقع.', 'Something unexpected happened.');
  String get sessionExpired =>
      _t('انتهت الجلسة، سجّل الدخول مجددًا.', 'Your session has expired. Please sign in again.');

  String errorMessage(Object error) {
    if (error is AppException) {
      switch (error.type) {
        case AppErrorType.network:
          return networkError;
        case AppErrorType.timeout:
          return timeoutError;
        case AppErrorType.server:
          return error.message.isNotEmpty ? error.message : serverError;
        case AppErrorType.unauthorized:
          return error.message.isNotEmpty ? error.message : sessionExpired;
        case AppErrorType.validation:
          // The envelope message is generic ("The given data was invalid");
          // the actionable text is in the field details.
          final first = error.fieldErrors.values.expand((m) => m).firstOrNull;
          return first ?? (error.message.isNotEmpty ? error.message : unknownError);
        default:
          return error.message.isNotEmpty ? error.message : unknownError;
      }
    }
    return unknownError;
  }

  // Splash
  String get connecting => _t('جارٍ تجهيز المتجر…', 'Preparing the store…');
  String get serverUnavailable => _t('الخادم غير متاح حاليًا.', 'The server is unavailable.');

  // Home
  String get featured => _t('مختارات مميزة', 'Featured');
  String get newArrivals => _t('وصل حديثًا', 'New arrivals');
  String get bestSellers => _t('الأكثر مبيعًا', 'Best sellers');
  String get searchHint => _t('ابحث عن كتاب أو مؤلف…', 'Search books or authors…');
  String get storeEmpty => _t('لا توجد منتجات بعد.', 'No products yet.');

  // Categories / listing
  String get allProducts => _t('كل المنتجات', 'All products');
  String productsCount(int n) => _t('$n منتج', n == 1 ? '1 product' : '$n products');
  String get noProducts => _t('لا توجد منتجات مطابقة.', 'No matching products.');
  String get noCategories => _t('لا توجد أقسام.', 'No categories.');

  // Product
  String get inStock => _t('متوفر', 'In stock');
  String get outOfStock => _t('غير متوفر', 'Out of stock');
  String onlyLeft(int n) => _t('بقي $n فقط', 'Only $n left');
  String get addToCart => _t('أضف إلى السلة', 'Add to cart');
  String get addedToCart => _t('تمت الإضافة إلى السلة', 'Added to cart');
  String get viewCart => _t('عرض السلة', 'View cart');
  String get description => _t('الوصف', 'Description');
  String get details => _t('التفاصيل', 'Details');
  String get related => _t('منتجات مشابهة', 'Related products');
  String get quantity => _t('الكمية', 'Quantity');
  String selectOption(String name) => _t('اختر $name', 'Select $name');

  // Reviews
  String get reviews => _t('التقييمات', 'Reviews');
  String reviewsCount(int n) => _t('$n تقييم', n == 1 ? '1 review' : '$n reviews');
  String get noReviews => _t('لا توجد تقييمات بعد.', 'No reviews yet.');
  String get writeReview => _t('اكتب تقييمًا', 'Write a review');
  String get yourRating => _t('تقييمك', 'Your rating');
  String get comment => _t('تعليقك', 'Your comment');
  String get submitReview => _t('إرسال التقييم', 'Submit review');
  String get reviewSubmitted => _t('شكرًا! تم إرسال تقييمك.', 'Thanks! Your review was submitted.');
  String get pickRating => _t('اختر عدد النجوم', 'Choose a star rating');
  String get reviewRequiresPurchase => _t(
    'يمكنك تقييم هذا المنتج بعد استلام طلب يحتوي عليه.',
    'You can review this product once an order containing it has been delivered.',
  );

  // Search
  String get filters => _t('الفلاتر', 'Filters');
  String get sortBy => _t('الترتيب حسب', 'Sort by');
  String get minPrice => _t('أقل سعر', 'Min price');
  String get maxPrice => _t('أعلى سعر', 'Max price');
  String get inStockOnly => _t('المتوفر فقط', 'In stock only');
  String get featuredOnly => _t('المميز فقط', 'Featured only');
  String get category => _t('القسم', 'Category');
  String get allCategories => _t('كل الأقسام', 'All categories');
  String get apply => _t('تطبيق', 'Apply');
  String get reset => _t('إعادة تعيين', 'Reset');
  String get ascending => _t('تصاعدي', 'Ascending');
  String get descending => _t('تنازلي', 'Descending');
  String get sortDefault => _t('الافتراضي', 'Default');
  String get sortPrice => _t('السعر', 'Price');
  String get sortNewest => _t('الأحدث', 'Newest');
  String get sortBestSelling => _t('الأكثر مبيعًا', 'Best selling');
  String get sortRating => _t('التقييم', 'Rating');
  String get sortName => _t('الاسم', 'Name');
  String get typeToSearch => _t('اكتب للبحث في المنتجات.', 'Type to search products.');
  String get invalidPriceRange => _t('أقل سعر يجب ألا يتجاوز أعلى سعر.', 'Min price must not exceed max price.');

  // Auth
  String get login => _t('تسجيل الدخول', 'Sign in');
  String get register => _t('إنشاء حساب', 'Create account');
  String get logout => _t('تسجيل الخروج', 'Sign out');
  String get name => _t('الاسم', 'Name');
  String get email => _t('البريد الإلكتروني', 'Email');
  String get phone => _t('رقم الهاتف', 'Phone number');
  String get password => _t('كلمة المرور', 'Password');
  String get confirmPassword => _t('تأكيد كلمة المرور', 'Confirm password');
  String get invalidEmail => _t('أدخل بريدًا إلكترونيًا صحيحًا', 'Enter a valid email');
  String get passwordTooShort => _t('8 أحرف على الأقل', 'At least 8 characters');
  String get passwordsDontMatch => _t('كلمتا المرور غير متطابقتين', 'Passwords do not match');
  String get noAccount => _t('ليس لديك حساب؟', "Don't have an account?");
  String get haveAccount => _t('لديك حساب؟', 'Already have an account?');
  String get loginRequired => _t('سجّل الدخول للمتابعة', 'Sign in to continue');
  String get loginRequiredBody => _t(
    'تحتاج إلى حساب لاستخدام السلة والطلبات والمفضلة.',
    'You need an account to use the cart, orders and favorites.',
  );
  String get welcome => _t('مرحبًا بك', 'Welcome');
  String get guest => _t('زائر', 'Guest');
  String get editProfile => _t('تعديل البيانات', 'Edit profile');
  String get profileUpdated => _t('تم حفظ بياناتك', 'Profile saved');
  String get logoutConfirm => _t('هل تريد تسجيل الخروج؟', 'Do you want to sign out?');
  String get contactStore => _t('تواصل مع المتجر', 'Contact the store');
  String get aboutStore => _t('عن المتجر', 'About the store');
  String get call => _t('اتصال', 'Call');
  String get whatsapp => _t('واتساب', 'WhatsApp');
  String get minOrder => _t('الحد الأدنى للطلب', 'Minimum order');
  String get deliveryAndOrders => _t('التوصيل والطلبات', 'Delivery & orders');
  String get linkFailed => _t('تعذّر فتح الرابط', 'Could not open the link');
  String get appearance => _t('المظهر', 'Appearance');
  String get themeSystem => _t('تلقائي', 'System');
  String get themeLight => _t('فاتح', 'Light');
  String get themeDark => _t('داكن', 'Dark');

  // Cart
  String get emptyCart => _t('سلتك فارغة', 'Your cart is empty');
  String get startShopping => _t('ابدأ التسوق', 'Start shopping');
  String get subtotal => _t('المجموع الفرعي', 'Subtotal');
  String get discount => _t('الخصم', 'Discount');
  String get deliveryFee => _t('رسوم التوصيل', 'Delivery fee');
  String get total => _t('الإجمالي', 'Total');
  String get couponCode => _t('كود الخصم', 'Coupon code');
  String get applyCoupon => _t('تطبيق', 'Apply');
  String get removeCoupon => _t('إزالة الكوبون', 'Remove coupon');
  String couponApplied(String code) => _t('الكوبون $code مُطبّق', 'Coupon $code applied');
  String get clearCart => _t('إفراغ السلة', 'Clear cart');
  String get clearCartConfirm => _t('هل تريد حذف كل المنتجات من السلة؟', 'Remove all items from the cart?');
  String get checkout => _t('إتمام الطلب', 'Checkout');
  String minOrderNotMet(String amount) => _t('الحد الأدنى للطلب $amount', 'Minimum order is $amount');
  String get itemUnavailable => _t('هذا المنتج لم يعد متوفرًا', 'No longer available');
  String get remove => _t('حذف', 'Remove');

  // Checkout
  String get orderSummary => _t('ملخص الطلب', 'Order summary');
  String get deliveryDetails => _t('بيانات التوصيل', 'Delivery details');
  String get customerName => _t('اسم المستلم', 'Recipient name');
  String get address => _t('العنوان', 'Address');
  String get notes => _t('ملاحظات (اختياري)', 'Notes (optional)');
  String get paymentMethod => _t('طريقة الدفع', 'Payment method');
  String get payCash => _t('الدفع عند الاستلام', 'Cash on delivery');
  String get payCardDemo => _t('بطاقة (تجريبي)', 'Card (demo)');
  String get cardDemoNotice => _t(
    'وضع تجريبي: لن يتم خصم أي مبلغ ولا تُطلب بيانات بطاقة. لا تستخدمه لطلبات حقيقية.',
    'Demo mode: no money is charged and no card details are collected. Not a real payment.',
  );
  String get placeOrder => _t('تأكيد الطلب', 'Place order');
  String get invalidPhone => _t('أدخل رقم هاتف صحيحًا', 'Enter a valid phone number');

  // Orders
  String get orderPlaced => _t('تم استلام طلبك!', 'Order placed!');
  String orderNumber(String n) => _t('رقم الطلب: $n', 'Order number: $n');
  String get trackOrder => _t('تتبع الطلب', 'Track order');
  String get continueShopping => _t('متابعة التسوق', 'Continue shopping');
  String get allStatuses => _t('الكل', 'All');
  String get noOrders => _t('لا توجد طلبات بعد.', 'No orders yet.');
  String get orderDetails => _t('تفاصيل الطلب', 'Order details');
  String get tracking => _t('تتبع الطلب', 'Tracking');
  String get items => _t('المنتجات', 'Items');
  String get cancelOrder => _t('إلغاء الطلب', 'Cancel order');
  String get cancelOrderConfirm =>
      _t('هل أنت متأكد من إلغاء هذا الطلب؟', 'Are you sure you want to cancel this order?');
  String get orderCancelled => _t('تم إلغاء الطلب', 'Order cancelled');
  String get status => _t('الحالة', 'Status');
  String get payment => _t('الدفع', 'Payment');

  String statusLabel(String status) => switch (status) {
    'pending' => _t('بانتظار التأكيد', 'Pending'),
    'confirmed' => _t('تم التأكيد', 'Confirmed'),
    'preparing' => _t('قيد التجهيز', 'Preparing'),
    'shipped' => _t('تم الشحن', 'Shipped'),
    'delivered' => _t('تم التوصيل', 'Delivered'),
    'cancelled' => _t('ملغي', 'Cancelled'),
    _ => status,
  };

  String paymentLabel(String? method) => switch (method) {
    'cash' => payCash,
    'card_demo' => payCardDemo,
    _ => method ?? '',
  };

  // Favorites
  String get noFavorites => _t('لا توجد منتجات في المفضلة.', 'No favorites yet.');
  String get addFavorite => _t('أضف للمفضلة', 'Add to favorites');
  String get removeFavorite => _t('أزل من المفضلة', 'Remove from favorites');
}

extension AppStringsX on BuildContext {
  AppStrings get s => AppStrings.of(this);
}
