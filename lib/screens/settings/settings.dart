import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nmobile/blocs/global/global_bloc.dart';
import 'package:nmobile/blocs/global/global_event.dart';
import 'package:nmobile/blocs/global/global_state.dart';
import 'package:nmobile/components/box/body.dart';
import 'package:nmobile/components/dialog/bottom.dart';
import 'package:nmobile/components/header/header.dart';
import 'package:nmobile/components/label.dart';
import 'package:nmobile/components/select_list/select_list_item.dart';
import 'package:nmobile/consts/theme.dart';
import 'package:nmobile/helpers/global.dart';
import 'package:nmobile/helpers/local_notification.dart';
import 'package:nmobile/helpers/local_storage.dart';
import 'package:nmobile/helpers/secure_storage.dart';
import 'package:nmobile/helpers/settings.dart';
import 'package:nmobile/helpers/utils.dart';
import 'package:nmobile/l10n/localization_intl.dart';
import 'package:nmobile/schemas/wallet.dart';
import 'package:nmobile/screens/advice_page.dart';
import 'package:nmobile/screens/select.dart';
import 'package:nmobile/services/local_authentication_service.dart';
import 'package:nmobile/utils/const_utils.dart';
import 'package:nmobile/utils/extensions.dart';
import 'package:oktoast/oktoast.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  final LocalStorage _localStorage = LocalStorage();
  final SecureStorage _secureStorage = SecureStorage();
  GlobalBloc _globalBloc;
  StreamSubscription _globalBlocSubs;
  List<SelectListItem> _languageList;
  String _currentLanguage;
  List<SelectListItem> _localNotificationTypeList;
  String _currentLocalNotificationType;
  String _authTypeString;
  bool _authSelected = false;

  @override
  void initState() {
    super.initState();
    initData();
    _globalBloc = BlocProvider.of<GlobalBloc>(context);
    _globalBlocSubs = _globalBloc.listen((state) {
      if (state is LocaleUpdated) {
        if (_languageList != null) {
          var item = _languageList.firstWhere((x) => x.value == state.locale, orElse: () => null);
          if (item != null) {
            setState(() {
              _currentLanguage = item.text;
            });
          }
        }
      }
    });
    initAsync();
  }

  initAsync() async {
    final _localAuth = await LocalAuthenticationService.instance;
    _authSelected = _localAuth.isProtectionEnabled;
    if (_localAuth.authType == BiometricType.face) {
      _authTypeString = NL10ns.of(Global.appContext).face_id;
    } else if (_localAuth.authType == BiometricType.fingerprint) {
      _authTypeString = NL10ns.of(Global.appContext).touch_id;
    }
    setState(() {});
  }

  initData() {
    _languageList = <SelectListItem>[
      SelectListItem(
        text: NL10ns.of(Global.appContext).auto,
        value: 'auto',
      ),
      SelectListItem(
        text: '简体中文',
        value: 'zh',
      ),
      SelectListItem(
        text: 'English',
        value: 'en',
      ),
    ];

    _localNotificationTypeList = <SelectListItem>[
      SelectListItem(
        text: NL10ns.of(Global.appContext).local_notification_only_name,
        value: 0,
      ),
      SelectListItem(
        text: NL10ns.of(Global.appContext).local_notification_both_name_message,
        value: 1,
      ),
      SelectListItem(
        text: NL10ns.of(Global.appContext).local_notification_none_display,
        value: 2,
      ),
    ];

    if (Global.locale == null) {
      _currentLanguage = NL10ns.of(Global.appContext).auto;
    } else {
      _currentLanguage = _languageList.firstWhere((x) => x.value == Global.locale, orElse: () => null)?.text ?? NL10ns.of(Global.appContext).auto;
    }

    if (Settings.localNotificationType == null) {
      _currentLocalNotificationType = NL10ns.of(Global.appContext).local_notification_only_name;
    } else {
      _currentLocalNotificationType = _localNotificationTypeList?.firstWhere((x) => x.value == Settings.localNotificationType, orElse: () => null)?.text ??
          NL10ns.of(Global.appContext).local_notification_only_name;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _globalBlocSubs?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    initData();

    String showVersion = Global.version;
    if (Platform.isIOS){
      showVersion = Global.versionFull;
    }

    return Scaffold(
      backgroundColor: DefaultTheme.primaryColor,
      appBar: Header(
        titleChild: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Label(
            NL10ns.of(context).menu_settings,
            type: LabelType.h2,
          ),
        ),
        hasBack: false,
        backgroundColor: DefaultTheme.primaryColor,
      ),
      body: BodyBox(
        padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.only(bottom: 100.h),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Label(
                      NL10ns.of(context).general,
                      type: LabelType.h3,
                    ),
                  ],
                ),
              ),
              Container(
                  decoration: BoxDecoration(
                    color: DefaultTheme.backgroundLightColor,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Column(children: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FlatButton(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(12))),
                        onPressed: () async {
                          Navigator.pushNamed(context, SelectScreen.routeName, arguments: {
                            SelectScreen.title: NL10ns.of(context).change_language,
                            SelectScreen.selectedValue: Global.locale ?? 'auto',
                            SelectScreen.list: _languageList,
                          }).then((lang) {
                            if (lang != null) {
                              _globalBloc.add(UpdateLanguage(lang));
                            }
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Label(
                              NL10ns.of(context).language,
                              type: LabelType.bodyRegular,
                              color: DefaultTheme.fontColor1,
                              height: 1,
                            ),
                            Row(
                              children: <Widget>[
                                Label(
                                  _currentLanguage,
                                  type: LabelType.bodyRegular,
                                  color: DefaultTheme.fontColor2,
                                  height: 1,
                                ),
                                SvgPicture.asset(
                                  'assets/icons/right.svg',
                                  width: 24,
                                  color: DefaultTheme.fontColor2,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ])),
              _authTypeString == null
                  ? Container()
                  : Column(children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Label(
                              NL10ns.of(context).security,
                              type: LabelType.h3,
                            ),
                          ],
                        ),
                      ),
                      Container(
                          decoration: BoxDecoration(
                            color: DefaultTheme.backgroundLightColor,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Column(children: <Widget>[
                            SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: FlatButton(
                                    padding: const EdgeInsets.only(left: 16, right: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(12))),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                                      Label(
                                        _authTypeString ?? '',
                                        type: LabelType.bodyRegular,
                                        color: DefaultTheme.fontColor1,
                                        height: 1,
                                      ),
                                      Row(children: <Widget>[
                                        CupertinoSwitch(
                                            value: _authSelected,
                                            activeColor: DefaultTheme.primaryColor,
                                            onChanged: (value) async {
                                              changeAuthAction(value);
                                            })
                                      ])
                                    ]),
                                    onPressed: () {}))
                          ]))
                    ]),
              Row(
                children: <Widget>[
                  Label(
                    NL10ns.of(context).notification,
                    type: LabelType.h3,
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
              ).pad(t: 16, b: 16),
              Container(
                decoration: BoxDecoration(
                  color: DefaultTheme.backgroundLightColor,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FlatButton(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(12))),
                        onPressed: () async {
                          Navigator.pushNamed(context, SelectScreen.routeName, arguments: {
                            SelectScreen.title: NL10ns.of(context).local_notification,
                            SelectScreen.selectedValue: Settings.localNotificationType,
                            SelectScreen.list: _localNotificationTypeList,
                          }).then((type) {
                            if (type != null) {
                              Settings.localNotificationType = type;
                              _localStorage.set('${LocalStorage.SETTINGS_KEY}:${LocalStorage.LOCAL_NOTIFICATION_TYPE_KEY}', type);
                              setState(() {
                                _currentLocalNotificationType = _localNotificationTypeList?.firstWhere((x) => x.value == Settings.localNotificationType)?.text;
                              });
                            }
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Label(
                              NL10ns.of(context).local_notification,
                              type: LabelType.bodyRegular,
                              color: DefaultTheme.fontColor1,
                              height: 1,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Label(
                                _currentLocalNotificationType ?? '',
                                type: LabelType.bodyRegular,
                                color: DefaultTheme.fontColor2,
                                overflow: TextOverflow.fade,
                                textAlign: TextAlign.right,
                                height: 1,
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/icons/right.svg',
                              width: 24,
                              color: DefaultTheme.fontColor2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Label(
                      NL10ns.of(context).about,
                      type: LabelType.h3,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: DefaultTheme.backgroundLightColor,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FlatButton(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Label(
                              NL10ns.of(context).version,
                              type: LabelType.bodyRegular,
                              color: DefaultTheme.fontColor1,
                              height: 1,
                            ),
                            Label(
                              showVersion,
                              type: LabelType.bodyRegular,
                              color: DefaultTheme.fontColor2,
                              height: 1,
                            ),
                          ],
                        ),
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FlatButton(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Label(
                              NL10ns.of(context).contact,
                              type: LabelType.bodyRegular,
                              color: DefaultTheme.fontColor1,
                              height: 1,
                            ),
                            Row(
                              children: <Widget>[
                                Label(
                                  'nmobile@nkn.org',
                                  type: LabelType.bodyRegular,
                                  color: DefaultTheme.fontColor2,
                                  height: 1,
                                ),
//                                SvgPicture.asset(
//                                  'assets/icons/right.svg',
//                                  width: 24,
//                                  color: DefaultTheme.fontColor2,
//                                ),
                              ],
                            )
                          ],
                        ),
                        onPressed: () async {
//                          launchURL('mailto:nmobile@nkn.org');
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FlatButton(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Label(
                              NL10ns.of(context).help,
                              type: LabelType.bodyRegular,
                              color: DefaultTheme.fontColor1,
                              height: 1,
                            ),
                            Row(
                              children: <Widget>[
                                Label(
                                  'https://forum.nkn.org',
                                  type: LabelType.bodyRegular,
                                  color: DefaultTheme.fontColor2,
                                  height: 1,
                                ),
                                SvgPicture.asset(
                                  'assets/icons/right.svg',
                                  width: 24,
                                  color: DefaultTheme.fontColor2,
                                ),
                              ],
                            )
                          ],
                        ),
                        onPressed: () {
                          launchURL('https://forum.nkn.org');
//                          Navigator.pushNamed(context, CommonWebViewPage.routeName, arguments: {CommonWebViewPage.webUrl: 'https://forum.nkn.org'});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Label(
                      NL10ns.of(context).advanced,
                      type: LabelType.h3,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: DefaultTheme.backgroundLightColor,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FlatButton(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(12))),
                        onPressed: () async {
                          Navigator.pushNamed(context, AdvancePage.routeName);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Label(
                              NL10ns.of(context).debug,
                              type: LabelType.bodyRegular,
                              color: DefaultTheme.fontColor1,
                              height: 1,
                            ),
                            SvgPicture.asset(
                              'assets/icons/right.svg',
                              width: 24,
                              color: DefaultTheme.fontColor2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  changeAuthAction(bool value) async {
    var wallet = await WalletSchema.getWallet();
    if (wallet == null) return;
    var password = await BottomDialog.of(Global.appContext).showInputPasswordDialog(title: NL10ns.of(Global.appContext).verify_wallet_password);

    String testCode = wallet.address;

    // _secureStorage.set('${SecureStorage.PASSWORDS_KEY}:$address', password);
    // _secureStorage.set('${SecureStorage.NKN_KEYSTORES_KEY}:${wallet.address}', keystore)
    if (password != null) {
      try {
        var w = await wallet.exportWallet(password);
        _localStorage.set('${LocalStorage.SETTINGS_KEY}:${LocalStorage.AUTH_KEY}', value);
        final _localAuth = await LocalAuthenticationService.instance;
        _localAuth.isProtectionEnabled = value;
        setState(() {
          _authSelected = value;
        });
      } catch (e) {
        showToast('Ee'+e.toString());
        if (e.message == ConstUtils.WALLET_PASSWORD_ERROR) {
          showToast(NL10ns.of(context).tip_password_error);
        }
      }
    }
  }
}
