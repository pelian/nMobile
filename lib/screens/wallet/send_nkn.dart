import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:nmobile/blocs/wallet/filtered_wallets_bloc.dart';
import 'package:nmobile/blocs/wallet/filtered_wallets_state.dart';
import 'package:nmobile/blocs/wallet/wallets_bloc.dart';
import 'package:nmobile/blocs/wallet/wallets_state.dart';
import 'package:nmobile/components/button.dart';
import 'package:nmobile/components/dialog/modal.dart';
import 'package:nmobile/components/header/header.dart';
import 'package:nmobile/components/label.dart';
import 'package:nmobile/components/layout/expansion_layout.dart';
import 'package:nmobile/components/textbox.dart';
import 'package:nmobile/components/wallet/dropdown.dart';
import 'package:nmobile/consts/theme.dart';
import 'package:nmobile/helpers/format.dart';
import 'package:nmobile/helpers/utils.dart';
import 'package:nmobile/helpers/validation.dart';
import 'package:nmobile/l10n/localization_intl.dart';
import 'package:nmobile/plugins/nkn_wallet.dart';
import 'package:nmobile/schemas/contact.dart';
import 'package:nmobile/schemas/wallet.dart';
import 'package:nmobile/screens/contact/home.dart';
import 'package:nmobile/screens/scanner.dart';
import 'package:nmobile/screens/wallet/home.dart';
import 'package:nmobile/services/task_service.dart';
import 'package:nmobile/utils/const_utils.dart';
import 'package:nmobile/utils/image_utils.dart';
import 'package:oktoast/oktoast.dart';

class SendNknScreen extends StatefulWidget {
  static const String routeName = '/wallet/send_nkn';
  WalletSchema arguments;
  SendNknScreen({this.arguments});

  @override
  _SendNknScreenState createState() => _SendNknScreenState();
}

class _SendNknScreenState extends State<SendNknScreen> {
  final GetIt locator = GetIt.instance;
  GlobalKey _formKey = new GlobalKey<FormState>();
  bool _formValid = false;
  TextEditingController _amountController = TextEditingController();
  TextEditingController _sendToController = TextEditingController();
  TextEditingController _feeController = TextEditingController();
  FocusNode _amountFocusNode = FocusNode();
  FocusNode _sendToFocusNode = FocusNode();
  FocusNode _feeToFocusNode = FocusNode();

  WalletSchema wallet;
  bool _showFeeLayout = false;
  FilteredWalletsBloc _filteredWalletsBloc;
  var _amount;
  var _sendTo;
  double _fee = 0.1;
  double _sliderFee = 0.1;
  double _sliderFeeMin = 0;
  double _sliderFeeMax = 10;
  @override
  void initState() {
    super.initState();
    locator<TaskService>().queryNknWalletBalanceTask();
    _filteredWalletsBloc = BlocProvider.of<FilteredWalletsBloc>(context);
    _feeController.text = _fee.toString();
  }

  next() async {
    if ((_formKey.currentState as FormState).validate()) {
      (_formKey.currentState as FormState).save();

      var password = await wallet.getPassword();
      if (password != null) {
        try {
          EasyLoading.show();
          var w = await wallet.exportWallet(password);
          var keystore = w['keystore'];
          var hash = await NknWalletPlugin.transfer(keystore, password, _sendTo, _amount, _fee.toString());
          EasyLoading.dismiss();

          Navigator.of(context).pushReplacementNamed(WalletHome.routeName);
        } catch (e) {
          EasyLoading.dismiss();
          if (e.message == ConstUtils.WALLET_PASSWORD_ERROR) {
            showToast(NMobileLocalizations.of(context).password_wrong);
          } else if (e.message == 'INTERNAL ERROR, can not append tx to txpool: not sufficient funds') {
            await ModalDialog.of(context).show(
              height: 240,
              content: Label(
                e.message,
                type: LabelType.bodyRegular,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(
        title: NMobileLocalizations.of(context).send_nkn.toUpperCase(),
        backgroundColor: DefaultTheme.backgroundColor4,
        action: IconButton(
          icon: loadAssetIconsImage(
            'scan',
            width: 24,
            color: DefaultTheme.backgroundLightColor,
          ),
          onPressed: () async {
            var qrData = await Navigator.of(context).pushNamed(ScannerScreen.routeName);
            var jsonFormat;
            var jsonData;
            try {
              jsonData = jsonDecode(qrData);
              jsonFormat = true;
            } on Exception catch (e) {
              jsonFormat = false;
            }
            if (jsonFormat) {
              _sendToController.text = jsonData['address'];
              _amountController.text = jsonData['amount'].toString();
            } else if (verifyAddress(qrData)) {
              _sendToController.text = qrData;
            } else {
              await ModalDialog.of(context).show(
                height: 240,
                content: Label(
                  NMobileLocalizations.of(context).error_unknow_nkn_qrcode,
                  type: LabelType.bodyRegular,
                ),
              );
            }
          },
        ),
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
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
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(bottom: 32, left: 20, right: 20),
                            child: Image(
                              image: AssetImage("assets/wallet/transfer-header.png"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: 400),
                child: Container(
                  constraints: BoxConstraints.expand(height: MediaQuery.of(context).size.height - 200),
                  color: DefaultTheme.backgroundColor4,
                  child: Flex(
                    direction: Axis.vertical,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: BlocBuilder<FilteredWalletsBloc, FilteredWalletsState>(
                          builder: (context, state) {
                            if (state is FilteredWalletsLoaded) {
                              wallet = state.filteredWallets.first;
                              return Container(
                                decoration: BoxDecoration(
                                  color: DefaultTheme.backgroundLightColor,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                                ),
                                child: Form(
                                  key: _formKey,
                                  autovalidate: true,
                                  onChanged: () {
                                    setState(() {
                                      _formValid = (_formKey.currentState as FormState).validate();
                                    });
                                  },
                                  child: Flex(
                                    direction: Axis.vertical,
                                    children: <Widget>[
                                      Expanded(
                                        flex: 1,
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Scrollbar(
                                            child: SingleChildScrollView(
                                              child: Padding(
                                                padding: EdgeInsets.only(top: 32, left: 20, right: 20),
                                                child: Flex(
                                                  direction: Axis.vertical,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Expanded(
                                                      flex: 0,
                                                      child: Padding(
                                                        padding: EdgeInsets.only(bottom: 32),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: <Widget>[
                                                            Padding(
                                                              padding: const EdgeInsets.only(bottom: 20),
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                children: <Widget>[
                                                                  Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: <Widget>[
                                                                      Label(
                                                                        NMobileLocalizations.of(context).from,
                                                                        type: LabelType.h4,
                                                                        textAlign: TextAlign.start,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  WalletDropdown(
                                                                    title: NMobileLocalizations.of(context).select_asset_to_recieve,
                                                                    schema: widget.arguments ?? wallet,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Label(
                                                              NMobileLocalizations.of(context).amount,
                                                              type: LabelType.h4,
                                                              textAlign: TextAlign.start,
                                                            ),
                                                            Textbox(
                                                              padding: const EdgeInsets.only(bottom: 4),
                                                              controller: _amountController,
                                                              focusNode: _amountFocusNode,
                                                              onSaved: (v) => _amount = v,
                                                              onFieldSubmitted: (_) {
                                                                FocusScope.of(context).requestFocus(_sendToFocusNode);
                                                              },
                                                              validator: Validator.of(context).amount(),
                                                              showErrorMessage: false,
                                                              hintText: NMobileLocalizations.of(context).enter_amount,
                                                              suffixIcon: GestureDetector(
                                                                onTap: () async {},
                                                                child: Container(
                                                                  width: 20,
                                                                  alignment: Alignment.centerRight,
                                                                  child: Label(
                                                                    NMobileLocalizations.of(context).nkn,
                                                                    type: LabelType.label,
                                                                  ),
                                                                ),
                                                              ),
                                                              textInputAction: TextInputAction.next,
                                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                              inputFormatters: [WhitelistingTextInputFormatter(RegExp('^[0-9]*.?[0-9]{0,8}'))],
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets.only(bottom: 20),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: <Widget>[
                                                                  Row(
                                                                    children: <Widget>[
                                                                      Label(NMobileLocalizations.of(context).available + ': '),
                                                                      BlocBuilder<WalletsBloc, WalletsState>(
                                                                        builder: (context, state) {
                                                                          if (state is WalletsLoaded) {
                                                                            var w = state.wallets.firstWhere((x) => x == wallet, orElse: () => null);
                                                                            if (w != null) {
                                                                              return Label(
                                                                                Format.nknFormat(w.balance, decimalDigits: 8, symbol: 'NKN'),
                                                                                color: DefaultTheme.fontColor1,
                                                                              );
                                                                            }
                                                                          }
                                                                          return Label(
                                                                            '- NKN',
                                                                            color: DefaultTheme.fontColor1,
                                                                          );
                                                                        },
                                                                      )
                                                                    ],
                                                                  ),
                                                                  InkWell(
                                                                    child: Label(
                                                                      NMobileLocalizations.of(context).max,
                                                                      color: DefaultTheme.primaryColor,
                                                                      type: LabelType.bodyRegular,
                                                                    ),
                                                                    onTap: () {
                                                                      _amountController.text = wallet.balance.toString();
                                                                    },
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                            Label(
                                                              NMobileLocalizations.of(context).send_to,
                                                              type: LabelType.h4,
                                                              textAlign: TextAlign.start,
                                                            ),
                                                            Textbox(
                                                              focusNode: _sendToFocusNode,
                                                              controller: _sendToController,
                                                              onSaved: (v) => _sendTo = v,
                                                              onFieldSubmitted: (_) {
                                                                FocusScope.of(context).requestFocus(_feeToFocusNode);
                                                              },
                                                              validator: Validator.of(context).nknAddress(),
                                                              textInputAction: TextInputAction.next,
                                                              hintText: NMobileLocalizations.of(context).enter_receive_address,
                                                              suffixIcon: GestureDetector(
                                                                onTap: () async {
                                                                  var contact = await Navigator.of(context).pushNamed(ContactHome.routeName, arguments: true);
                                                                  if (contact is ContactSchema) {
                                                                    _sendToController.text = contact.nknWalletAddress;
                                                                  }
                                                                },
                                                                child: Container(
                                                                  width: 20,
                                                                  alignment: Alignment.centerRight,
                                                                  child: Icon(FontAwesomeIcons.solidAddressBook),
                                                                ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets.only(bottom: 20),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                                children: <Widget>[
                                                                  InkWell(
                                                                    onTap: () {
                                                                      setState(() {
                                                                        _showFeeLayout = !_showFeeLayout;
                                                                      });
                                                                    },
                                                                    child: Row(
                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                      children: <Widget>[
                                                                        Label(
                                                                          NMobileLocalizations.of(context).fee,
                                                                          color: DefaultTheme.primaryColor,
                                                                          type: LabelType.h4,
                                                                          textAlign: TextAlign.start,
                                                                        ),
                                                                        RotatedBox(
                                                                          quarterTurns: _showFeeLayout ? 2 : 0,
                                                                          child: loadAssetIconsImage('down', color: DefaultTheme.primaryColor, width: 20),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 160,
                                                                    child: Textbox(
                                                                      controller: _feeController,
                                                                      focusNode: _feeToFocusNode,
                                                                      padding: const EdgeInsets.only(bottom: 0),
                                                                      onSaved: (v) => _fee = double.parse(v ?? 0),
                                                                      onChanged: (v) {
                                                                        setState(() {
                                                                          double fee = v.isNotEmpty ? double.parse(v) : 0;
                                                                          if (fee > _sliderFeeMax) {
                                                                            fee = _sliderFeeMax;
                                                                          } else if (fee < _sliderFeeMin) {
                                                                            fee = _sliderFeeMin;
                                                                          }
                                                                          _sliderFee = fee;
                                                                        });
                                                                      },
                                                                      suffixIcon: GestureDetector(
                                                                        onTap: () {},
                                                                        child: Container(
                                                                          width: 20,
                                                                          alignment: Alignment.centerRight,
                                                                          child: Label(
                                                                            NMobileLocalizations.of(context).nkn,
                                                                            type: LabelType.label,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      keyboardType: TextInputType.numberWithOptions(
                                                                        decimal: true,
                                                                      ),
                                                                      textInputAction: TextInputAction.done,
                                                                      inputFormatters: [WhitelistingTextInputFormatter(RegExp('^[0-9]*.?[0-9]{0,8}'))],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            ExpansionLayout(
                                                              isExpanded: _showFeeLayout,
                                                              child: Container(
                                                                  width: double.infinity,
                                                                  padding: const EdgeInsets.only(top: 0),
                                                                  child: Column(
                                                                    children: <Widget>[
                                                                      Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: <Widget>[
                                                                          Label(
                                                                            NMobileLocalizations.of(context).slow,
                                                                            type: LabelType.bodySmall,
                                                                            color: DefaultTheme.primaryColor,
                                                                          ),
                                                                          Label(
                                                                            NMobileLocalizations.of(context).average,
                                                                            type: LabelType.bodySmall,
                                                                            color: DefaultTheme.primaryColor,
                                                                          ),
                                                                          Label(
                                                                            NMobileLocalizations.of(context).fast,
                                                                            type: LabelType.bodySmall,
                                                                            color: DefaultTheme.primaryColor,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Slider(
                                                                        value: _sliderFee,
                                                                        onChanged: (v) {
                                                                          setState(() {
                                                                            _sliderFee = _fee = v;
                                                                            _feeController.text = _fee.toStringAsFixed(2);
                                                                          });
                                                                        },
                                                                        max: _sliderFeeMax,
                                                                        min: _sliderFeeMin,
                                                                      ),
                                                                    ],
                                                                  )),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 0,
                                        child: SafeArea(
                                          child: Padding(
                                            padding: EdgeInsets.only(bottom: 8, top: 8),
                                            child: Column(
                                              children: <Widget>[
                                                Padding(
                                                  padding: EdgeInsets.only(left: 30, right: 30),
                                                  child: Button(
                                                    width: double.infinity,
                                                    text: NMobileLocalizations.of(context).continue_text,
                                                    padding: EdgeInsets.only(top: 16, bottom: 16),
                                                    disabled: !_formValid,
                                                    onPressed: next,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              return null;
                            }
                          },
                        ),
                      )
                    ],
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