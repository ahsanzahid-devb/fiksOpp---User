import 'package:fiksOpp/locale/language_en.dart';

/// Norwegian language that builds on top of the full English implementation,
/// overriding only the strings we want to localize now.
class LanguageNo extends LanguageEn {
  @override
  String get appName => 'Bestillingssystem';

  @override
  String get signIn => 'Logg inn';

  @override
  String get signUp => 'Registrer deg';

  @override
  String get signOut => 'Logg ut';

  @override
  String get email => 'E-post';

  @override
  String get password => 'Passord';

  @override
  String get confirmPassword => 'Bekreft passord';

  @override
  String get forgotPassword => 'Glemt passord';

  @override
  String get resetPassword => 'Tilbakestill passord';

  @override
  String get changePassword => 'Endre passord';

  @override
  String get home => 'Hjem';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Rediger profil';

  @override
  String get save => 'Lagre';

  @override
  String get update => 'Oppdater';

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Slett';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nei';

  @override
  String get ok => 'OK';

  @override
  String get submit => 'Send inn';

  @override
  String get next => 'Neste';

  @override
  String get previous => 'Forrige';

  @override
  String get loading => 'Laster';

  @override
  String get search => 'Søk';

  @override
  String get notification => 'Varsel';

  @override
  String get notifications => 'Varsler';

  @override
  String get settings => 'Innstillinger';

  @override
  String get language => 'Språk';

  @override
  String get theme => 'Tema';

  @override
  String get lightTheme => 'Lyst tema';

  @override
  String get darkTheme => 'Mørkt tema';

  @override
  String get systemTheme => 'Systemtema';

  @override
  String get booking => 'Bestilling';

  @override
  String get bookings => 'Bestillinger';

  @override
  String get myBookings => 'Mine bestillinger';

  @override
  String get bookNow => 'Bestill nå';

  @override
  String get bookingDetail => 'Bestillingsdetaljer';

  @override
  String get bookingHistory => 'Bestillingshistorikk';

  @override
  String get payment => 'Betaling';

  @override
  String get payments => 'Betalinger';

  @override
  String get paymentMethod => 'Betalingsmetode';

  @override
  String get paymentStatus => 'Betalingsstatus';

  @override
  String get paid => 'Betalt';

  @override
  String get unpaid => 'Ikke betalt';

  @override
  String get pending => 'Venter';

  @override
  String get completed => 'Fullført';

  @override
  String get cancelled => 'Avbrutt';

  @override
  String get rejected => 'Avvist';

  @override
  String get approved => 'Godkjent';

  @override
  String get service => 'Tjeneste';

  @override
  String get services => 'Tjenester';

  @override
  String get provider => 'Leverandør';

  @override
  String get providers => 'Leverandører';

  @override
  String get category => 'Kategori';

  @override
  String get categories => 'Kategorier';

  @override
  String get price => 'Pris';

  @override
  String get total => 'Totalt';

  @override
  String get discount => 'Rabatt';

  @override
  String get tax => 'Avgift';

  @override
  String get description => 'Beskrivelse';

  @override
  String get address => 'Adresse';

  @override
  String get phone => 'Telefon';

  @override
  String get contactUs => 'Kontakt oss';

  @override
  String get aboutUs => 'Om oss';

  @override
  String get help => 'Hjelp';

  @override
  String get faq => 'Ofte stilte spørsmål';

  @override
  String get noDataFound => 'Ingen data funnet';

  @override
  String get somethingWentWrong => 'Noe gikk galt';

  @override
  String get internetNotAvailable => 'Internett er ikke tilgjengelig';

  @override
  String get logoutConfirmation => 'Er du sikker på at du vil logge ut?';

  @override
  String get deleteConfirmation => 'Er du sikker på at du vil slette dette?';

  @override
  String get requiredField => 'Dette feltet er obligatorisk';

  @override
  String get invalidEmail => 'Ugyldig e-postadresse';

  @override
  String get passwordLength => 'Passordet må være mellom 8 og 14 tegn';

  @override
  String get retry => 'Prøv igjen';

  @override
  String get refresh => 'Oppdater';

  @override
  String get welcome => 'Velkommen';

  @override
  String get hello => 'Hei';

  @override
  String get viewAll => 'Se alle';

  @override
  String get seeMore => 'Se mer';

  @override
  String get seeLess => 'Se mindre';

  @override
  String get today => 'I dag';

  @override
  String get tomorrow => 'I morgen';

  @override
  String get selectDate => 'Velg dato';

  @override
  String get selectTime => 'Velg tid';

  @override
  String get newPostJobRequest => 'Opprett ny jobbforespørsel';

  @override
  String get postJobTitle => 'Tittel på jobbforespørsel';

  @override
  String get postJobDescription => 'Beskrivelse av jobbforespørsel';

  @override
  String get myPostJobList => 'Mine tilpassede jobbforespørsler';

  @override
  String get lblMyJobs => 'Mine jobber';

  @override
  String get requestNewJob => 'Be om ny jobb';

  @override
  String get postJobSuccess => 'Jobben ble opprettet';

  @override
  String get confirmBooking => 'Bekreft bestilling';

  @override
  String get bookingConfirmed => 'Bestilling bekreftet';

  @override
  String get bookingFailed => 'Bestilling mislyktes';

  // === BaseLanguage getters used across the app (Norwegian) ===
  @override
  String get walkTitle1 => 'Opprett og sett opp kontoen din';
  @override
  String get walkTitle2 => 'Bla og bestill tjenester';
  @override
  String get walkTitle3 => 'Spor og administrer bestillingene dine';
  @override
  String get getStarted => 'Kom i gang';
  @override
  String get hintFirstNameTxt => 'Fornavn';
  @override
  String get hintLastNameTxt => 'Etternavn';
  @override
  String get hintContactNumberTxt => 'Kontaktnummer';
  @override
  String get hintEmailAddressTxt => 'Skriv inn e-postadressen din';
  @override
  String get hintUserNameTxt => 'Brukernavn';
  @override
  String get hintPasswordTxt => 'Passord';
  @override
  String get hintReenterPasswordTxt => 'Skriv inn passord på nytt';
  @override
  String get confirm => 'Bekreft';
  @override
  String get hintEmailTxt => 'E-postadresse';
  @override
  String get alreadyHaveAccountTxt => 'Har du allerede en konto?';
  @override
  String get rememberMe => 'Husk meg';
  @override
  String get dashboard => 'Dashboard';
  @override
  String get camera => 'Kamera';
  @override
  String get appTheme => 'App-tema';
  @override
  String get rateUs => 'Vurder oss';
  @override
  String get termsCondition => 'Vilkår og betingelser';
  @override
  String get helpSupport => 'Hjelp og støtte';
  @override
  String get privacyPolicy => 'Personvernregler';
  @override
  String get about => 'Om';
  @override
  String get chooseTheme => 'Velg app-tema';
  @override
  String get selectCountry => 'Velg land';
  @override
  String get selectState => 'Velg fylke';
  @override
  String get selectCity => 'Velg by';
  @override
  String get passwordNotMatch => 'Passordet stemmer ikke';
  @override
  String get doNotHaveAccount => 'Har du ikke konto?';
  @override
  String get hintOldPasswordTxt => 'Gammelt passord';
  @override
  String get hintNewPasswordTxt => 'Nytt passord';
  @override
  String get hintAddress => 'Adresse';
  @override
  String get hintDescription => 'Beskrivelse';
  @override
  String get lblGallery => 'Galleri';
  @override
  String get yourReview => 'Din anmeldelse';
  @override
  String get review => 'Anmeldelser';
  @override
  String get lblApply => 'Bruk';
  @override
  String get contactAdmin => 'Vennligst kontakt administrator';
  @override
  String get allServices => 'Alle tjenester';
  @override
  String get duration => 'Varighet';
  @override
  String get hourly => 'per time';
  @override
  String get done => 'Ferdig';
  @override
  String get totalAmount => 'Totalbeløp';
  @override
  String get applyCoupon => 'Bruk kupong';
  @override
  String get priceDetail => 'Prisdetaljer';
  @override
  String get lblAlertBooking => 'Vil du bestille tjenesten?';
  @override
  String get serviceName => 'Tjenestenavn';
  @override
  String get lblCancelReason => 'Oppgi grunn for avbestilling';
  @override
  String get enterReason => 'Skriv grunnen her';
  @override
  String get noDataAvailable => 'Ingen data tilgjengelig';
  @override
  String get lblOk => 'OK';
  @override
  String get paymentDetail => 'Betalingsdetaljer';
  @override
  String get viewDetail => 'Se detaljer';
  @override
  String get appThemeLight => 'Lys';
  @override
  String get appThemeDark => 'Mørk';
  @override
  String get appThemeDefault => 'Systemstandard';
  @override
  String get markAsRead => 'Merk alle som lest';
  @override
  String get lblYes => 'Ja';
  @override
  String get lblNo => 'Nei';
  @override
  String get btnRate => 'Vurder nå';
  @override
  String get btnSubmit => 'Send inn';
  @override
  String get walkThrough1 =>
      'Registrer deg eller logg inn med e-post eller sosiale medier. Fullfør profilen for en enkel bestilling.';
  @override
  String get walkThrough2 =>
      'Utforsk tjenester i ditt område. Velg tjeneste, tid og adresse for å bestille raskt.';
  @override
  String get walkThrough3 =>
      'Følg bestillingene i sanntid. Se og administrer nåværende og tidligere bestillinger.';
  @override
  String get lblNotification => 'Varsler';
  @override
  String get lblUnAuthorized => 'Demobruker kan ikke utføre denne handlingen';
  @override
  String get btnNext => 'Neste';
  @override
  String get lblViewAll => 'Se alle';
  @override
  String get notAvailable => 'Ikke tilgjengelig';
  @override
  String get lblFavorite => 'Favoritttjenester';
  @override
  String get lblChat => 'Chat';
  @override
  String get getLocation => 'Sett';
  @override
  String get setAddress => 'Sett adresse';
  @override
  String get requiredText => 'Dette feltet er obligatorisk';
  @override
  String get phnRequiredText => 'Vennligst skriv inn mobilnummer';
  @override
  String get lblCall => 'Ring';
  @override
  String get lblRateHandyman => 'Vurder håndverker';
  @override
  String get msgForLocationOn =>
      'Posisjon er på. Fortsett å vise tjenester fra ALLE områder?';
  @override
  String get msgForLocationOff =>
      'Posisjon er av. Utforsk tjenester i valgt område.';
  @override
  String get lblEnterPhnNumber => 'Skriv inn telefonnummer';
  @override
  String get btnSendOtp => 'Send OTP';
  @override
  String get lblLocationOff => 'Alle tjenester tilgjengelig';
  @override
  String get lblAppSetting => 'App-innstillinger';
  @override
  String get lblSubTotal => 'Delsum';
  @override
  String get lblImage => 'Bilde';
  @override
  String get lblVideo => 'Video';
  @override
  String get lblAudio => 'Lyd';
  @override
  String get lblChangePwdTitle =>
      'Nytt passord må være forskjellig fra tidligere passord';
  @override
  String get lblForgotPwdSubtitle =>
      'En tilbakestillingslenke sendes til e-postadressen over';
  @override
  String get lblLoginTitle => 'Hei igjen';
  @override
  String get lblLoginSubTitle => 'Velkommen tilbake, vi har savnet deg';
  @override
  String get lblOrContinueWith => 'Eller fortsett med';
  @override
  String get lblHelloUser => 'Hei!';
  @override
  String get lblSignUpSubTitle => 'Opprett konto for bedre opplevelse';
  @override
  String get lblStepper1Title => 'Oppgi detaljert informasjon';
  @override
  String get lblDateAndTime => 'Dato og tid:';
  @override
  String get chooseDateAndTime => 'Velg dato og tid';
  @override
  String get lblYourAddress => 'Din adresse';
  @override
  String get lblEnterYourAddress => 'Skriv inn adressen din';
  @override
  String get lblUseCurrentLocation => 'Bruk nåværende posisjon';
  @override
  String get lblEnterDescription => 'Skriv beskrivelse';
  @override
  String get lblPrice => 'Pris';
  @override
  String get lblTax => 'MVA';
  @override
  String get lblDiscount => 'Rabatt';
  @override
  String get lblAvailableCoupons => 'Tilgjengelige kuponger';
  @override
  String get lblPrevious => 'Forrige';
  @override
  String get lblCoupon => 'Kupong';
  @override
  String get lblEditYourReview => 'Rediger anmeldelsen';
  @override
  String get lblTime => 'Tid';
  @override
  String get textProvider => 'Leverandør';
  @override
  String get lblConfirmBooking => 'Bekreft bestilling';
  @override
  String get lblConfirmMsg => 'Vil du bekrefte denne bestillingen?';
  @override
  String get lblCancel => 'Avbryt';
  @override
  String get lblExpiryDate => 'Utløpsdato:';
  @override
  String get lblRemoveCoupon => 'Fjern kupong';
  @override
  String get lblNoCouponsAvailable => 'Ingen kuponger tilgjengelig';
  @override
  String get lblStep1 => 'Steg 1';
  @override
  String get lblStep2 => 'Steg 2';
  @override
  String get lblBookingID => 'Bestillings-ID';
  @override
  String get lblDate => 'Dato';
  @override
  String get lblEstimatedDate => 'Jobbplanlegging';
  @override
  String get lblSelectArea => 'Velg område';
  @override
  String get hintJobScheduling =>
      'Jeg vil ha jobben gjort hjemme hos meg i Oslo, Norge på dato kl. tid';
  @override
  String get lblAboutHandyman => 'Om håndverker';
  @override
  String get lblAboutProvider => 'Om leverandør';
  @override
  String get lblNotRatedYet => 'Du har ikke vurdert ennå';
  @override
  String get lblDeleteReview => 'Slett anmeldelse';
  @override
  String get lblConfirmReviewSubTitle => 'Vil du slette denne anmeldelsen?';
  @override
  String get lblConfirmService => 'Vil du sette denne tjenesten på vent?';
  @override
  String get lblConFirmResumeService => 'Vil du fortsette denne tjenesten?';
  @override
  String get lblEndServicesMsg => 'Vil du avslutte denne tjenesten?';
  @override
  String get lblCancelBooking => 'Avbryt bestilling';
  @override
  String get lblStart => 'Start';
  @override
  String get lblHold => 'Pause';
  @override
  String get lblResume => 'Fortsett';
  @override
  String get lblPayNow => 'Betal nå';
  @override
  String get lblCheckStatus => 'Sjekk status';
  @override
  String get lblID => 'ID';
  @override
  String get lblNoBookingsFound => 'Ingen bestillinger funnet';
  @override
  String get lblCategory => 'Kategori';
  @override
  String get lblYourComment => 'Din kommentar';
  @override
  String get lblIntroducingCustomerRating => 'Kundevurdering';
  @override
  String get lblSeeYourRatings => 'Se vurderingene dine';
  @override
  String get lblFeatured => 'Utvalgt';
  @override
  String get lblNoServicesFound =>
      'Det er for øyeblikket ingen data i denne sonen';
  @override
  String get lblGENERAL => 'GENERELLT';
  @override
  String get lblAboutApp => 'Om appen';
  @override
  String get lblPurchaseCode => 'Kjøp full kildekode';
  @override
  String get lblNoRateYet => 'Du har ikke vurdert noen tjenester ennå';
  @override
  String get lblMemberSince => 'Medlem siden';
  @override
  String get lblFilterBy => 'Filtrer på';
  @override
  String get lblClearFilter => 'Fjern filter';
  @override
  String get lblNoReviews => 'Ingen anmeldelser';
  @override
  String get lblUnreadNotification => 'Ulest varsel';
  @override
  String get lblChoosePaymentMethod => 'Velg betalingsmetode';
  @override
  String get lblNoPayments => 'Ingen betalinger';
  @override
  String get lblPayWith => 'Vil du betale med';
  @override
  String get payWith => 'Betal med';
  @override
  String get lblYourRating => 'Din vurdering';
  @override
  String get lblEnterReview => 'Skriv anmeldelse (valgfritt)';
  @override
  String get lblDelete => 'Slett';
  @override
  String get lblDeleteRatingMsg => 'Vil du slette denne vurderingen?';
  @override
  String get lblSelectRating => 'Vurdering er påkrevd';
  @override
  String get lblNoServiceRatings => 'Ingen tjenestevurderinger';
  @override
  String get lblSearchFor => 'Søk etter';
  @override
  String get lblRating => 'Vurdering';
  @override
  String get lblAvailableAt => 'Tilgjengelige steder';
  @override
  String get lblRelatedServices => 'Relaterte tjenester';
  @override
  String get lblBookNow => 'Bestill nå';
  @override
  String get lblWelcomeToHandyman => 'Velkommen til FiksOpp';
  @override
  String get lblWalkThroughSubTitle =>
      'FiksOpp – Bestill håndverkere og tjenester enkelt';
  @override
  String get textHandyman => 'Håndverker';
  @override
  String get lblChooseFromMap => 'Velg fra kart';
  @override
  String get lblDeleteAddress => 'Slett adresse';
  @override
  String get lblDeleteSunTitle => 'Vil du slette denne adressen?';
  @override
  String get lblFaq => 'Ofte stilte spørsmål';
  @override
  String get lblServiceFaq => 'Tjeneste-FAQ';
  @override
  String get lblLogoutTitle => 'Vil du logge ut?';
  @override
  String get lblLogoutSubTitle => 'Er du sikker på at du vil logge ut?';
  @override
  String get lblFeaturedProduct => 'Dette er en utvalgt tjeneste';
  @override
  String get lblAlert => 'Varsel';
  @override
  String get lblOnBase => 'Basert på';
  @override
  String get lblInvalidCoupon => 'Kupongkoden er ugyldig';
  @override
  String get lblSelectCode => 'Velg kupongkode';
  @override
  String get lblBackPressMsg => 'Trykk tilbake igjen for å avslutte';
  @override
  String get lblHour => 'time';
  @override
  String get lblHr => 't';
  @override
  String get lblHelplineNumber => 'Støtte-e-post';
  @override
  String get lblSubcategories => 'Underkategorier';
  @override
  String get lblAgree => 'Jeg godtar';
  @override
  String get lblTermsOfService => 'Vilkår for tjenesten';
  @override
  String get lblWalkThrough0 => 'FiksOpp – Bestill tjenester enkelt';
  @override
  String get lblServiceTotalTime => 'Total tjenestetid';
  @override
  String get lblDateTimeUpdated => 'Bestillingsdato og -tid er oppdatert';
  @override
  String get lblSelectDate => 'Velg dato og tid';
  @override
  String get lblReasonCancelling => 'Grunn:';
  @override
  String get lblReasonRejecting => 'Grunn for avvisning';
  @override
  String get lblFailed => 'Grunn til at bestillingen mislyktes';
  @override
  String get lblNotDescription => 'Ingen beskrivelse tilgjengelig';
  @override
  String get lblMaterialTheme => 'Aktiver Material You-tema';
  @override
  String get lblServiceProof => 'Tjenestebevis';
  @override
  String get lblAndroid12Support => 'Appen startes på nytt. Bekreft?';
  @override
  String get lblOff => 'Av';
  @override
  String get lblSignInWithGoogle => 'Logg inn med Google';
  @override
  String get lblSignInWithOTP => 'Logg inn med OTP';
  @override
  String get lblDangerZone => 'Fareområde';
  @override
  String get lblDeleteAccount => 'Slett konto';
  @override
  String get lblUnderMaintenance => 'Under vedlikehold…';
  @override
  String get lblCatchUpAfterAWhile => 'Kom tilbake senere';
  @override
  String get lblId => 'Id';
  @override
  String get lblMethod => 'Metode';
  @override
  String get lblStatus => 'Status';
  @override
  String get lblPending => 'Venter';
  @override
  String get confirmationRequestTxt => 'Vil du utføre denne handlingen?';
  @override
  String get lblDeleteAccountConformation =>
      'Kontoen slettes permanent. Data kan ikke gjenopprettes.';
  @override
  String get lblAutoSliderStatus => 'Automatisk slider';
  @override
  String get lblPickAddress => 'Velg adresse';
  @override
  String get lblUpdateDateAndTime => 'Oppdater dato og tid';
  @override
  String get lblRecheck => 'Sjekk på nytt';
  @override
  String get lblLoginAgain => 'Vennligst logg inn på nytt';
  @override
  String get lblUpdate => 'Oppdater';
  @override
  String get lblNewUpdate => 'Ny oppdatering';
  @override
  String get lblOptionalUpdateNotify => 'Valgfri oppdatering';
  @override
  String get lblAnUpdateTo => 'En oppdatering av';
  @override
  String get lblIsAvailableWouldYouLike => 'er tilgjengelig. Vil du oppdatere?';
  @override
  String get lblRegisterAsPartner => 'Registrer som partner';
  @override
  String get lblSignInWithApple => 'Logg inn med Apple';
  @override
  String get lblWaitingForProviderApproval =>
      'Venter på godkjenning fra leverandør';
  @override
  String get lblFree => 'Gratis';
  @override
  String get lblAppleSignInNotAvailable =>
      'Apple-innlogging er ikke tilgjengelig på enheten din';
  @override
  String get lblTotalExtraCharges => 'Totale ekstrakostnader';
  @override
  String get lblWaitingForResponse => 'Venter på svar';
  @override
  String get lblAll => 'Alle';
  @override
  String get noConversation => 'Ingen samtale';
  @override
  String get noConversationSubTitle =>
      'Du har ikke startet noen samtale ennå. Bestill en tjeneste for å chatte med leverandør.';
  @override
  String get noBookingSubTitle => 'Du har ikke bestilt noe ennå';
  @override
  String get myReviews => 'Mine anmeldelser';
  @override
  String get noCategoryFound => 'Ingen kategori funnet';
  @override
  String get noProviderFound => 'Ingen leverandør funnet';
  @override
  String get createServiceRequest => 'Opprett tjeneste';
  @override
  String get chooseImages => 'Velg bilder';
  @override
  String get serviceDescription => 'Tjenestebeskrivelse';
  @override
  String get addNewService => 'Legg til ny tjeneste';
  @override
  String get noNotifications => 'Ingen varsler';
  @override
  String get noNotificationsSubTitle => 'Vi varsler deg når det skjer noe';
  @override
  String get noFavouriteSubTitle => 'Favoritttjenestene dine vises her';
  @override
  String get termsConditionsAccept => 'Vennligst godta vilkår og betingelser';
  @override
  String get disclaimer => 'Ansvarsfraskrivelse';
  @override
  String get disclaimerContent =>
      'Du blir bedt om betaling når bestillingen er fullført.';
  @override
  String get inputMustBeNumberOrDigit => 'Må være tall';
  @override
  String get requiredAfterCountryCode => 'påkrevd etter landskode';
  @override
  String get selectedOtherBookingTime =>
      'Valgt tid er allerede passert. Velg annen tid.';
  @override
  String get myServices => 'Mine tjenester';
  @override
  String get doYouWantToAssign => 'Vil du tildele';
  @override
  String get bidPrice => 'Budpris';
  @override
  String get accept => 'Aksepter';
  @override
  String get remove => 'Fjern';
  @override
  String get add => 'Legg til';
  @override
  String get createPostJobWithoutSelectService =>
      'Du må velge tjeneste for å opprette jobbforespørsel';
  @override
  String get selectCategory => 'Velg kategori';
  @override
  String get pleaseAddImage => 'Vennligst legg til bilde';
  @override
  String get selectedBookingTimeIsAlreadyPassed =>
      'Valgt tid er passert. Velg annen tid.';
  @override
  String get jobPrice => 'Jobbpris';
  @override
  String get estimatedPrice => 'Estimert pris';
  @override
  String get bidder => 'Budgivere';
  @override
  String get assignedProvider => 'Tildelt leverandør';
  @override
  String get myPostDetail => 'Min forespørsel';
  @override
  String get thankYou => 'Takk!';
  @override
  String get bookingConfirmedMsg => 'Bestillingen er bekreftet.';
  @override
  String get goToHome => 'Gå til forsiden';
  @override
  String get goToReview => 'Gå til anmeldelse';
  @override
  String get noServiceAdded => 'Ingen tjeneste lagt til';
  @override
  String get noPostJobFound => 'Ingen jobbforespørsel funnet';
  @override
  String get noPostJobFoundSubtitle =>
      'Når du legger ut en jobb, varsles leverandører, og du kan velge hvem som skal utføre jobben.';
  @override
  String get pleaseEnterValidOTP => 'Vennligst skriv inn gyldig OTP';
  @override
  String get confirmOTP => 'Bekreft OTP';
  @override
  String get sendingOTP => 'Sender OTP';
  @override
  String get pleaseSelectDifferentSlotThenPrevious =>
      'Velg annen tid enn forrige';
  @override
  String get pleaseSelectTheSlotsFirst => 'Velg tidspunkt først';
  @override
  String get editTimeSlotsBooking => 'Rediger bestillingstid';
  @override
  String get availableSlots => 'Tilgjengelige tider';
  @override
  String get noTimeSlots => 'Ingen tider';
  @override
  String get bookingDateAndSlot => 'Dato og tid for bestilling';
  @override
  String get extraCharges => 'Ekstrakostnader';
  @override
  String get chatCleared => 'Chat tømt';
  @override
  String get clearChat => 'Tøm chat';
  @override
  String get jobRequestSubtitle =>
      'Fant du ikke tjenesten? Du kan legge ut en forespørsel.';
  @override
  String get verified => 'Verifisert';
  @override
  String get theEnteredCodeIsInvalidPleaseTryAgain =>
      'Koden er ugyldig. Prøv igjen.';
  @override
  String get otpCodeIsSentToYourMobileNumber =>
      'OTP er sendt til mobilnummeret ditt';
  @override
  String get yourPaymentFailedPleaseTryAgain =>
      'Betalingen mislyktes. Prøv igjen.';
  @override
  String get yourPaymentHasBeenMadeSuccessfully => 'Betalingen er gjennomført.';
  @override
  String get transactionFailed => 'Transaksjonen mislyktes';
  @override
  String get lblStep3 => 'Steg 3';
  @override
  String get lblAvailableOnTheseDays => 'Tilgjengelig disse dagene';
  @override
  String get pleaseTryAgain => 'Vennligst prøv igjen';
  @override
  String get postJob => 'Legg ut jobb';
  @override
  String get package => 'Pakke';
  @override
  String get frequentlyBoughtTogether => 'Ofte bestilt sammen';
  @override
  String get endOn => 'Slutter';
  @override
  String get buy => 'Kjøp';
  @override
  String get includedServices => 'Inkluderte tjenester';
  @override
  String get includedInThisPackage => 'Inkludert i denne pakken';
  @override
  String get lblInvalidTransaction => 'Ugyldig transaksjon';
  @override
  String get getTheseServiceWithThisPackage =>
      'Disse tjenestene følger med pakken';
  @override
  String get lblNotValidUser => 'Du er ikke en gyldig bruker';
  @override
  String get lblSkip => 'Hopp over';
  @override
  String get lblChangeCountry => 'Bytt land';
  @override
  String get lblTimeSlotNotAvailable => 'Denne tiden er ikke ledig';
  @override
  String get lblAdd => 'legg til';
  @override
  String get lblThisService => 'denne tjenesten';
  @override
  String get lblYourCurrenciesNotSupport =>
      'Valutaen din støttes ikke av CinetPay';
  @override
  String get lblSignInFailed => 'Innlogging mislyktes';
  @override
  String get lblUserCancelled => 'Bruker avbrøt';
  @override
  String get lblTransactionCancelled => 'Transaksjonen er avbrutt';
  @override
  String get lblExample => 'Eksempel';
  @override
  String get lblCheckOutWithCinetPay => 'Betal med CinetPay';
  @override
  String get lblLocationPermissionDenied => 'Posisjonstilgang er avvist.';
  @override
  String get lblLocationPermissionDeniedPermanently =>
      'Posisjonstilgang er permanent avvist.';
  @override
  String get lblEnableLocation => 'Slå på posisjonstjenester.';
  @override
  String get lblNoUserFound => 'Ingen bruker funnet';
  @override
  String get lblUserNotCreated => 'Bruker ble ikke opprettet';
  @override
  String get lblTokenExpired => 'Sesjon utløpt';
  @override
  String get lblConfirmationForDeleteMsg => 'Vil du slette meldingen?';
  @override
  String get favouriteProvider => 'Favorittleverandør';
  @override
  String get noProviderFoundMessage => 'Favorittleverandørene dine vises her';
  @override
  String get personalInfo => 'Personlig info';
  @override
  String get essentialSkills => 'Ferdigheter';
  @override
  String get knownLanguages => 'Språk';
  @override
  String get authorBy => 'Av';
  @override
  String get views => 'Visninger';
  @override
  String get blogs => 'Blogger';
  @override
  String get noBlogsFound => 'Ingen blogger funnet';
  @override
  String get requestInvoice => 'Be om faktura';
  @override
  String get invoiceSubTitle => 'Skriv e-postadressen der du vil motta faktura';
  @override
  String get sentInvoiceText => 'Sjekk e-posten – faktura er sendt.';
  @override
  String get send => 'Send';
  @override
  String get published => 'Publisert';
  @override
  String get publish => 'Publiser';
  @override
  String get clearChatMessage => 'Vil du tømme denne chatten?';
  @override
  String get deleteMessage => 'Vil du slette?';
  @override
  String get accepted => 'Akseptert';
  @override
  String get onGoing => 'Pågår';
  @override
  String get inProgress => 'Pågår';
  @override
  String get failed => 'Mislyktes';
  @override
  String get pendingApproval => 'Venter på godkjenning';
  @override
  String get waiting => 'Venter';
  @override
  String get advancePaid => 'Forskuddsbetalt';
  @override
  String get insufficientBalanceMessage =>
      'Utilstrekkelig saldo. Velg annen betalingsmetode.';
  @override
  String get cinetPayNotSupportedMessage =>
      'CinetPay støttes ikke for valutaen din';
  @override
  String get walletBalance => 'Lommeboksaldo';
  @override
  String get payAdvance => 'Betal forskudd';
  @override
  String get advancePaymentMessage =>
      'Betal forskudd for å fullføre bestillingen';
  @override
  String get advancePayAmount => 'Forskuddsbeløp';
  @override
  String get remainingAmount => 'Gjenstående beløp';
  @override
  String get advancePayment => 'Betal forskudd';
  @override
  String get withExtraAndAdvanceCharge => 'Med ekstrakostnader og forskudd';
  @override
  String get withExtraCharge => 'Med ekstrakostnader';
  @override
  String get min => 'min';
  @override
  String get hour => 'time';
  @override
  String get customerRatingMessage => 'Del din erfaring';
  @override
  String get paymentHistory => 'Betalingshistorikk';
  @override
  String get message => 'Melding';
  @override
  String get wallet => 'Lommebok';
  @override
  String get payWithFlutterWave => 'Betal med Flutterwave';
  @override
  String get goodMorning => 'God morgen';
  @override
  String get goodAfternoon => 'God ettermiddag';
  @override
  String get goodEvening => 'God kveld';
  @override
  String get invalidURL => 'Ugyldig adresse';
  @override
  String get use24HourFormat => 'Bruk 24-timers format?';
  @override
  String get badRequest => 'Ugyldig forespørsel';
  @override
  String get forbidden => 'Tilgang nektet';
  @override
  String get pageNotFound => 'Siden finnes ikke';
  @override
  String get tooManyRequests => 'For mange forespørsler';
  @override
  String get internalServerError => 'Serverfeil';
  @override
  String get badGateway => 'Nettverksfeil';
  @override
  String get serviceUnavailable => 'Tjenesten er utilgjengelig';
  @override
  String get gatewayTimeout => 'Tidsavbrudd';
  @override
  String get pleaseWait => 'Vennligst vent';
  @override
  String get externalWallet => 'Ekstern lommebok';
  @override
  String get userNotFound => 'Bruker ikke funnet';
  @override
  String get requested => 'Forespurt';
  @override
  String get assigned => 'Tildelt';
  @override
  String get reload => 'Last på nytt';
  @override
  String get lblStripeTestCredential => 'Testkonto kan ikke betale mer enn 500';
  @override
  String get noDataFoundInFilter => 'Velg filter for å finne resultater';
  @override
  String get addYourCountryCode => 'Legg til landskode';
  @override
  String get couponCantApplied => 'Denne kupongen kan ikke brukes';
  @override
  String get priceAmountValidationMessage => 'Beløpet må være større enn 0';
  @override
  String get pleaseWaitWhileWeLoadChatDetails =>
      'Vennligst vent mens chat lastes…';
  @override
  String get isNotAvailableForChat => 'er ikke tilgjengelig for chat';
  @override
  String get connectWithFirebaseForChat => 'Koble til Firebase for chat';
  @override
  String get closeApp => 'Lukk app';
  @override
  String get providerAddedToFavourite => 'Leverandør lagt til i favoritter';
  @override
  String get providerRemovedFromFavourite =>
      'Leverandør fjernet fra favoritter';
  @override
  String get provideValidCurrentPasswordMessage =>
      'Skriv inn gyldig nåværende passord';
  @override
  String get copied => 'Kopiert';
  @override
  String get copyMessage => 'Kopier melding';
  @override
  String get messageDelete => 'Slett melding';
  @override
  String get pleaseChooseAnyOnePayment => 'Velg én betalingsmetode';
  @override
  String get myWallet => 'Min lommebok';
  @override
  String get balance => 'Saldo';
  @override
  String get topUpWallet => 'Fyll på lommebok';
  @override
  String get topUpAmountQuestion => 'Hvor mye vil du fylle på?';
  @override
  String get selectYourPaymentMethodToAddBalance =>
      'Velg betalingsmetode for å fylle på';
  @override
  String get proceedToTopUp => 'Fortsett til oppfyling';
  @override
  String get serviceAddedToFavourite => 'Tjeneste lagt til i favoritter';
  @override
  String get serviceRemovedFromFavourite => 'Tjeneste fjernet fra favoritter';
  @override
  String get firebaseRemoteCannotBe => 'Kan ikke koble til Firebase';
  @override
  String get close => 'Lukk';
  @override
  String get totalAmountShouldBeMoreThan => 'Totalbeløpet må være mer enn';
  @override
  String get totalAmountShouldBeLessThan => 'Totalbeløpet må være mindre enn';
  @override
  String get doYouWantToTopUpYourWallet => 'Vil du fylle på lommeboken nå?';
  @override
  String get chooseYourLocation => 'Velg posisjon';
  @override
  String get connect => 'Koble til';
  @override
  String get transactionId => 'Transaksjons-ID';
  @override
  String get at => 'kl.';
  @override
  String get appliedTaxes => 'MVA';
  @override
  String get accessDeniedContactYourAdmin =>
      'Tilgang nektet. Kontakt administrator.';
  @override
  String get yourWalletIsUpdated => 'Lommeboken er oppdatert!';
  @override
  String get by => 'av';
  @override
  String get noPaymentMethodFound => 'Ingen betalingsmetode funnet';
  @override
  String get theAmountShouldBeEntered => 'Beløpet må fylles inn';
  @override
  String get walletHistory => 'Lommebokhistorikk';
  @override
  String get debit => 'Debet';
  @override
  String get credit => 'Kredit';
  @override
  String get youCannotApplyThisCoupon => 'Du kan ikke bruke denne kupongen';
  @override
  String get basedOn => 'Basert på';
  @override
  String get serviceStatusPicMessage => 'Velg minst én bestillingsstatus';
  @override
  String get clearFilter => 'Fjern filter';
  @override
  String get bookingStatus => 'Bestillingsstatus';
  @override
  String get addOns => 'Tillegg';
  @override
  String get serviceAddOns => 'Tjenestetillegg';
  @override
  String get turnOn => 'På';
  @override
  String get turnOff => 'Av';
  @override
  String get serviceVisitType => 'Type besøk';
  @override
  String get thisServiceIsOnlineRemote =>
      'Denne tjenesten utføres på nett/fjernstyrt.';
  @override
  String get deleteMessageForAddOnService =>
      'Vil du fjerne dette tilleggstjenesten?';
  @override
  String get confirmation => 'Bekreftelse';
  @override
  String get pleaseNoteThatAllServiceMarkedCompleted =>
      'Merk at alle tillegg er merket som fullført.';
  @override
  String get writeHere => 'Skriv her';
  @override
  String get isAvailableGoTo =>
      'er tilgjengelig. Gå til Play Store og last ned ny versjon.';
  @override
  String get later => 'Senere';
  @override
  String get whyChooseMe => 'Hvorfor velge meg?';
  @override
  String get useThisCodeToGet => 'Bruk denne koden for';
  @override
  String get off => 'av';
  @override
  String get applied => 'Brukt';
  @override
  String get coupons => 'Kuponger';
  @override
  String get handymanList => 'Håndverkerliste';
  @override
  String get noHandymanFound => 'Ingen håndverker funnet';
  @override
  String get back => 'Tilbake';
  @override
  String get team => 'Team';
  @override
  String get whyChooseMeAs => 'Hvorfor velge meg som leverandør';
  @override
  String get reason => 'Grunn';
  @override
  String get pleaseEnterAddressAnd => 'Oppgi adresse og dato/tid';
  @override
  String get pleaseEnterYourAddress => 'Skriv inn adressen din';
  @override
  String get pleaseSelectBookingDate => 'Velg dato og tid';
  @override
  String get doYouWantTo => 'Vil du fjerne denne kupongen?';
  @override
  String get chooseDateTime => 'Velg dato og tid';
  @override
  String get airtelMoneyPayment => 'Airtel Money';
  @override
  String get recommendedForYou => 'Anbefalt for deg';
  @override
  String get paymentSuccess => 'Betaling fullført';
  @override
  String get redirectingToBookings => 'Videresender til bestillinger…';
  @override
  String get transactionIsInProcess => 'Transaksjon pågår…';
  @override
  String get pleaseCheckThePayment =>
      'Sjekk at betalingsforespørselen er sendt til nummeret ditt';
  @override
  String get enterYourMsisdnHere => 'Skriv inn mobilnummer her';
  @override
  String get theTransactionIsStill =>
      'Transaksjonen behandles fortsatt. Sjekk status senere.';
  @override
  String get transactionIsSuccessful => 'Transaksjonen er vellykket';
  @override
  String get incorrectPinHasBeen => 'Feil PIN er oppgitt';
  @override
  String get theUserHasExceeded =>
      'Brukeren har overskredet transaksjonsgrensen';
  @override
  String get theAmountUserIs => 'Beløpet er under minimumsgrensen';
  @override
  String get userDidnTEnterThePin => 'Brukeren oppga ikke PIN';
  @override
  String get transactionInPendingState =>
      'Transaksjon venter. Sjekk igjen senere.';
  @override
  String get userWalletDoesNot => 'Lommeboken har ikke nok penger';
  @override
  String get theTransactionWasRefused => 'Transaksjonen ble avvist';
  @override
  String get thisIsAGeneric => 'Generell avvisning';
  @override
  String get payeeIsAlreadyInitiated => 'Mottaker er ikke tilgjengelig';
  @override
  String get theTransactionWasTimed => 'Tidsavbrudd.';
  @override
  String get theTransactionWasNot => 'Transaksjonen ble ikke funnet.';
  @override
  String get xSignatureAndPayloadDid => 'Signatur stemmer ikke';
  @override
  String get encryptionKeyHasBeen => 'Krypteringsnøkkel hentet';
  @override
  String get couldNotFetchEncryption => 'Kunne ikke hente krypteringsnøkkel';
  @override
  String get transactionHasBeenExpired => 'Transaksjonen er utløpt';
  @override
  String get ambiguous => 'Uavklart';
  @override
  String get success => 'Vellykket';
  @override
  String get incorrectPin => 'Feil PIN';
  @override
  String get exceedsWithdrawalAmountLimitS => 'Overstiger uttaksgrense';
  @override
  String get invalidAmount => 'Ugyldig beløp';
  @override
  String get transactionIdIsInvalid => 'Transaksjons-ID er ugyldig';
  @override
  String get inProcess => 'Behandles';
  @override
  String get notEnoughBalance => 'Utilstrekkelig saldo';
  @override
  String get refused => 'Avvist';
  @override
  String get doNotHonor => 'Avvist';
  @override
  String get transactionNotPermittedTo => 'Transaksjon ikke tillatt';
  @override
  String get transactionTimedOut => 'Tidsavbrudd';
  @override
  String get transactionNotFound => 'Transaksjon ikke funnet';
  @override
  String get forBidden => 'Forbudt';
  @override
  String get successfullyFetchedEncryptionKey => 'Krypteringsnøkkel hentet';
  @override
  String get errorWhileFetchingEncryption => 'Feil ved henting av nøkkel';
  @override
  String get transactionExpired => 'Transaksjon utløpt';
  @override
  String get verifyEmail => 'Bekreft e-post';
  @override
  String get minRead => 'min lesning';
  @override
  String get loadingChats => 'Laster chatter…';
  @override
  String get monthly => 'Månedlig';
  @override
  String get noCouponsAvailableMsg => 'Ingen kuponger tilgjengelig';
  @override
  String get refundPolicy => 'Refusjonsregler';
  @override
  String get chooseAnyOnePayment => 'Velg én betalingsmetode';
  @override
  String get january => 'januar';
  @override
  String get february => 'februar';
  @override
  String get march => 'mars';
  @override
  String get april => 'april';
  @override
  String get may => 'mai';
  @override
  String get june => 'juni';
  @override
  String get july => 'juli';
  @override
  String get august => 'august';
  @override
  String get september => 'september';
  @override
  String get october => 'oktober';
  @override
  String get november => 'november';
  @override
  String get december => 'desember';
  @override
  String get monthName => 'Måned';
  @override
  String get mon => 'man';
  @override
  String get tue => 'tir';
  @override
  String get wed => 'ons';
  @override
  String get thu => 'tor';
  @override
  String get fri => 'fre';
  @override
  String get sat => 'lør';
  @override
  String get sun => 'søn';
  @override
  String get weekName => 'Uke';
  @override
  String get removeThisFile => 'Fjern denne filen';
  @override
  String get areYouSureWantToRemoveThisFile =>
      'Er du sikker på at du vil fjerne denne filen?';
  @override
  String get sendMessage => 'Send melding';
  @override
  String get youAreNotConnectedWithChatServer =>
      'Du er ikke koblet til chattserveren';
  @override
  String get NotConnectedWithChatServerMessage =>
      'Sjekk internett og prøv igjen';
  @override
  String get sentYouAMessage => 'sendte deg en melding';
  @override
  String get pushNotification => 'Push-varsler';
  @override
  String get yourBooking => 'Din bestilling';
  @override
  String get featuredServices => 'Utvalgte tjenester';
  @override
  String get postYourRequestAnd => 'Legg ut forespørselen din';
  @override
  String get newRequest => 'Ny forespørsel';
  @override
  String get upcomingBooking => 'Kommende bestilling';
  @override
  String get theUserHasDenied => 'Brukeren har nektet tilgang';
  @override
  String get helloGuest => 'Hei, gjest';
  @override
  String get eGCleaningPlumberPest => 'f.eks. rørlegger, rengjøring';
  @override
  String get ifYouDidnTFind => 'Fant du ikke det du lette etter?';
  @override
  String get popularServices => 'Populære tjenester';
  @override
  String get canTFindYourServices => 'Finner du ikke tjenesten?';
  @override
  String get trackProviderLocation => 'Spor leverandør';
  @override
  String get trackHandymanLocation => 'Spor håndverker';
  @override
  String get handymanLocation => 'Håndverkerens posisjon';
  @override
  String get providerLocation => 'Leverandørens posisjon';
  @override
  String get lastUpdatedAt => 'Sist oppdatert';
  @override
  String get track => 'Spor';
  @override
  String get handymanReached => 'Håndverkeren har ankommet';
  @override
  String get providerReached => 'Leverandøren har ankommet';
  @override
  String get lblBankDetails => 'Bankopplysninger';
  @override
  String get addBank => 'Legg til bank';
  @override
  String get bankList => 'Bankliste';
  @override
  String get lbldefault => 'Standard';
  @override
  String get setAsDefault => 'Sett som standard';
  @override
  String get aadharNumber => 'ID-nummer';
  @override
  String get panNumber => 'Skattenummer';
  @override
  String get lblPleaseEnterAccountNumber => 'Oppgi kontonummer';
  @override
  String get lblAccountNumberMustContainOnlyDigits =>
      'Kontonummer må kun inneholde tall';
  @override
  String get lblAccountNumberMustBetween11And16Digits =>
      'Kontonummer må ha 11–16 siffer';
  @override
  String get noBankDataTitle => 'Ingen bank lagt til';
  @override
  String get noBankDataSubTitle => 'Legg til bank for uttak';
  @override
  String get active => 'Aktiv';
  @override
  String get inactive => 'Inaktiv';
  @override
  String get deleteBankTitle => 'Slett bankkonto?';
  @override
  String get lblEdit => 'Rediger';
  @override
  String get iFSCCode => 'Bankkode';
  @override
  String get accountNumber => 'Kontonummer';
  @override
  String get bankName => 'Banknavn';
  @override
  String get withdraw => 'Ta ut';
  @override
  String get availableBalance => 'Tilgjengelig saldo';
  @override
  String get successful => 'Vellykket';
  @override
  String get yourWithdrawalRequestHasBeenSuccessfullySubmitted =>
      'Uttaksforespørselen er sendt inn.';
  @override
  String get eg3000 => 'f.eks. 3000';
  @override
  String get chooseBank => 'Velg bank';
  @override
  String get egCentralNationalBank => 'f.eks. DNB';
  @override
  String get withdrawRequest => 'Uttaksforespørsel';
  @override
  String get lblEnterAmount => 'Skriv inn beløp';
  @override
  String get pleaseAddLessThanOrEqualTo =>
      'Beløpet må være mindre enn eller lik';
  @override
  String get topUp => 'Fyll på';
  @override
  String get btnSave => 'Lagre';
  @override
  String get fullNameOnBankAccount => 'Fullt navn på konto';
  @override
  String get packageIsExpired => 'Pakken er utløpt';
  @override
  String get bookPackage => 'Bestill pakke';
  @override
  String get packageDescription => 'Pakkebeskrivelse';
  @override
  String get packagePrice => 'Pakkepris';
  @override
  String get online => 'Nett';
  @override
  String get noteAddressIsNot => 'Merk: Adresse er ikke endret';
  @override
  String get wouldYouLikeTo => 'Vil du bekrefte denne bestillingen?';
  @override
  String get packageName => 'Pakkenavn';
  @override
  String get feeAppliesForCancellations => 'avbestillingsgebyr gjelder innen';
  @override
  String get a => 'en';
  @override
  String get byConfirmingYouAgree => 'Ved å bekrefte godtar du';
  @override
  String get and => 'og';
  @override
  String get areYouSureYou => 'Er du sikker?';
  @override
  String get totalCancellationFee => 'Total avbestillingsgebyr';
  @override
  String get goBack => 'Tilbake';
  @override
  String get bookingCancelled => 'Bestilling avbrutt';
  @override
  String get yourBookingHasBeen => 'Bestillingen er avbrutt.';
  @override
  String get noteCheckYourBooking => 'Sjekk bestillingsdetaljene.';
  @override
  String get cancelledReason => 'Avbestillingsgrunn';
  @override
  String get refundPaymentDetails => 'Refusjonsdetaljer';
  @override
  String get refundOf => 'Refusjon av';
  @override
  String get refundAmount => 'Refusjonsbeløp';
  @override
  String get cancellationFee => 'Avbestillingsgebyr';
  @override
  String get advancedPayment => 'Forskuddsbetaling';
  @override
  String get hoursOfTheScheduled => 'timer før planlagt tid';
  @override
  String get open => 'Åpen';
  @override
  String get closed => 'Lukket';
  @override
  String get createBy => 'Opprettet av';
  @override
  String get repliedBy => 'Besvart av';
  @override
  String get closedBy => 'Lukket av';
  @override
  String get helpDesk => 'Kundeservice';
  @override
  String get addNew => 'Legg til ny';
  @override
  String get queryYet => 'Ingen henvendelser ennå';
  @override
  String get toSubmitYourProblems => 'Send inn spørsmål eller problemer';
  @override
  String get noRecordsFoundFor => 'Ingen poster funnet for';
  @override
  String get queries => 'Henvendelser';
  @override
  String get noActivityYet => 'Ingen aktivitet ennå';
  @override
  String get noRecordsFound => 'Ingen poster funnet';
  @override
  String get reply => 'Svar';
  @override
  String get eGDuringTheService => 'f.eks. under tjenesten';
  @override
  String get doYouWantClosedThisQuery => 'Vil du lukke denne henvendelsen?';
  @override
  String get markAsClosed => 'Merk som lukket';
  @override
  String get youCanMarkThis => 'Du kan lukke denne når problemet er løst';
  @override
  String get subject => 'Emne';
  @override
  String get eGDamagedFurniture => 'f.eks. skade på møbler';
  @override
  String get closedOn => 'Lukket';
  @override
  String get on => 'den';
  @override
  String get showMessage => 'Vis melding';
  @override
  String get yesterday => 'i går';
  @override
  String get chooseAction => 'Velg handling';
  @override
  String get chooseImage => 'Velg bilde';
  @override
  String get noteYouCanUpload => 'Du kan laste opp flere filer';
  @override
  String get removeImage => 'Fjern bilde';
  @override
  String get advancedRefund => 'Avansert refusjon';
  @override
  String get lblService => 'Tjeneste';
  @override
  String get dateRange => 'Datoområde';
  @override
  String get paymentType => 'Betalings type';
  @override
  String get reset => 'Tilbakestill';
  @override
  String get noStatusFound => 'Ingen status funnet';
  @override
  String get selectStartDateEndDate => 'Velg start- og sluttdato';
  @override
  String get handymanNotFound => 'Håndverker ikke funnet';
  @override
  String get providerNotFound => 'Leverandør ikke funnet';
  @override
  String get rateYourExperience => 'Vurder opplevelsen';
  @override
  String get weValueYourFeedback => 'Vi setter pris på tilbakemeldingen din';
  @override
  String get viewStatus => 'Se status';
  @override
  String get paymentInfo => 'Betalingsinformasjon';
  @override
  String get mobile => 'Mobil';
  @override
  String get to => 'til';
  @override
  String get chooseYourDateRange => 'Velg datoområde';
  @override
  String get asHandyman => 'som håndverker';
  @override
  String get passwordLengthShouldBe =>
      'Passordet må være mellom 8 og 14 tegn.';
  @override
  String get cash => 'Kontant';
  @override
  String get bank => 'Bank';
  @override
  String get razorPay => 'Razorpay';
  @override
  String get payPal => 'PayPal';
  @override
  String get stripe => 'Stripe';
  @override
  String get payStack => 'PayStack';
  @override
  String get flutterWave => 'Flutterwave';
  @override
  String get paytm => 'Paytm';
  @override
  String get airtelMoney => 'Airtel Money';
  @override
  String get cinet => 'CinetPay';
  @override
  String get midtrans => 'Midtrans';
  @override
  String get sadadPayment => 'Sadad';
  @override
  String get phonePe => 'PhonePe';
  @override
  String get inAppPurchase => 'Inngangsbetaling';
  @override
  String get pix => 'Pix';
  @override
  String get chooseWithdrawalMethod => 'Velg uttaksmetode';

  @override
  String get datePriceInfo => 'Dato / prisinfo';

  @override
  String get notAssigned => 'Ikke tildelt';

  @override
  String get noBiddersYet => 'Ingen budgivere ennå';

  @override
  String get noSubcategoriesFound => 'Ingen underkategorier funnet';

  @override
  String get subcategory => 'Underkategori';

  @override
  String get selectSubcategory => 'Velg underkategori';

  @override
  String get pleaseEnterValidDate =>
      'Vennligst skriv inn en gyldig dato (ÅÅÅÅ-MM-DD)';

  @override
  String get postJobTimedOutTryFromMyJobs =>
      'Tjenesten er lagret. Utsending av jobb tok for lang tid – prøv igjen fra Mine jobber.';

  @override
  String get serviceIncludedInThisPackage =>
      'Tjenester inkludert i denne pakken';

  @override
  String get lblPurchase => 'Kjøp';

  @override
  String get whatAreYouLookingFor => 'Hva leter du etter?';

  @override
  String get startSearchingYourService => 'Begynn å søke etter tjenesten din';

  @override
  String get postJobDataNotFound => 'Jobbdata ikke funnet.';

  @override
  String get failedToSendMessage => 'Kunne ikke sende melding';

  @override
  String get lblFrom => 'Fra';

  @override
  String get lblTo => 'Til';

  @override
  String get fileSizeShouldBeLessThan => 'Filstørrelsen må være mindre enn';

  @override
  String get upiApps => 'UPI-apper';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get subCategoryLabel => 'Underkategori';

  @override
  String get payWithUpiApps => 'Betal med UPI-apper';

  @override
  String get payWithCard => 'Betal med kort';

  @override
  String bookingCompleted(int count) =>
      '$count bestilling${count > 1 ? 'er' : ''} fullført';
}
