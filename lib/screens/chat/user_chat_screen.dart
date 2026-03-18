import 'dart:async';
import 'dart:io';

import 'package:fiksOpp/component/loader_widget.dart';
import 'package:fiksOpp/main.dart';
import 'package:fiksOpp/model/chat_message_model.dart';
import 'package:fiksOpp/model/user_data_model.dart';
import 'package:fiksOpp/screens/chat/widget/chat_item_widget.dart';
import 'package:fiksOpp/services/notification_services.dart';
import 'package:fiksOpp/utils/colors.dart';
import 'package:fiksOpp/utils/common.dart';
import 'package:fiksOpp/utils/constant.dart';
import 'package:fiksOpp/utils/string_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/cached_image_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../services/chat_services.dart';
import '../../utils/configs.dart';
import '../../utils/getImage.dart';
import '../../utils/images.dart';
import 'send_file_screen.dart';

class UserChatScreen extends StatefulWidget {
  final UserData receiverUser;
  final bool isChattingAllow;

  UserChatScreen({required this.receiverUser, this.isChattingAllow = true});

  @override
  _UserChatScreenState createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen>
    with WidgetsBindingObserver {
  TextEditingController messageCont = TextEditingController();

  FocusNode messageFocus = FocusNode();

  UserData senderUser = UserData();

  StreamSubscription? _streamSubscription;

  int isReceiverOnline = 0;

  bool get isReceiverUserOnline => isReceiverOnline == 1;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    log("🔵 [CHAT DEBUG] ========== INIT STARTED ==========");
    log("🔵 [CHAT DEBUG] Receiver User Email: ${widget.receiverUser.email}");
    log("🔵 [CHAT DEBUG] Receiver User UID: ${widget.receiverUser.uid}");
    log("🔵 [CHAT DEBUG] Sender User Email: ${appStore.userEmail}");
    log("🔵 [CHAT DEBUG] Sender User UID: ${appStore.uid}");
    log("🔵 [CHAT DEBUG] Is Chatting Allowed: ${widget.isChattingAllow}");

    WidgetsBinding.instance.addObserver(this);

    //OneSignal.shared.disablePush(true);

    if (widget.receiverUser.uid.validate().isEmpty) {
      log("🔵 [CHAT DEBUG] Receiver UID is empty, fetching user by email...");
      await userService
          .getUser(email: widget.receiverUser.email.validate())
          .then((value) {
        widget.receiverUser.uid = value.uid;
        log("🔵 [CHAT DEBUG] ✅ Receiver UID fetched successfully: ${value.uid}");
      }).catchError((e) {
        log("🔴 [CHAT DEBUG] ❌ Error fetching receiver user: ${e.toString()}");
        toast(e.toString());
      });
    } else {
      log("🔵 [CHAT DEBUG] ✅ Receiver UID already exists: ${widget.receiverUser.uid}");
    }

    log("🔵 [CHAT DEBUG] Fetching sender user...");
    try {
      senderUser =
          await userService.getUser(email: appStore.userEmail.validate());
      log("🔵 [CHAT DEBUG] ✅ Sender user fetched: ${senderUser.displayName} (UID: ${senderUser.uid})");
    } catch (e) {
      log("🔴 [CHAT DEBUG] ❌ Error fetching sender user: ${e.toString()}");
    }

    appStore.setLoading(false);
    setState(() {});

    log("🔵 [CHAT DEBUG] Checking if receiver is in contacts...");
    bool isInContacts = await userService.isReceiverInContacts(
        senderUserId: appStore.uid.validate(),
        receiverUserId: widget.receiverUser.uid.validate());
    log("🔵 [CHAT DEBUG] Is receiver in contacts: $isInContacts");

    if (isInContacts) {
      log("🔵 [CHAT DEBUG] Setting unread status to true...");
      await chatServices
          .setUnReadStatusToTrue(
              senderId: appStore.uid.validate(),
              receiverId: widget.receiverUser.uid.validate())
          .then((_) {
        log("🔵 [CHAT DEBUG] ✅ Unread status set successfully");
      }).catchError((e) {
        log("🔴 [CHAT DEBUG] ❌ Error setting unread status: ${e.toString()}");
        toast(e.toString());
      });

      log("🔵 [CHAT DEBUG] Receiver ID: ${widget.receiverUser.uid}");
      log("🔵 [CHAT DEBUG] Setting online count to 1...");
      chatServices.setOnlineCount(
          senderId: widget.receiverUser.uid.validate(),
          receiverId: appStore.uid.validate(),
          status: 1);

      log("🔵 [CHAT DEBUG] Setting up online status listener...");
      _streamSubscription = chatServices
          .isReceiverOnline(
              senderId: appStore.uid.validate(),
              receiverUserId: widget.receiverUser.uid.validate())
          .listen(
        (event) {
          isReceiverOnline = event.isOnline.validate();
          log("🔵 [CHAT DEBUG] ====== Online Status Changed: $isReceiverOnline ======");
        },
        onError: (error) {
          log("🔴 [CHAT DEBUG] ❌ Error in online status stream: ${error.toString()}");
        },
        onDone: () {
          log("🔵 [CHAT DEBUG] Online status stream closed");
        },
      );
      log("🔵 [CHAT DEBUG] ✅ Online status listener set up successfully");
    } else {
      log("🔵 [CHAT DEBUG] ⚠️ Receiver not in contacts, will add when first message is sent");
    }

    log("🔵 [CHAT DEBUG] ========== INIT COMPLETED ==========");
  }

  //region Widget
  Widget _buildChatFieldWidget() {
    return Row(
      children: [
        AppTextField(
          textFieldType: TextFieldType.OTHER,
          controller: messageCont,
          textStyle: primaryTextStyle(),
          minLines: 1,
          onFieldSubmitted: (s) {
            sendMessages();
          },
          focus: messageFocus,
          cursorHeight: 20,
          maxLines: 5,
          cursorColor: appStore.isDarkMode ? Colors.white : Colors.black,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          suffix: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Transform.rotate(
                    angle: -0.75, child: Icon(Icons.attach_file_outlined)),
                onPressed: () {
                  if (!appStore.isLoading) {
                    _handleDocumentClick();
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.camera_alt_outlined),
                onPressed: () {
                  if (!appStore.isLoading) {
                    _handleCameraClick();
                  }
                },
              ),
            ],
          ),
          decoration: inputDecoration(context).copyWith(
              hintText: language.message, hintStyle: secondaryTextStyle()),
        ).expand(),
        8.width,
        Container(
          decoration: boxDecorationDefault(
              borderRadius: radius(80), color: primaryColor),
          child: IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () {
              sendMessages();
            },
          ),
        )
      ],
    );
  }

  //endregion

  //region Methods
  Future<void> sendMessages({
    bool isFile = false,
    List<String> attachmentFiles = const [],
  }) async {
    log("🟢 [CHAT DEBUG] ========== SEND MESSAGE STARTED ==========");
    log("🟢 [CHAT DEBUG] Is File: $isFile");
    log("🟢 [CHAT DEBUG] Attachment Files Count: ${attachmentFiles.length}");
    log("🟢 [CHAT DEBUG] Message Text: ${messageCont.text}");
    log("🟢 [CHAT DEBUG] App Store Loading: ${appStore.isLoading}");

    if (appStore.isLoading) {
      log("🟡 [CHAT DEBUG] ⚠️ App is loading, aborting send message");
      return;
    }

    // If Message TextField is Empty.
    if (messageCont.text.trim().isEmpty && !isFile) {
      log("🟡 [CHAT DEBUG] ⚠️ Message is empty and not a file, requesting focus");
      messageFocus.requestFocus();
      return;
    } else if (isFile && attachmentFiles.isEmpty) {
      log("🟡 [CHAT DEBUG] ⚠️ File message but no attachments");
      return;
    }

    // Making Request for sending data to firebase
    ChatMessageModel data = ChatMessageModel();

    data.receiverId = widget.receiverUser.uid;
    data.senderId = appStore.uid;
    data.message = messageCont.text;
    data.isMessageRead = isReceiverOnline == 1;
    data.createdAt = DateTime.now().millisecondsSinceEpoch;
    data.createdAtTime = Timestamp.now();
    data.updatedAtTime = Timestamp.now();
    data.messageType = isFile ? MessageType.Files.name : MessageType.TEXT.name;
    data.attachmentfiles = attachmentFiles;

    log("🟢 [CHAT DEBUG] Message Data Prepared:");
    log("🟢 [CHAT DEBUG] - Receiver ID: ${data.receiverId}");
    log("🟢 [CHAT DEBUG] - Sender ID: ${data.senderId}");
    log("🟢 [CHAT DEBUG] - Message: ${data.message}");
    log("🟢 [CHAT DEBUG] - Message Type: ${data.messageType}");
    log("🟢 [CHAT DEBUG] - Is Read: ${data.isMessageRead}");
    log("🟢 [CHAT DEBUG] - Created At: ${data.createdAt}");
    log("🟢 [CHAT DEBUG] - Attachments: ${data.attachmentfiles?.length ?? 0}");
    log('🟢 [CHAT DEBUG] ChatMessageModel JSON: ${data.toJson()}');

    messageCont.clear();

    bool isInContacts = await userService.isReceiverInContacts(
        senderUserId: appStore.uid.validate(),
        receiverUserId: widget.receiverUser.uid.validate());
    log("🟢 [CHAT DEBUG] Is receiver in contacts: $isInContacts");

    if (!isInContacts) {
      log("🟢 [CHAT DEBUG] ========== Adding To Contacts ==========");
      log("🟢 [CHAT DEBUG] Sender ID: ${data.senderId}");
      log("🟢 [CHAT DEBUG] Receiver ID: ${data.receiverId}");
      log("🟢 [CHAT DEBUG] Receiver Name: ${widget.receiverUser.displayName.validate()}");
      log("🟢 [CHAT DEBUG] Sender Name: ${senderUser.displayName.validate()}");

      try {
        await chatServices.addToContacts(
          senderId: data.senderId,
          receiverId: data.receiverId,
          receiverName: widget.receiverUser.displayName.validate(),
          senderName: senderUser.displayName.validate(),
        );
        log("🟢 [CHAT DEBUG] ✅ Successfully added to contacts");

        log("🟢 [CHAT DEBUG] Setting up online status listener after adding to contacts...");
        _streamSubscription?.cancel();
        _streamSubscription = chatServices
            .isReceiverOnline(
                senderId: appStore.uid.validate(),
                receiverUserId: widget.receiverUser.uid.validate())
            .listen(
          (event) {
            isReceiverOnline = event.isOnline.validate();
            log("🟢 [CHAT DEBUG] ====== Online Status: $isReceiverOnline ======");
          },
          onError: (error) {
            log("🔴 [CHAT DEBUG] ❌ Error in online status stream: ${error.toString()}");
          },
        );
        log("🟢 [CHAT DEBUG] ✅ Online status listener set up");
      } catch (e) {
        log("🔴 [CHAT DEBUG] ❌ Error adding to contacts: ${e.toString()}");
      }
    }

    log("🟢 [CHAT DEBUG] ------- Calling addMessage -------");
    try {
      DocumentReference messageRef = await chatServices.addMessage(data);
      log("🟢 [CHAT DEBUG] ✅ Message Successfully Added to Firebase");
      log("🟢 [CHAT DEBUG] Message Document Reference: ${messageRef.path}");

      // todo : remove this
      isReceiverOnline = 0;
      log("🟢 [CHAT DEBUG] Is Receiver Online: $isReceiverOnline");

      if (isReceiverOnline != 1) {
        log("🟢 [CHAT DEBUG] Receiver is offline, sending push notification...");

        /// Send Notification
        NotificationService()
            .sendPushNotifications(
          appStore.userFullName,
          data.message.validate(),
          image: data.attachmentfiles == null || data.attachmentfiles!.isEmpty
              ? null
              : data.attachmentfiles!.first,
          receiverUser: widget.receiverUser,
          senderUserData: senderUser,
        )
            .then((_) {
          log("🟢 [CHAT DEBUG] ✅ Push notification sent successfully");
        }).catchError((e) {
          log("🔴 [CHAT DEBUG] ❌ Notification Error: ${e.toString()}");
        });
      } else {
        log("🟢 [CHAT DEBUG] Receiver is online, skipping notification");
      }

      /// Save receiverId to Sender Doc.
      log("🟢 [CHAT DEBUG] Saving receiverId to sender contacts...");
      userService
          .saveToContacts(
              senderId: appStore.uid,
              receiverId: widget.receiverUser.uid.validate())
          .then((value) {
        log("🟢 [CHAT DEBUG] ✅ ReceiverId saved to Sender Doc");
      }).catchError((e) {
        log("🔴 [CHAT DEBUG] ❌ Error saving receiverId to sender: ${e.toString()}");
      });

      /// Save senderId to Receiver Doc.
      log("🟢 [CHAT DEBUG] Saving senderId to receiver contacts...");
      userService
          .saveToContacts(
              senderId: widget.receiverUser.uid.validate(),
              receiverId: appStore.uid)
          .then((value) {
        log("🟢 [CHAT DEBUG] ✅ SenderId saved to Receiver Doc");
      }).catchError((e) {
        log("🔴 [CHAT DEBUG] ❌ Error saving senderId to receiver: ${e.toString()}");
      });

      log("🟢 [CHAT DEBUG] ========== SEND MESSAGE COMPLETED ==========");
    } catch (e, stackTrace) {
      log("🔴 [CHAT DEBUG] ❌ Error adding message: ${e.toString()}");
      log("🔴 [CHAT DEBUG] Stack Trace: $stackTrace");
      toast("${language.failedToSendMessage}: ${e.toString()}");
    }
  }

  //endregion

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      chatServices.setOnlineCount(
          senderId: widget.receiverUser.uid.validate(),
          receiverId: appStore.uid.validate(),
          status: 0);
    }

    if (state == AppLifecycleState.paused) {
      chatServices.setOnlineCount(
          senderId: widget.receiverUser.uid.validate(),
          receiverId: appStore.uid.validate(),
          status: 0);
    }
    if (state == AppLifecycleState.resumed) {
      chatServices.setOnlineCount(
          senderId: widget.receiverUser.uid.validate(),
          receiverId: appStore.uid.validate(),
          status: 1);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    chatServices.setOnlineCount(
        senderId: widget.receiverUser.uid.validate(),
        receiverId: appStore.uid.validate(),
        status: 0);

    _streamSubscription?.cancel();

    setStatusBarColor(transparentColor,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool effectiveChatAllowed =
        widget.isChattingAllow && appConfigurationStore.isEnableChat;

    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.primaryColor,
          leadingWidth: context.width(),
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: context.primaryColor,
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light),
          leading: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.symmetric(horizontal: 8),
                onPressed: () {
                  finish(context);
                },
                icon: ic_arrow_left.iconImage(color: Colors.white),
              ),
              CachedImageWidget(
                  url: widget.receiverUser.profileImage.validate(),
                  height: 36,
                  circle: true,
                  fit: BoxFit.cover),
              12.width,
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.receiverUser.firstName.validate() + " " + widget.receiverUser.lastName.validate()}",
                    style: boldTextStyle(color: white, size: APP_BAR_TEXT_SIZE),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ).expand(),
              40.width,
            ],
          ),
          actions: [
            PopupMenuButton(
              onSelected: (index) {
                if (index == 0) {
                  showConfirmDialogCustom(
                    context,
                    positiveText: language.lblYes,
                    negativeText: language.lblNo,
                    primaryColor: context.primaryColor,
                    title: language.clearChatMessage,
                    onAccept: (c) async {
                      appStore.setLoading(true);
                      await chatServices
                          .clearAllMessages(
                              senderId: appStore.uid,
                              receiverId: widget.receiverUser.uid.validate())
                          .then((value) {
                        toast(language.chatCleared);
                        hideKeyboard(context);
                      }).catchError((e) {
                        toast(e);
                      });
                      appStore.setLoading(false);
                    },
                  );
                }
              },
              color: context.cardColor,
              icon: Icon(Icons.more_vert_sharp, color: Colors.white),
              itemBuilder: (context) {
                List<PopupMenuItem> list = [];
                list.add(
                  PopupMenuItem(
                    value: 0,
                    child: Text(language.clearChat, style: primaryTextStyle()),
                  ),
                );
                return list;
              },
            )
          ],
        ),
        body: SizedBox(
          height: context.height(),
          width: context.width(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: effectiveChatAllowed ? 80 : 0),
                child: FirestorePagination(
                  reverse: true,
                  isLive: true,
                  padding:
                      EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 0),
                  physics: BouncingScrollPhysics(),
                  query: chatServices.chatMessagesWithPagination(
                      senderId: appStore.uid.validate(),
                      receiverUserId: widget.receiverUser.uid.validate()),
                  initialLoader: LoaderWidget(),
                  limit: PER_PAGE_CHAT_LIST_COUNT,
                  onEmpty: NoDataWidget(
                    title: language.noConversation,
                    imageWidget: EmptyStateWidget(),
                  ),
                  shrinkWrap: true,
                  viewType: ViewType.list,
                  itemBuilder: (context, snap, index) {
                    try {
                      ChatMessageModel data = ChatMessageModel.fromJson(
                          snap[index].data() as Map<String, dynamic>);
                      data.isMe = data.senderId == appStore.uid;
                      data.chatDocumentReference = snap[index].reference;

                      log("🟣 [CHAT DEBUG] Message loaded - Index: $index, IsMe: ${data.isMe}, Type: ${data.messageType}, Message: ${data.message?.substring(0, data.message!.length > 50 ? 50 : data.message!.length)}");

                      return ChatItemWidget(chatItemData: data);
                    } catch (e) {
                      log("🔴 [CHAT DEBUG] ❌ Error parsing message at index $index: ${e.toString()}");
                      return SizedBox.shrink();
                    }
                  },
                ),
              ),
              if (effectiveChatAllowed)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildChatFieldWidget(),
                ),
              Observer(
                  builder: (context) =>
                      LoaderWidget().visible(appStore.isLoading)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDocumentClick() async {
    appStore.setLoading(true);
    await pickFiles(
      allowedExtensions: chatFilesAllowedExtensions,
      maxFileSizeMB: max_acceptable_file_size,
      type: FileType.custom,
    ).then((pickedfiles) async {
      await handleUploadAndSendFiles(pickedfiles);
    }).catchError((e) {
      toast(e);
      log('ChatServices().uploadFiles Err: ${e}');
      return;
    }).whenComplete(() => appStore.setLoading(false));
  }

  Future<void> _handleCameraClick() async {
    GetImage(ImageSource.camera, path: (path, name, xFile) async {
      log('Path camera : ${path.toString()} name $name');
      await handleUploadAndSendFiles([File(xFile.path)]);
      setState(() {});
    });
  }

  Future<void> handleUploadAndSendFiles(List<File> pickedfiles) async {
    log("🟡 [CHAT DEBUG] ========== HANDLE UPLOAD FILES STARTED ==========");
    log("🟡 [CHAT DEBUG] Files count: ${pickedfiles.length}");

    if (pickedfiles.isEmpty) {
      log("🟡 [CHAT DEBUG] ⚠️ No files to upload");
      return;
    }

    for (int i = 0; i < pickedfiles.length; i++) {
      log("🟡 [CHAT DEBUG] File $i: ${pickedfiles[i].path} (${pickedfiles[i].lengthSync()} bytes)");
    }

    await SendFilePreviewScreen(pickedfiles: pickedfiles)
        .launch(context)
        .then((value) async {
      log("🟡 [CHAT DEBUG] File preview screen returned");
      log("🟡 [CHAT DEBUG] Return value: $value");
      log("🟡 [CHAT DEBUG] Text value: ${value[MessageType.TEXT.name]}");
      log("🟡 [CHAT DEBUG] Files value: ${value[MessageType.Files.name]}");
      log("🟡 [CHAT DEBUG] Files type: ${value[MessageType.Files.name].runtimeType}");

      if (value[MessageType.Files.name] is List<File>) {
        pickedfiles = value[MessageType.Files.name];
        log("🟡 [CHAT DEBUG] Updated files list, new count: ${pickedfiles.length}");
      }

      if (value[MessageType.TEXT.name] is String) {
        messageCont.text = value[MessageType.TEXT.name];
        log("🟡 [CHAT DEBUG] Message text set: ${messageCont.text}");
      }

      if (messageCont.text.trim().isNotEmpty || pickedfiles.isNotEmpty) {
        log("🟡 [CHAT DEBUG] Starting file upload...");
        appStore.setLoading(true);
        await ChatServices()
            .uploadFiles(pickedfiles)
            .then((attached_files) async {
          log("🟡 [CHAT DEBUG] ✅ Files uploaded successfully");
          log("🟡 [CHAT DEBUG] Attached files count: ${attached_files.length}");
          for (int i = 0; i < attached_files.length; i++) {
            log("🟡 [CHAT DEBUG] Attached file $i: ${attached_files[i]}");
          }

          if (attached_files.isEmpty) {
            log("🟡 [CHAT DEBUG] ⚠️ No files were uploaded");
            return;
          }

          log("🟡 [CHAT DEBUG] Sending message with attachments...");
          await sendMessages(isFile: true, attachmentFiles: attached_files)
              .whenComplete(() {
            log("🟡 [CHAT DEBUG] ✅ Message with attachments sent");
            appStore.setLoading(false);
          });
        }).catchError((e, stackTrace) {
          log("🔴 [CHAT DEBUG] ❌ ChatServices().uploadFiles Error: ${e.toString()}");
          log("🔴 [CHAT DEBUG] Stack Trace: $stackTrace");
          toast(e);
          return;
        }).whenComplete(() {
          appStore.setLoading(false);
          log("🟡 [CHAT DEBUG] ========== HANDLE UPLOAD FILES COMPLETED ==========");
        });
      } else {
        log("🟡 [CHAT DEBUG] ⚠️ No text or files to send");
      }
    }).catchError((e) {
      log("🔴 [CHAT DEBUG] ❌ Error in SendFilePreviewScreen: ${e.toString()}");
    });
  }
}
