import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nmobile/components/box/body.dart';
import 'package:nmobile/components/button.dart';
import 'package:nmobile/components/header/header.dart';
import 'package:nmobile/components/label.dart';
import 'package:nmobile/consts/theme.dart';
import 'package:nmobile/helpers/global.dart';
import 'package:nmobile/helpers/permission.dart';
import 'package:nmobile/helpers/utils.dart';
import 'package:nmobile/l10n/localization_intl.dart';
import 'package:nmobile/plugins/nkn_wallet.dart';
import 'package:nmobile/schemas/contact.dart';
import 'package:nmobile/schemas/subscribers.dart';
import 'package:nmobile/schemas/topic.dart';
import 'package:nmobile/screens/contact/contact.dart';
import 'package:nmobile/utils/image_utils.dart';
import 'package:oktoast/oktoast.dart';

class ChannelMembersScreen extends StatefulWidget {
  static const String routeName = '/channel/members';

  final TopicSchema arguments;

  ChannelMembersScreen({this.arguments});

  @override
  _ChannelMembersScreenState createState() => _ChannelMembersScreenState();
}

class _ChannelMembersScreenState extends State<ChannelMembersScreen> {
  ScrollController _scrollController = ScrollController();
  List<ContactSchema> _subs = List<ContactSchema>();
  Permission _permissionHelper;

  _genContactList(List<SubscribersSchema> data) async {
    List<ContactSchema> list = List<ContactSchema>();

    for (int i = 0, length = data.length; i < length; i++) {
      SubscribersSchema item = data[i];
      var walletAddress = await NknWalletPlugin.pubKeyToWalletAddr(getPublicKeyByClientAddr(item.addr));
      String contactType = ContactType.stranger;
      if (item.addr == Global.currentClient.address) {
        contactType = ContactType.me;
      }
      ContactSchema contact = ContactSchema(clientAddress: item.addr, nknWalletAddress: walletAddress, type: contactType);
      await contact.createContact();
      var getContact = await ContactSchema.getContactByAddress(contact.clientAddress);
      list.add(getContact);
    }

    return list;
  }

  initAsync() async {
    LogUtil.v('initAsync');
    widget.arguments.querySubscribers().then((data) async {
      List<ContactSchema> list = List<ContactSchema>();

      for (var sub in data) {
        var walletAddress = await NknWalletPlugin.pubKeyToWalletAddr(getPublicKeyByClientAddr(sub.addr));
        String contactType = ContactType.stranger;
        if (sub.addr == Global.currentClient.address) {
          contactType = ContactType.me;
        }
        ContactSchema contact = ContactSchema(clientAddress: sub.addr, nknWalletAddress: walletAddress, type: contactType);
        await contact.createContact();
        var getContact = await ContactSchema.getContactByAddress(contact.clientAddress);
        list.add(getContact);
      }

      if (mounted) {
        setState(() {
          _subs = list;
        });
      }
    });

    await widget.arguments.getTopicCount();

    var data = await widget.arguments.querySubscribers();
    _subs = await _genContactList(data);
    if (widget.arguments.type == TopicType.private) {
      // get private meta
      var meta = await widget.arguments.getPrivateOwnerMeta();
      print(meta);
      LogUtil.v('==============$meta');
      _permissionHelper = Permission(accept: meta['accept'] ?? [], reject: meta['reject'] ?? []);
    }
    LogUtil.v('_permissionHelper');
    if (mounted) {
      setState(() {});
    }
    Global.removeTopicCache(widget.arguments.topic);
  }

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> topicWidget = <Widget>[
      Label(widget.arguments.topicName, type: LabelType.h2, dark: true),
    ];
    if (widget.arguments.type == TopicType.private) {
      topicWidget.insert(
        0,
        loadAssetIconsImage(
          'lock',
          width: 24,
          color: DefaultTheme.fontLightColor,
        ),
      );
    }

    return Scaffold(
      appBar: Header(
        title: NMobileLocalizations.of(context).channel_members.toUpperCase(),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: DefaultTheme.backgroundColor4,
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                constraints: BoxConstraints.expand(height: MediaQuery.of(context).size.height),
                color: DefaultTheme.backgroundColor4,
                child: Flex(direction: Axis.vertical, children: <Widget>[
                  Expanded(
                    flex: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(bottom: 24, left: 20, right: 20),
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: widget.arguments.avatarWidget(
                                  backgroundColor: DefaultTheme.backgroundLightColor.withAlpha(30),
                                  size: 48,
                                  fontColor: DefaultTheme.fontLightColor,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: topicWidget,
                                  ),
                                  Label('${widget.arguments.count ?? 0} ' + NMobileLocalizations.of(context).members, type: LabelType.bodyRegular, color: DefaultTheme.successColor)
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            Container(
              constraints: BoxConstraints.expand(height: MediaQuery.of(context).size.height - 190),
              child: BodyBox(
                padding: const EdgeInsets.only(top: 2, left: 20, right: 20),
                color: DefaultTheme.backgroundLightColor,
                child: Flex(
                  direction: Axis.vertical,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.only(top: 0),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          controller: _scrollController,
                          itemCount: _subs.length,
                          itemExtent: 72,
                          itemBuilder: (BuildContext context, int index) {
                            var contact = _subs[index];
                            return getItemView(contact);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  getNameLabel(ContactSchema contact) {
    String name = contact.name;
    if (widget.arguments.type == TopicType.private && contact.clientAddress != Global.currentClient.publicKey && widget.arguments.isOwner()) {
      var permissionStatus = _permissionHelper?.getSubscriberStatus(contact.clientAddress);
      name = name + '(${permissionStatus ?? NMobileLocalizations.of(context).loading})';
    }
    return Expanded(
      child: Label(
        name,
        type: LabelType.h3,
        overflow: TextOverflow.fade,
      ),
    );
  }

  getItemView(ContactSchema contact) {
    List<Widget> toolBtns = [];
    if (contact.clientAddress != Global.currentClient.publicKey) {
      toolBtns = getToolBtn(contact);
    }
    List<Widget> nameLabel = <Widget>[
      getNameLabel(contact),
    ];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          ContactScreen.routeName,
          arguments: contact,
        );
      },
      child: Container(
        padding: const EdgeInsets.only(),
        child: Flex(
          direction: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 0,
              child: Container(
                padding: const EdgeInsets.only(right: 16),
                alignment: Alignment.center,
                child: contact.avatarWidget(
                  size: 24,
                  backgroundColor: DefaultTheme.primaryColor.withAlpha(25),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.only(),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: DefaultTheme.backgroundColor2)),
                ),
                child: Flex(
                  direction: Axis.horizontal,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        height: 48.h,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: nameLabel,
                            ),
                            Label(
                              contact.clientAddress,
                              type: LabelType.label,
                              overflow: TextOverflow.fade,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 0,
                      child: Container(
                        alignment: Alignment.centerRight,
                        height: 44,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: toolBtns,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  getToolBtn(ContactSchema contact) {
    List<Widget> toolBtns = <Widget>[];
    if (widget.arguments.type == TopicType.private && widget.arguments.isOwner()) {
      var permissionStatus = _permissionHelper?.getSubscriberStatus(contact.clientAddress);
      Widget checkBtn = Button(
        onPressed: () async {
          EasyLoading.show();
          if (permissionStatus == PermissionStatus.rejected) {
            await widget.arguments.removeRejectPrivateMember(addr: contact.clientAddress);
          }
          EasyLoading.dismiss();
          showToast(NMobileLocalizations.of(context).success);
          setState(() {
            _permissionHelper.reject.removeWhere((x) => x['addr'] == contact.clientAddress);
            if (_permissionHelper.accept == null) {
              _permissionHelper.accept = [];
            }
            _permissionHelper.accept.add({'addr': contact.clientAddress});
          });
          Future.delayed(Duration(milliseconds: 500), () {
            widget.arguments.acceptPrivateMember(addr: contact.clientAddress);
          });
        },
        padding: const EdgeInsets.all(0),
        size: 24,
        icon: true,
        child: loadAssetIconsImage(
          'check',
          width: 16,
          color: DefaultTheme.successColor,
        ),
      );
      Widget trashBtn = Button(
        onPressed: () async {
          EasyLoading.show();
          if (permissionStatus == PermissionStatus.accepted) {
            await widget.arguments.removeAcceptPrivateMember(addr: contact.clientAddress);
          }
          EasyLoading.dismiss();
          showToast(NMobileLocalizations.of(context).success);
          setState(() {
            _permissionHelper.accept.removeWhere((x) => x['addr'] == contact.clientAddress);
            if (_permissionHelper.reject == null) {
              _permissionHelper.reject = [];
            }
            _permissionHelper.reject.add({'addr': contact.clientAddress});
          });
          Future.delayed(Duration(milliseconds: 500), () {
            widget.arguments.rejectPrivateMember(addr: contact.clientAddress);
          });
        },
        padding: const EdgeInsets.all(0),
        size: 24,
        icon: true,
        child: loadAssetIconsImage(
          'trash',
          width: 16,
          color: DefaultTheme.strongColor,
        ),
      );
      if (permissionStatus == PermissionStatus.accepted) {
        toolBtns.add(trashBtn);
      } else if (permissionStatus == PermissionStatus.rejected) {
        toolBtns.add(checkBtn);
      } else if (permissionStatus == PermissionStatus.pending) {
        toolBtns.add(checkBtn);
        toolBtns.add(trashBtn);
      }
    }

    return toolBtns;
  }
}