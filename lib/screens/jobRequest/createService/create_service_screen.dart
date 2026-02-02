import 'dart:convert';
import 'dart:io';
import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/chat_gpt_loder.dart';
import '../../../model/multi_language_request_model.dart';
import '../../../utils/configs.dart';
import '../../../component/responsive_container.dart';

class CreateServiceScreen extends StatefulWidget {
  final ServiceData? data;

  /// Optional pre-filled job request fields when opened from "New Request".
  final String? jobTitle;
  final String? jobDescription;
  final String? jobDate;

  CreateServiceScreen({
    this.data,
    this.jobTitle,
    this.jobDescription,
    this.jobDate,
  });

  @override
  _CreateServiceScreenState createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  UniqueKey formWidgetKey = UniqueKey();

  ImagePicker picker = ImagePicker();

  TextEditingController serviceNameCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();
  TextEditingController jobTitleCont = TextEditingController();
  TextEditingController jobDescriptionCont = TextEditingController();
  TextEditingController jobDateCont = TextEditingController();

  FocusNode serviceNameFocus = FocusNode();
  FocusNode descriptionFocus = FocusNode();
  FocusNode jobTitleFocus = FocusNode();
  FocusNode jobDescriptionFocus = FocusNode();
  FocusNode jobDateFocus = FocusNode();

  List<XFile> imageFiles = [];
  List<Attachments> attachmentsArray = [];
  List<String> typeList = [SERVICE_TYPE_FIXED, SERVICE_TYPE_HOURLY];
  List<CategoryData> categoryList = [];
  List<CategoryData> subCategoryList = []; // ✅ New list for subcategories

  CategoryData? selectedCategory;
  CategoryData? selectedSubCategory; // ✅ New variable for selected subcategory
  String serviceType = '';

  bool isUpdate = false;
  bool isServiceUpdated = false;

  Map<String, MultiLanguageRequest> translations = {};
  MultiLanguageRequest defaultLanguageTranslations = MultiLanguageRequest();

  @override
  void initState() {
    super.initState();
    jobDateCont.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (widget.jobTitle != null && widget.jobTitle!.trim().isNotEmpty) {
      jobTitleCont.text = widget.jobTitle!.trim();
    }
    if (widget.jobDescription != null &&
        widget.jobDescription!.trim().isNotEmpty) {
      jobDescriptionCont.text = widget.jobDescription!.trim();
    }
    if (widget.jobDate != null && widget.jobDate!.trim().isNotEmpty) {
      jobDateCont.text = widget.jobDate!.trim();
    }
    init();
    appStore.setSelectedLanguage(languageList().first);
  }

  Future<void> init() async {
    isUpdate = widget.data != null;

    if (isUpdate) {
      if (widget.data?.translations?.isNotEmpty ?? false) {
        translations = await widget.data!.translations!;
        defaultLanguageTranslations = await translations[DEFAULT_LANGUAGE]!;
      }

      serviceNameCont.text =
          widget.data?.translations?[DEFAULT_LANGUAGE]?.name.validate() ?? "";
      descriptionCont.text = widget
              .data?.translations?[DEFAULT_LANGUAGE]?.description
              .validate() ??
          "";
      imageFiles.addAll(
          widget.data!.attachments!.map((e) => XFile(e.validate().toString())));
      attachmentsArray.addAll(widget.data!.attachmentsArray.validate());
    }

    await getCategoryData();
  }

  Future<void> getCategoryData() async {
    appStore.setLoading(true);
    await getCategoryList(CATEGORY_LIST_ALL).then((value) {
      if (value.categoryList!.isNotEmpty) {
        categoryList.addAll(value.categoryList.validate());
      }

      if (isUpdate) {
        selectedCategory = value.categoryList!.firstWhere(
            (element) => element.id == widget.data!.categoryId.validate());
      }

      setState(() {});
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  // ✅ Fetch subcategories based on selected category
  Future<void> getSubCategoryData(int categoryId) async {
    appStore.setLoading(true);
    try {
      CategoryResponse response = await getSubCategoryList(catId: categoryId);

      subCategoryList.clear();
      if (response.categoryList != null && response.categoryList!.isNotEmpty) {
        subCategoryList.addAll(response.categoryList.validate());
      } else {
        toast('No subcategories found');
      }
    } catch (e) {
      toast(e.toString(), print: true);
    } finally {
      appStore.setLoading(false);
      setState(() {});
    }
  }

  Future<void> getMultipleFile() async {
    await picker.pickMultiImage().then((value) {
      imageFiles.addAll(value);
      setState(() {});
    });
  }

  Future<void> checkValidation(
      {required bool isSave, LanguageDataModel? code}) async {
    if (imageFiles.isEmpty) {
      return toast(language.pleaseAddImage);
    }

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);
      updateTranslation();

      if (!isSave) {
        appStore.setSelectedLanguage(code!);
        disposeAllTextFieldsController();
        getTranslation();
        await checkValidationLanguage();
        setState(() => formWidgetKey = UniqueKey());
      } else {
        showConfirmDialogCustom(
          context,
          title: language.confirmationRequestTxt,
          positiveText: language.lblYes,
          negativeText: language.lblNo,
          primaryColor: primaryColor,
          onAccept: (p0) async {
            await removeEnTranslations();
            final req = await _buildServiceRequest();
            _submitService(req, context);
          },
        );
      }
    }
  }

  removeEnTranslations() {
    if (translations.containsKey(DEFAULT_LANGUAGE)) {
      translations.remove(DEFAULT_LANGUAGE);
    }
  }

  Future<void> _submitService(req, context) async {
    try {
      appStore.setLoading(true);
      await sendMultiPartRequest(
        req,
        onSuccess: (data) async {
          appStore.setLoading(false);
          final decoded = jsonDecode(data);
          toast(decoded['message']?.toString() ?? language.save, print: true);

          // If this was a new service and job request fields are filled, create post job
          if (!isUpdate && jobTitleCont.text.trim().isNotEmpty) {
            // API may return service_id (root), data.id, or id
            final rawId = decoded['service_id'] ??
                decoded['data']?['id'] ??
                decoded['id'];
            final serviceId =
                rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
            if (serviceId != null && serviceId > 0) {
              try {
                final request = {
                  PostJob.postTitle: jobTitleCont.text.validate(),
                  PostJob.description: jobDescriptionCont.text.validate(),
                  PostJob.serviceId: [serviceId],
                  PostJob.price: jobDateCont.text.validate(),
                  PostJob.status: JOB_REQUEST_STATUS_REQUESTED,
                  PostJob.latitude: appStore.latitude,
                  PostJob.longitude: appStore.longitude,
                };
                await savePostJob(request);
              } catch (e) {
                toast(e.toString(), print: true);
              }
            }
          }
          finish(context, true);
        },
        onError: (error) {
          toast(error.toString(), print: true);
          appStore.setLoading(false);
        },
      ).catchError((e) {
        appStore.setLoading(false);
        toast(e.toString(), print: true);
      });
    } catch (e) {
      toast(e.toString());
    }
  }

  Future<MultipartRequest> _buildServiceRequest() async {
    MultipartRequest multiPartRequest =
        await getMultiPartRequest('service-save');
    multiPartRequest.fields[CreateService.name] =
        defaultLanguageTranslations.name.validate();
    multiPartRequest.fields[CreateService.description] =
        defaultLanguageTranslations.description.validate();
    multiPartRequest.fields[CreateService.type] = SERVICE_TYPE_FIXED;
    multiPartRequest.fields[CreateService.price] = '0';
    multiPartRequest.fields[CreateService.addedBy] =
        appStore.userId.toString().validate();
    multiPartRequest.fields[CreateService.providerId] =
        appStore.userId.toString();
    multiPartRequest.fields[CreateService.categoryId] =
        selectedCategory!.id.toString();
    multiPartRequest.fields[CreateService.status] = '1';
    multiPartRequest.fields[CreateService.duration] = "0";

    // ✅ Include Subcategory ID if selected
    if (selectedSubCategory != null) {
      multiPartRequest.fields['sub_category_id'] =
          selectedSubCategory!.id.toString();
    }

    log("multiPart Request: ${multiPartRequest.fields}");

    if (isUpdate) {
      multiPartRequest.fields[CreateService.id] =
          widget.data!.id.validate().toString();
    }

    if (translations.isNotEmpty) {
      multiPartRequest.fields[CreateService.translations] =
          jsonEncode(translations);
    }

    if (imageFiles.isNotEmpty) {
      List<XFile> tempImages = imageFiles
          .where((element) => !element.path.contains("https"))
          .toList();

      multiPartRequest.files.clear();
      await Future.forEach<XFile>(tempImages, (element) async {
        int i = tempImages.indexOf(element);
        multiPartRequest.files.add(await MultipartFile.fromPath(
            '${CreateService.serviceAttachment + i.toString()}', element.path));
      });

      if (tempImages.isNotEmpty)
        multiPartRequest.fields[CreateService.attachmentCount] =
            tempImages.length.toString();
    }

    multiPartRequest.headers.addAll(buildHeaderTokens());

    return multiPartRequest;
  }

  void updateTranslation() {
    appStore.setLoading(true);
    final languageCode = appStore.selectedLanguage.languageCode.validate();
    // Use job title/description when service name/description are empty (fields removed from UI)
    final name = serviceNameCont.text.trim().isEmpty
        ? jobTitleCont.text.validate()
        : serviceNameCont.text.validate();
    final description = descriptionCont.text.trim().isEmpty
        ? jobDescriptionCont.text.validate()
        : descriptionCont.text.validate();
    if (name.isEmpty && description.isEmpty) {
      translations.remove(languageCode);
    } else {
      if (languageCode != DEFAULT_LANGUAGE) {
        translations[languageCode] = translations[languageCode]?.copyWith(
              name: name,
              description: description,
            ) ??
            MultiLanguageRequest(name: name, description: description);
      } else {
        defaultLanguageTranslations = defaultLanguageTranslations.copyWith(
          name: name,
          description: description,
        );
      }
    }
    appStore.setLoading(false);
  }

  void getTranslation() {
    final languageCode = appStore.selectedLanguage.languageCode;
    if (languageCode == DEFAULT_LANGUAGE) {
      serviceNameCont.text = defaultLanguageTranslations.name.validate();
      descriptionCont.text = defaultLanguageTranslations.description.validate();
    } else {
      final translation = translations[languageCode] ?? MultiLanguageRequest();
      serviceNameCont.text = translation.name.validate();
      descriptionCont.text = translation.description.validate();
    }
    setState(() {});
  }

  void disposeAllTextFieldsController() {
    serviceNameCont.clear();
    descriptionCont.clear();
    setState(() {});
  }

  bool checkValidationLanguage() {
    if (appStore.selectedLanguage.languageCode == DEFAULT_LANGUAGE) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> removeAttachment({required int id}) async {
    appStore.setLoading(true);

    Map req = {
      CommonKeys.type: SERVICE_ATTACHMENT,
      CommonKeys.id: id,
    };

    await deleteImage(req).then((value) {
      attachmentsArray.validate().removeWhere((element) => element.id == id);
      isServiceUpdated = true;
      setState(() {});
      appStore.setLoading(false);
      toast(value.message.validate(), print: true);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    jobTitleCont.dispose();
    jobDescriptionCont.dispose();
    jobDateCont.dispose();
    jobTitleFocus.dispose();
    jobDescriptionFocus.dispose();
    jobDateFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        finish(context, isServiceUpdated);
        return Future.value(false);
      },
      child: AppScaffold(
        appBarTitle: language.createServiceRequest,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              8.height,
              Form(
                key: formKey,
                child: SingleChildScrollView(
                  key: formWidgetKey,
                  child: ResponsiveContainer(
                    padding: EdgeInsets.all(16),
                    maxWidth: 700,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: context.width(),
                          height: 120,
                          child: DottedBorderWidget(
                            color: primaryColor.withValues(alpha: 0.6),
                            strokeWidth: 1,
                            gap: 6,
                            radius: 12,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(selectImage,
                                    height: 25,
                                    width: 25,
                                    color: appStore.isDarkMode ? white : gray),
                                8.height,
                                Text(language.chooseImages,
                                    style: boldTextStyle()),
                              ],
                            ).center().onTap(borderRadius: radius(), () async {
                              getMultipleFile();
                            }),
                          ),
                        ),
                        HorizontalList(
                          itemCount: imageFiles.length,
                          itemBuilder: (context, i) {
                            return Stack(
                              alignment: Alignment.topRight,
                              children: [
                                if (imageFiles[i].path.contains("https"))
                                  CachedImageWidget(
                                          url: imageFiles[i].path,
                                          height: 90,
                                          fit: BoxFit.cover)
                                      .cornerRadiusWithClipRRect(16)
                                else
                                  Image.file(File(imageFiles[i].path),
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover)
                                      .cornerRadiusWithClipRRect(16),
                                Container(
                                  decoration: boxDecorationWithRoundedCorners(
                                      boxShape: BoxShape.circle,
                                      backgroundColor: primaryColor),
                                  margin: EdgeInsets.only(right: 8, top: 4),
                                  padding: EdgeInsets.all(4),
                                  child:
                                      Icon(Icons.close, size: 16, color: white),
                                ).onTap(() {
                                  imageFiles.removeAt(i);
                                  setState(() {});
                                }),
                              ],
                            );
                          },
                        ).paddingBottom(16).visible(imageFiles.isNotEmpty),
                        20.height,

                        /// Job request fields (when opened from "New Request")
                        AppTextField(
                          controller: jobTitleCont,
                          textFieldType: TextFieldType.NAME,
                          nextFocus: jobDescriptionFocus,
                          decoration: inputDecoration(context,
                              labelText: language.postJobTitle),
                        ),
                        16.height,
                        AppTextField(
                          controller: jobDescriptionCont,
                          textFieldType: TextFieldType.MULTILINE,
                          maxLines: 2,
                          focus: jobDescriptionFocus,
                          nextFocus: jobDateFocus,
                          enableChatGPT: appConfigurationStore.chatGPTStatus,
                          promptFieldInputDecorationChatGPT:
                              inputDecoration(context).copyWith(
                            hintText: language.writeHere,
                            fillColor: context.scaffoldBackgroundColor,
                            filled: true,
                          ),
                          testWithoutKeyChatGPT:
                              appConfigurationStore.testWithoutKey,
                          loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                          decoration: inputDecoration(context,
                              labelText: language.postJobDescription),
                        ),
                        16.height,
                        AppTextField(
                          controller: jobDateCont,
                          textFieldType: TextFieldType.OTHER,
                          focus: jobDateFocus,
                          decoration: inputDecoration(context,
                              labelText: language.lblEstimatedDate),
                          keyboardType: TextInputType.text,
                          validator: (s) {
                            if (s == null || s.isEmpty) return null;
                            final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                            if (dateRegex.hasMatch(s)) {
                              try {
                                DateFormat('yyyy-MM-dd').parseStrict(s);
                              } catch (e) {
                                return "Please enter a valid date (YYYY-MM-DD)";
                              }
                            }
                            return null;
                          },
                        ),
                        20.height,

                        /// CATEGORY
                        DropdownButtonFormField<CategoryData>(
                          decoration: inputDecoration(context,
                              labelText: language.lblCategory),
                          hint: Text(language.selectCategory,
                              style: secondaryTextStyle()),
                          initialValue: selectedCategory,
                          validator: (value) {
                            if (value == null) return errorThisFieldRequired;
                            return null;
                          },
                          dropdownColor: context.scaffoldBackgroundColor,
                          items: categoryList.map((data) {
                            return DropdownMenuItem<CategoryData>(
                              value: data,
                              child: Text(data.name.validate(),
                                  style: primaryTextStyle()),
                            );
                          }).toList(),
                          onChanged: isUpdate
                              ? null
                              : (CategoryData? value) async {
                                  selectedCategory = value!;
                                  selectedSubCategory = null;
                                  subCategoryList.clear();

                                  // ✅ Call new Laravel API function here
                                  await getSubCategoryData(
                                      selectedCategory!.id.validate());

                                  setState(() {});
                                },
                        ),

                        16.height,

                        /// SUBCATEGORY
                        16.height,
                        DropdownButtonFormField<CategoryData>(
                          decoration: inputDecoration(context,
                              labelText: 'Subcategory'),
                          hint: Text('Select Subcategory',
                              style: secondaryTextStyle()),
                          initialValue: selectedSubCategory,
                          validator: (value) {
                            if (value == null) return errorThisFieldRequired;
                            return null;
                          },
                          dropdownColor: context.scaffoldBackgroundColor,
                          items: subCategoryList.map((data) {
                            return DropdownMenuItem<CategoryData>(
                              value: data,
                              child: Text(data.name.validate(),
                                  style: primaryTextStyle()),
                            );
                          }).toList(),
                          onChanged: (CategoryData? value) {
                            selectedSubCategory = value!;
                            setState(() {});
                          },
                        ).visible(subCategoryList.isNotEmpty),

                        16.height,
                        AppButton(
                          text:
                              isUpdate ? language.lblUpdate : language.publish,
                          color: context.primaryColor,
                          width: context.width() >= 600 ? 400 : context.width(),
                          onTap: () {
                            checkValidation(isSave: true);
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
