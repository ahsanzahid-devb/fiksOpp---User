import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

const APP_NAME = 'Fiksopp Service';
const APP_NAME_TAG_LINE = 'On-Demand Home Services App';
// Primary color: teal (#008080)
const defaultPrimaryColor = Color(0xFF008080);

// Don't add slash at the end of the url

const DOMAIN_URL = "https://fiksopp.inoor.buzz";
const BASE_URL = '$DOMAIN_URL/api/';

// Default app language (Norwegian as primary)
const DEFAULT_LANGUAGE = 'no';

/// You can change this to your Provider App package name
/// This will be used in Registered As Partner in Sign In Screen where your users can redirect to the Play/App Store for Provider App
/// You can specify in Admin Panel, These will be used if you don't specify in Admin Panel
const PROVIDER_PACKAGE_NAME = 'fiksopp.inoor.buzz.provider';

/// Canonical customer app listing (used when admin `playstore_url` is wrong or placeholder).
/// See https://play.google.com/store/apps/details?id=buzz.inoor.fiksopp
const CUSTOMER_APP_PLAY_STORE_LISTING =
    'https://play.google.com/store/apps/details?id=buzz.inoor.fiksopp';

/// Public App Store product page (not App Store Connect). Used when Rate Us runs
/// and the API `appstore_url` is missing or invalid.
/// Live listing: https://apps.apple.com/us/app/fiksopp/id6758296889
const CUSTOMER_APP_APP_STORE_LISTING =
    'https://apps.apple.com/us/app/fiksopp/id6758296889';

const IOS_LINK_FOR_PARTNER = "";

/// Force-update dialog on iOS (must be a public apps.apple.com URL, not App Store Connect).
const IOS_LINK_FOR_USER = 'https://apps.apple.com/us/app/fiksopp/id6758296889';

const DASHBOARD_AUTO_SLIDER_SECOND = 5;
const OTP_TEXT_FIELD_LENGTH = 6;

const TERMS_CONDITION_URL = '';
const PRIVACY_POLICY_URL = '';
const HELP_AND_SUPPORT_URL = '';
const REFUND_POLICY_URL = '';
const INQUIRY_SUPPORT_EMAIL = '';

//Airtel Money Payments
///It Supports ["UGX", "NGN", "TZS", "KES", "RWF", "ZMW", "CFA", "XOF", "XAF", "CDF", "USD", "XAF", "SCR", "MGA", "MWK"]
const AIRTEL_CURRENCY_CODE = "MWK";
const AIRTEL_COUNTRY_CODE = "MW";
const AIRTEL_TEST_BASE_URL = 'https://openapiuat.airtel.africa/'; //Test Url
const AIRTEL_LIVE_BASE_URL = 'https://openapi.airtel.africa/'; // Live Url

/// PAYSTACK PAYMENT DETAIL
const PAYSTACK_CURRENCY_CODE = 'NGN';

/// Nigeria Currency

/// STRIPE PAYMENT DETAIL
const STRIPE_MERCHANT_COUNTRY_CODE = 'IN';
const STRIPE_CURRENCY_CODE = 'INR';

/// RAZORPAY PAYMENT DETAIL
const RAZORPAY_CURRENCY_CODE = 'INR';

/// PAYPAL PAYMENT DETAIL
const PAYPAL_CURRENCY_CODE = 'USD';

/// SADAD PAYMENT DETAIL
const SADAD_API_URL = 'https://api-s.sadad.qa';
const SADAD_PAY_URL = "https://d.sadad.qa";

DateTime todayDate = DateTime(2022, 8, 24);

Country defaultCountry() {
  return Country(
    phoneCode: '91',
    countryCode: 'IN',
    e164Sc: 91,
    geographic: true,
    level: 1,
    name: 'India',
    example: '9123456789',
    displayName: 'India (IN) [+91]',
    displayNameNoCountryCode: 'India (IN)',
    e164Key: '91-IN-0',
    fullExampleWithPlusSign: '+919123456789',
  );
}

//Chat Module File Upload Configs
const chatFilesAllowedExtensions = [
  'jpg', 'jpeg', 'png', 'gif', 'webp', // Images
  'pdf', 'txt', // Documents
  'mkv', 'mp4', // Video
  'mp3', // Audio
];

const max_acceptable_file_size = 5; //Size in Mb
