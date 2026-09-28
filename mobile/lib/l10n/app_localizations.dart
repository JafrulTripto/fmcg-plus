import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FMCG+ Retail POS & Ledger'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @posRegister.
  ///
  /// In en, this message translates to:
  /// **'POS Register'**
  String get posRegister;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get customers;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get todaySales;

  /// No description provided for @todayOrders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get todayOrders;

  /// No description provided for @khataDues.
  ///
  /// In en, this message translates to:
  /// **'Total Ledger Dues'**
  String get khataDues;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alerts'**
  String get lowStock;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @noRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recent purchases yet'**
  String get noRecentTransactions;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Cash Customer'**
  String get walkInCustomer;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get totalPayable;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash Received'**
  String get cashReceived;

  /// No description provided for @remainingDue.
  ///
  /// In en, this message translates to:
  /// **'Remaining Due'**
  String get remainingDue;

  /// No description provided for @changeReturn.
  ///
  /// In en, this message translates to:
  /// **'Change to Return'**
  String get changeReturn;

  /// No description provided for @confirmSale.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sale'**
  String get confirmSale;

  /// No description provided for @fullCash.
  ///
  /// In en, this message translates to:
  /// **'Full Cash'**
  String get fullCash;

  /// No description provided for @partialPayment.
  ///
  /// In en, this message translates to:
  /// **'Partial Payment'**
  String get partialPayment;

  /// No description provided for @creditKhata.
  ///
  /// In en, this message translates to:
  /// **'Full Credit (Ledger)'**
  String get creditKhata;

  /// No description provided for @exact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get exact;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer Phone Number'**
  String get customerPhone;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search by product name or barcode...'**
  String get searchProducts;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers by name or phone...'**
  String get searchCustomers;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add New Customer'**
  String get addCustomer;

  /// No description provided for @payDue.
  ///
  /// In en, this message translates to:
  /// **'Pay Store Due'**
  String get payDue;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @fullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully Paid'**
  String get fullyPaid;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNumber;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you, visit again!'**
  String get thankYou;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get bangla;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get switchLanguage;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter 4-Digit PIN'**
  String get enterPin;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register Merchant'**
  String get register;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeName;

  /// No description provided for @storeAddress.
  ///
  /// In en, this message translates to:
  /// **'Store Address'**
  String get storeAddress;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @withDue.
  ///
  /// In en, this message translates to:
  /// **'With Due'**
  String get withDue;

  /// No description provided for @zeroDue.
  ///
  /// In en, this message translates to:
  /// **'Zero Due'**
  String get zeroDue;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @recordKhataPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Ledger Payment'**
  String get recordKhataPayment;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmount;

  /// No description provided for @paymentAmountWithSymbol.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount (৳)'**
  String get paymentAmountWithSymbol;

  /// No description provided for @currentDue.
  ///
  /// In en, this message translates to:
  /// **'Current Due'**
  String get currentDue;

  /// No description provided for @totalKhataCredit.
  ///
  /// In en, this message translates to:
  /// **'TOTAL LEDGER DUES'**
  String get totalKhataCredit;

  /// No description provided for @dueBalance.
  ///
  /// In en, this message translates to:
  /// **'Due Balance'**
  String get dueBalance;

  /// No description provided for @zeroBalance.
  ///
  /// In en, this message translates to:
  /// **'Zero Balance'**
  String get zeroBalance;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'+ Customer'**
  String get newCustomer;

  /// No description provided for @newKhataCustomer.
  ///
  /// In en, this message translates to:
  /// **'New Ledger Customer'**
  String get newKhataCustomer;

  /// No description provided for @customerKhataPortal.
  ///
  /// In en, this message translates to:
  /// **'Customer Ledger Portal'**
  String get customerKhataPortal;

  /// No description provided for @switchToCustomerPortal.
  ///
  /// In en, this message translates to:
  /// **'Switch to Customer Portal'**
  String get switchToCustomerPortal;

  /// No description provided for @customerPortal.
  ///
  /// In en, this message translates to:
  /// **'Customer Portal'**
  String get customerPortal;

  /// No description provided for @digitalKhataPassbook.
  ///
  /// In en, this message translates to:
  /// **'Ledger Passbook'**
  String get digitalKhataPassbook;

  /// No description provided for @merchantLogin.
  ///
  /// In en, this message translates to:
  /// **'Merchant Login'**
  String get merchantLogin;

  /// No description provided for @storeProfile.
  ///
  /// In en, this message translates to:
  /// **'Store Profile'**
  String get storeProfile;

  /// No description provided for @toggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle Theme'**
  String get toggleTheme;

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Light Mode'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to Dark Mode'**
  String get switchToDarkMode;

  /// No description provided for @signOutDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out from this device'**
  String get signOutDeviceSubtitle;

  /// No description provided for @pinOrOtpVerification.
  ///
  /// In en, this message translates to:
  /// **'PIN or OTP verification'**
  String get pinOrOtpVerification;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Retail POS & Digital Ledger'**
  String get tagline;

  /// No description provided for @registerStore.
  ///
  /// In en, this message translates to:
  /// **'Register Store'**
  String get registerStore;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @securityPin.
  ///
  /// In en, this message translates to:
  /// **'Security PIN'**
  String get securityPin;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'4 or 6-digit PIN'**
  String get pinHint;

  /// No description provided for @merchantPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Merchant Phone Number'**
  String get merchantPhoneNumber;

  /// No description provided for @changePhone.
  ///
  /// In en, this message translates to:
  /// **'Change Phone'**
  String get changePhone;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'6-digit OTP Code'**
  String get otpCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @storeDetailsAndPin.
  ///
  /// In en, this message translates to:
  /// **'Store Details & Security PIN'**
  String get storeDetailsAndPin;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerName;

  /// No description provided for @ownerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rafiqul Islam'**
  String get ownerNameHint;

  /// No description provided for @storeNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rafiq General Store'**
  String get storeNameHint;

  /// No description provided for @storeAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mirpur-10, Dhaka'**
  String get storeAddressHint;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set 4-Digit Security PIN'**
  String get setPin;

  /// No description provided for @launchStore.
  ///
  /// In en, this message translates to:
  /// **'Launch Store'**
  String get launchStore;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditLimit;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address / Area (Optional)'**
  String get addressOptional;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Road 4, House 12, Mirpur 10'**
  String get addressHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @openKhataAccount.
  ///
  /// In en, this message translates to:
  /// **'Open Ledger Account'**
  String get openKhataAccount;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes / Voucher # (Optional)'**
  String get notesOptional;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Counter deposit or bKash TrxID'**
  String get notesHint;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @onboardCatalogItem.
  ///
  /// In en, this message translates to:
  /// **'Onboard Catalog Item'**
  String get onboardCatalogItem;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @unitType.
  ///
  /// In en, this message translates to:
  /// **'Unit Type'**
  String get unitType;

  /// No description provided for @looseItemHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank if selling unbranded or loose items.'**
  String get looseItemHint;

  /// No description provided for @purchaseCost.
  ///
  /// In en, this message translates to:
  /// **'Purchase Cost'**
  String get purchaseCost;

  /// No description provided for @purchaseCostPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Purchase Cost / Unit'**
  String get purchaseCostPerUnit;

  /// No description provided for @sellingMrp.
  ///
  /// In en, this message translates to:
  /// **'Selling MRP'**
  String get sellingMrp;

  /// No description provided for @customerSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Customer Selling Price'**
  String get customerSellingPrice;

  /// No description provided for @initialStock.
  ///
  /// In en, this message translates to:
  /// **'Initial Stock Quantity'**
  String get initialStock;

  /// No description provided for @lowStockAlertLimit.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert Limit'**
  String get lowStockAlertLimit;

  /// No description provided for @expiryDateAlert.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date Alert'**
  String get expiryDateAlert;

  /// No description provided for @trackExpiry.
  ///
  /// In en, this message translates to:
  /// **'Track product expiration date'**
  String get trackExpiry;

  /// No description provided for @saveProduct.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get saveProduct;

  /// No description provided for @quantityToAdjust.
  ///
  /// In en, this message translates to:
  /// **'Quantity to Adjust'**
  String get quantityToAdjust;

  /// No description provided for @mfsOnlineSettlement.
  ///
  /// In en, this message translates to:
  /// **'MFS Online Settlement'**
  String get mfsOnlineSettlement;

  /// No description provided for @dokanPos.
  ///
  /// In en, this message translates to:
  /// **'Dokan POS'**
  String get dokanPos;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashPayment;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retailCatalog.
  ///
  /// In en, this message translates to:
  /// **'FMCG+ Retail Master'**
  String get retailCatalog;

  /// No description provided for @activeSaleBasket.
  ///
  /// In en, this message translates to:
  /// **'Active Sale Basket'**
  String get activeSaleBasket;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @onlineSync.
  ///
  /// In en, this message translates to:
  /// **'ONLINE SYNC'**
  String get onlineSync;

  /// No description provided for @allEventsSynced.
  ///
  /// In en, this message translates to:
  /// **'All cloud events synced and updated'**
  String get allEventsSynced;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardSubtitle;

  /// No description provided for @posTerminalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pos Terminal'**
  String get posTerminalSubtitle;

  /// No description provided for @stockInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stock Inventory'**
  String get stockInventorySubtitle;

  /// No description provided for @khataLedgerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get khataLedgerSubtitle;

  /// No description provided for @overviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewSubtitle;

  /// No description provided for @moreOptionsAndSettings.
  ///
  /// In en, this message translates to:
  /// **'More Options & Settings'**
  String get moreOptionsAndSettings;

  /// No description provided for @switchCustomerViewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to customer view & receipt passbook'**
  String get switchCustomerViewSubtitle;

  /// No description provided for @currentLanguageSubtitleEn.
  ///
  /// In en, this message translates to:
  /// **'Current: English (Tap for Bangla)'**
  String get currentLanguageSubtitleEn;

  /// No description provided for @currentLanguageSubtitleBn.
  ///
  /// In en, this message translates to:
  /// **'Current: Bangla (Tap for English)'**
  String get currentLanguageSubtitleBn;

  /// No description provided for @enterPhoneToRegister.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to register your store.'**
  String get enterPhoneToRegister;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to'**
  String get codeSentTo;

  /// No description provided for @fullDue.
  ///
  /// In en, this message translates to:
  /// **'Full Due'**
  String get fullDue;

  /// No description provided for @payWith.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get payWith;

  /// No description provided for @activeDebtors.
  ///
  /// In en, this message translates to:
  /// **'Active Debtors'**
  String get activeDebtors;

  /// No description provided for @saveAndAddNext.
  ///
  /// In en, this message translates to:
  /// **'Save & Add Next'**
  String get saveAndAddNext;

  /// No description provided for @adjustStockLevel.
  ///
  /// In en, this message translates to:
  /// **'Adjust Stock Level'**
  String get adjustStockLevel;

  /// No description provided for @applyAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Apply Adjustment'**
  String get applyAdjustment;

  /// No description provided for @adjustmentReason.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Reason'**
  String get adjustmentReason;

  /// No description provided for @notesReferenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes / Reference (Optional)'**
  String get notesReferenceOptional;

  /// No description provided for @currentStock.
  ///
  /// In en, this message translates to:
  /// **'Current Stock'**
  String get currentStock;

  /// No description provided for @lowStockHint.
  ///
  /// In en, this message translates to:
  /// **'Dashboard marks item Low Stock when quantity reaches or drops below this count.'**
  String get lowStockHint;

  /// No description provided for @numberAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This number is already registered. Please log in.'**
  String get numberAlreadyRegistered;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @enter6DigitOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-Digit OTP'**
  String get enter6DigitOtp;

  /// No description provided for @enter6DigitOtpBn.
  ///
  /// In en, this message translates to:
  /// **'৬ ডিজিটের যাচাইকরণ কোড দিন'**
  String get enter6DigitOtpBn;

  /// No description provided for @securePosGateway.
  ///
  /// In en, this message translates to:
  /// **'SECURE POS GATEWAY'**
  String get securePosGateway;

  /// No description provided for @terminalActive.
  ///
  /// In en, this message translates to:
  /// **'Terminal Active'**
  String get terminalActive;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Number'**
  String get changeNumber;

  /// No description provided for @smsDetected.
  ///
  /// In en, this message translates to:
  /// **'SMS Detected'**
  String get smsDetected;

  /// No description provided for @fmcgSecurityVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'FMCG+ Security verification code'**
  String get fmcgSecurityVerificationCode;

  /// No description provided for @tapToFill.
  ///
  /// In en, this message translates to:
  /// **'Tap to Fill'**
  String get tapToFill;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in'**
  String get resendCodeIn;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWait;

  /// No description provided for @resendCodeNow.
  ///
  /// In en, this message translates to:
  /// **'Resend Code Now'**
  String get resendCodeNow;

  /// No description provided for @resendCodeNowBn.
  ///
  /// In en, this message translates to:
  /// **'আবার পাঠান'**
  String get resendCodeNowBn;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get voiceCall;

  /// No description provided for @clearKey.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get clearKey;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @verifyAndContinueSub.
  ///
  /// In en, this message translates to:
  /// **'যাচাই করুন ও এগিয়ে যান'**
  String get verifyAndContinueSub;

  /// No description provided for @needHelpFmcgDesk.
  ///
  /// In en, this message translates to:
  /// **'Need help? FMCG+ Desk'**
  String get needHelpFmcgDesk;

  /// No description provided for @otpVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerificationTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
