import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:websocket_manager/websocket_manager.dart';
import 'components/frd_selector.dart' show FlowRainbowDirectionSelector, FlowRainbowDirectionState;
import 'components/iled_selector.dart' show LedIndexSelector;
import 'components/slider.dart' show CustomSlider, CustomSliderState;

void main() => runApp(MyApp());

class FlowRainbow {
  final int delay;
  final String direction;
  FlowRainbow({this.delay, this.direction});
  FlowRainbow.fromJson(Map<String, dynamic> json): delay = json['delay'], direction = json['direction'];
  Map<String, dynamic> toJson() => {
    'delay': delay,
    'direction': direction
  };
}

class WebSocketStatusMessage {
  final String command;
  final String data;
  WebSocketStatusMessage({this.command, this.data});
  WebSocketStatusMessage.fromJson(Map<String, dynamic> json): command = json['status']['command'], data = json['status']['data'];
  Map<String, dynamic> toJson() => {
    'status': {'command': command, 'data': data}
  };
}

class GlobalBrightness {
  final int brightness;
  GlobalBrightness({this.brightness});
  GlobalBrightness.fromJson(Map<String, dynamic> json): brightness = json['brightness'];
  Map<String, dynamic> toJson() => {
    'brightness': brightness
  };
}

class LedColor {
  final String hexRGBValue;
  final String iLed;
  LedColor({this.hexRGBValue, this.iLed});
  LedColor.fromJson(Map<String, dynamic> json): hexRGBValue = json['hexRGBValue'], iLed = json["iLed"];
  Map<String, dynamic> toJson() => {
    'brightness': hexRGBValue,
    'iLed': iLed
  };
}

class LedsColorBrightness {
  final int brightness;
  final String hexRGBValue;
  LedsColorBrightness({this.brightness, this.hexRGBValue});
  LedsColorBrightness.fromJson(Map<String, dynamic> json): brightness = json['brightness'], hexRGBValue = json["hexRGBValue"];
  Map<String, dynamic> toJson() => {
    'brightness': brightness,
    'hexRGBColor': hexRGBValue
  };
}

class LedBrightness {
  final int brightness;
  final String iLed;
  LedBrightness({this.brightness, this.iLed});
  LedBrightness.fromJson(Map<String, dynamic> json): brightness = json['brightness'], iLed = json["iLed"];
  Map<String, dynamic> toJson() => {
    'brightness': brightness,
    'iLed': iLed
  };
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = 'WS2812B LED Strip Controller';
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null)
        {
          currentFocus.focusedChild.unfocus();
          currentFocus.unfocus();
        }
        else if(!currentFocus.hasPrimaryFocus)
          currentFocus.unfocus();
      },
      child: MaterialApp(
        title: title,
        home: MyHomePage(title: title),
        theme: ThemeData(
          primaryColor: Color.fromARGB(255, 50, 168, 125),
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: Colors.black,
            displayColor: Colors.black
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  MyHomePage({Key key, @required this.title}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _socketAddressController = TextEditingController();
  final TextEditingController _socketPortController = TextEditingController();
  final TextEditingController _flowRainbowDelayController = TextEditingController();
  final TextEditingController _ledIndexController = TextEditingController();
  final GlobalKey<FlowRainbowDirectionState> _frdStateKey = GlobalKey<FlowRainbowDirectionState>();
  final GlobalKey<CustomSliderState> _csGlobalBrightnessKey = GlobalKey<CustomSliderState>();
  final GlobalKey<CustomSliderState> _csLedBrightnessKey = GlobalKey<CustomSliderState>();
  final RegExp _addressRegExp = RegExp(r"^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$");
  final RegExp _numberRegExp = RegExp(r"^[0-9]+$");
  final Color _buttonBackgroundColor = const Color.fromARGB(255, 50, 168, 125);
  final Color _buttonTextColor = const Color.fromARGB(255, 255, 255, 255);
  int _redComponent = 0;
  int _greenComponent = 0;
  int _blueComponent = 0;
  int _maxBrightnessValue = 64;
  bool _isWebSocketConnected = false;
  bool _isTaskRunning = false;
  bool _isLedIndexVisible = false;
  WebsocketManager _webSocket;
  @override
  Widget build(BuildContext externalContext) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: const EdgeInsets.all(20.0),
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Card(
                  margin: const EdgeInsets.only(bottom: 30),
                  elevation: 10.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            TextField(
                              controller: _socketAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Type the remote address',
                                prefixIcon: Icon(Icons.computer)
                              ),
                            ),
                            TextField(
                              controller: _socketPortController,
                              decoration: const InputDecoration(
                                labelText: 'Type the remote port',
                                prefixIcon: Icon(Icons.power)
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  child: RaisedButton(
                                    color: _buttonBackgroundColor,
                                    textColor: _buttonTextColor,
                                    child: const Text('CONNECT'),
                                    onPressed: _isWebSocketClosed() ? () => _openWebSocket(context) : null
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 8.0),
                                  child: RaisedButton(
                                    color: _buttonBackgroundColor,
                                    textColor: _buttonTextColor,
                                    child: const Text('CLOSE'),
                                    onPressed: _isWebSocketClosed() ? null : () => _closeWebSocket(context)
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 30),
                  elevation: 10.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[ 
                            TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                labelText: 'Send a message',
                                prefixIcon: Icon(Icons.send)
                              ),
                            ),
                            RaisedButton(
                              color: _buttonBackgroundColor,
                              textColor: _buttonTextColor,
                              child: const Text('SEND'),
                              onPressed: _isWebSocketClosed() ? null : () => _sendMessage(context)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 30),
                  elevation: 10.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            FlowRainbowDirectionSelector(
                              key: _frdStateKey,
                              showInSnackBar: (String message, BuildContext context) {
                                Scaffold.of(context).hideCurrentSnackBar();
                                Scaffold.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(milliseconds: 1500),
                                    content: Text('INFO: Direction Selected -> $message')
                                  ),
                                );
                              }
                            ),
                            TextField(
                              controller: _flowRainbowDelayController,
                              decoration: const InputDecoration(
                                labelText: 'Delay:',
                                prefixIcon: Icon(Icons.access_time)
                              ),
                            ),
                            RaisedButton(
                              color: _buttonBackgroundColor,
                              textColor: _buttonTextColor,
                              child: const Text('START FLOW RAINBOW'),
                              onPressed: _isWebSocketClosed() || _isTaskRunning ? null : () => _startFlowRainbow(context)
                            ),
                            RaisedButton(
                              color: _buttonBackgroundColor,
                              textColor: _buttonTextColor,
                              child: const Text('STOP FLOW RAINBOW'),
                              onPressed: !_isWebSocketClosed() && _isTaskRunning ? () => _stopTask(context) : null
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 30),
                  elevation: 10.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            CustomSlider(
                              key: _csGlobalBrightnessKey,
                              sliderLabel: "Brightness",
                              minValue: 0.0,
                              maxValue: 255.0
                            ),
                            RaisedButton(
                              color: _buttonBackgroundColor,
                              textColor: _buttonTextColor,
                              child: const Text('SET GLOBAL BRIGHTNESS'),
                              onPressed: !_isWebSocketClosed() && !_isTaskRunning ? () => _setBrightness(context) : null
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  elevation: 10.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            LedIndexSelector(
                              showInSnackBar: (String message, BuildContext context) {
                                Scaffold.of(context).hideCurrentSnackBar();
                                Scaffold.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(milliseconds: 1500),
                                    content: Text('INFO: Led Index Selected -> $message')
                                  ),
                                );
                                this._updateLedIndexVisibility(message);
                              }
                            ),
                            Visibility(
                              visible: _isLedIndexVisible,
                              child: Container(
                                child: TextField(
                                    controller: _ledIndexController,
                                    decoration: const InputDecoration(
                                      labelText: 'LED Index:',
                                      prefixIcon: Icon(Icons.class_)
                                    )
                                  ),
                                ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              width: 150,
                              height: 150,
                              color: Color.fromARGB(255, _redComponent, _greenComponent, _blueComponent),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              child: Text(
                                "#${_redComponent.toRadixString(16)}${_greenComponent.toRadixString(16)}${_blueComponent.toRadixString(16)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 35, top: 15),
                              child: CustomSlider(
                                sliderLabel: "R Component",
                                minValue: 0.0,
                                maxValue: 255.0,
                                startValue: 0.0,
                                onChanged: (newValue) => _updateRComponent(newValue)
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 35),
                              child: CustomSlider(
                                sliderLabel: "G Component",
                                minValue: 0.0,
                                maxValue: 255.0,
                                startValue: 0.0,
                                onChanged: (newValue) => _updateGComponent(newValue)
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 35),
                              child: CustomSlider(
                                sliderLabel: "B Component",
                                minValue: 0.0,
                                maxValue: 255.0,
                                startValue: 0.0,
                                onChanged: (newValue) => _updateBComponent(newValue)
                              ),
                            ),
                            Visibility(
                              visible: _isLedIndexVisible,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 25),
                                child: RaisedButton(
                                  color: _buttonBackgroundColor,
                                  textColor: _buttonTextColor,
                                  child: const Text('SET LED COLOR'),
                                  onPressed: !_isWebSocketClosed() && !_isTaskRunning ? () => _setLedColor(context): null
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 25),
                              child: CustomSlider(
                                key: _csLedBrightnessKey,
                                sliderLabel: "Brightness",
                                minValue: 0.0,
                                maxValue: _maxBrightnessValue.toDouble()
                              ),
                            ),
                            Visibility(
                              visible: _isLedIndexVisible,
                              child: RaisedButton(
                                color: _buttonBackgroundColor,
                                textColor: _buttonTextColor,
                                child: const Text('SET LED BRIGHTNESS'),
                                onPressed: !_isWebSocketClosed() && !_isTaskRunning ? () => _setLedBrightness(context) : null
                              ),
                            ),
                            Visibility(
                              visible: !_isLedIndexVisible,
                              child: RaisedButton(
                                color: _buttonBackgroundColor,
                                textColor: _buttonTextColor,
                                child: const Text('SET LEDS'),
                                onPressed: !_isWebSocketClosed() && !_isTaskRunning ? () => _setLeds(context) : null
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setLeds(BuildContext context) {
    if(_webSocket != null && _isWebSocketConnected && !_isLedIndexVisible)
    {
      int brightnessValue = int.tryParse(_csLedBrightnessKey.currentState.continuousValue.toStringAsFixed(0)) ?? _maxBrightnessValue;
      LedsColorBrightness ledsColorBrightness = LedsColorBrightness(brightness: brightnessValue, hexRGBValue: "#${_redComponent.toRadixString(16)}${_greenComponent.toRadixString(16)}${_blueComponent.toRadixString(16)}");
      _webSocket.send("set-music:" + jsonEncode(ledsColorBrightness) + ":set-music");
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text('INFO: Setting leds to: Color = #${_redComponent.toRadixString(16)}${_greenComponent.toRadixString(16)}${_blueComponent.toRadixString(16)} Brightness = $brightnessValue')
        )
      );
    }
  }

  void _setLedColor(BuildContext context){
    if(_webSocket != null && _isWebSocketConnected && _isLedIndexVisible)
    {
      int ledIndex = _ledIndexController.text.isNotEmpty && _numberRegExp.hasMatch(_ledIndexController.text) ? int.tryParse(_ledIndexController.text) ?? -1 : -1;
      if(ledIndex > 0)
      {
        LedColor ledColor = LedColor(hexRGBValue: "#${_redComponent.toRadixString(16)}${_greenComponent.toRadixString(16)}${_blueComponent.toRadixString(16)}", iLed: ledIndex.toString());
        _webSocket.send("set-color:" + jsonEncode(ledColor) + ":set-color");
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1500),
            content: Text('INFO: Setting led $ledIndex color to: #${_redComponent.toRadixString(16)}${_greenComponent.toRadixString(16)}${_blueComponent.toRadixString(16)}')
          )
        );
      }
    }
  }

  void _setLedBrightness(BuildContext context){
    if(_webSocket != null && _isWebSocketConnected && _isLedIndexVisible)
    {
      int brightnessValue = int.tryParse(_csLedBrightnessKey.currentState.continuousValue.toStringAsFixed(0)) ?? _maxBrightnessValue;
      int ledIndex = _ledIndexController.text.isNotEmpty && _numberRegExp.hasMatch(_ledIndexController.text) ? int.tryParse(_ledIndexController.text) ?? -1 : -1;
      if(ledIndex > 0)
      {
        LedBrightness ledBrightness = LedBrightness(brightness: brightnessValue, iLed: ledIndex.toString());
        _webSocket.send("set-led-brightness:" + jsonEncode(ledBrightness) + ":set-led-brightness");
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1500),
            content: Text('INFO: Setting led $ledIndex brightness to: $brightnessValue')
          )
        );
      }
    }
  }

  void _updateLedIndexVisibility(String message){
    bool isLedIndexVisible = true;
    if(message.toLowerCase() == "all")
      isLedIndexVisible = false;
    this.setState(() {
      this._isLedIndexVisible = isLedIndexVisible;
    });
  }

  void _updateRComponent(int newValue){
    this.setState(() {
      _redComponent = newValue;
    });
  }

  void _updateGComponent(int newValue){
    this.setState(() {
      _greenComponent = newValue;
    });
  }

  void _updateBComponent(int newValue){
    this.setState(() {
      _blueComponent = newValue;
    });
  }

  void _setBrightness(BuildContext context) {
    if(_webSocket != null && _isWebSocketConnected) {
      int brightnessValue = int.tryParse(_csGlobalBrightnessKey.currentState.continuousValue.toStringAsFixed(0)) ?? _maxBrightnessValue;
      GlobalBrightness globalBrightness = GlobalBrightness(brightness: brightnessValue);
      _webSocket.send("set-brightness:" + jsonEncode(globalBrightness) + ":set-brightness");
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text('INFO: Setting global brightness to: $brightnessValue')
        )
      );
    }
  }

  void _stopTask(BuildContext context) {
    if (_webSocket != null && _isWebSocketConnected) {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: const Text('INFO: Stopping running Task!')
        )
      );
      _webSocket.send("stop-task");
      setState(() {
        _isTaskRunning = false;
      });
    }
  }

  void _startFlowRainbow(BuildContext context) {
    if (_flowRainbowDelayController.text.isNotEmpty && _webSocket != null && _isWebSocketConnected) {
      final bool isDelayValid = (_numberRegExp.hasMatch(_flowRainbowDelayController.text) ? true : false);
      final int delay = isDelayValid ? int.tryParse(_flowRainbowDelayController.text) ?? 0 : 0;
      FlowRainbow flowRainbow = FlowRainbow(direction: _frdStateKey.currentState.flowDirectionString, delay: delay);
      setState(() {
        _isTaskRunning = true;
      });
      _webSocket.send("flow-rainbow:" + jsonEncode(flowRainbow) + ":flow-rainbow");
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: const Text('INFO: Flow Rainbow Started!')
        )
      );
    } else {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: const Text('WARNING: Delay is empty or WebSocket is not connected!')
        )
      );
    }
  }

  void _openWebSocket(BuildContext context) {
    if (_webSocket == null && !_isWebSocketConnected) {
      final int portNumber = int.tryParse(_socketPortController.text) ?? 0;
      final bool isPortValid = (portNumber > 0 && portNumber < 65535 ? true : false);
      if (_socketAddressController.text.isNotEmpty && _socketPortController.text.isNotEmpty && _addressRegExp.hasMatch(_socketAddressController.text) && isPortValid) {
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1500),
            content: Text('INFO: WebSocket is connecting to "ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}"!')
          )
        );
        _webSocket = WebsocketManager("ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}");
        _webSocket.onMessage((dynamic message) {
          Scaffold.of(context).hideCurrentSnackBar();
          Scaffold.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text('DATA MESSAGE: ${message.toString()}')
            )
          );
          Map<String, dynamic> jsonObject = jsonDecode(message.toString());
          var webSocketStatus = WebSocketStatusMessage.fromJson(jsonObject);
          if (webSocketStatus.command == "connect" && webSocketStatus.data == "connected") {
            _webSocket.send("get-brightness");
            setState(() {
              _isWebSocketConnected = true;
            });
          } else if(webSocketStatus.command == "get-brightness"){
            setState((){
              _maxBrightnessValue = int.tryParse(webSocketStatus.data) ?? 64;
            });
          }
        });
        _webSocket.onClose((dynamic message) {
          _webSocket = null;
          setState(() {
            _isWebSocketConnected = false;
          });
          Scaffold.of(context).hideCurrentSnackBar();
          Scaffold.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text('CLOSE MESSAGE: $message')
            )
          );
        });
        _webSocket.connect();
      }
    }
  }

  void _closeWebSocket(BuildContext context) {
    if (_webSocket != null && _isWebSocketConnected) {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text('INFO: WebSocket is disconnecting from "ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}"!')
        )
      );
      _webSocket.close();
    }
  }

  bool _isWebSocketClosed() {
    return !_isWebSocketConnected;
  }

  void _sendMessage(BuildContext context) {
    if (_messageController.text.isNotEmpty && _isWebSocketConnected) {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text('INFO: Sending message to "ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}"!')
        )
      );
      _webSocket.send(_messageController.text.trim());
    }
  }

  @override
  void dispose() {
    if (_webSocket != null && _isWebSocketConnected) {
      _webSocket.close();
      _isWebSocketConnected = false;
      _webSocket = null;
    }
    _socketAddressController.dispose();
    _socketPortController.dispose();
    _messageController.dispose();
    _flowRainbowDelayController.dispose();
    _ledIndexController.dispose();
    super.dispose();
  }
}