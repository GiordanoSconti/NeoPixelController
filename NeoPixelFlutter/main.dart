import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:websocket_manager/websocket_manager.dart';
import 'package:flutter/material.dart';
import 'components/frd_selector.dart' show FlowRainbowDirectionSelector, FlowRainbowDirectionState;
import 'components/slider.dart' show CustomSlider, CustomSliderState;

void main() => runApp(MyApp());

class FlowRainbow {
  final int delay;
  final String direction;
  FlowRainbow({this.delay, this.direction});
  FlowRainbow.fromJson(Map<String, dynamic> json): delay = json['delay'], direction = json['direction'];
  Map<String, dynamic> toJson() => {
    'delay': delay,
    'direction': direction,
  };
}

class WebSocketStatusMessage {
  final String command;
  final String data;
  WebSocketStatusMessage({this.command, this.data});
  WebSocketStatusMessage.fromJson(Map<String, dynamic> json): command = json['status']['command'], data = json['status']['data'];
  Map<String, dynamic> toJson() => {
    'status': {'command': command, 'data': data},
  };
}

class GlobalBrightness {
  final int brightness;
  GlobalBrightness({this.brightness});
  GlobalBrightness.fromJson(Map<String, dynamic> json): brightness = json['brightness'];
  Map<String, dynamic> toJson() => {
    'brightness': brightness,
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
            displayColor: Colors.black,
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
  final GlobalKey<FlowRainbowDirectionState> frdStateKey = GlobalKey<FlowRainbowDirectionState>();
  final GlobalKey<CustomSliderState> csStateKey = GlobalKey<CustomSliderState>();
  final RegExp addressRegExp = RegExp(r"^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$");
  final RegExp delayRegExp = RegExp(r"^[0-9]+$");
  final int defaultBrightnessValue = 64;
  bool _isWebSocketConnected = false;
  bool _isTaskRunning = false;
  WebsocketManager _webSocket;
  @override
  Widget build(BuildContext context) {
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
                                prefixIcon: Icon(Icons.computer),
                              ),
                            ),
                            TextField(
                              controller: _socketPortController,
                              decoration: const InputDecoration(
                                labelText: 'Type the remote port',
                                prefixIcon: Icon(Icons.power),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  child: RaisedButton(
                                    color: const Color.fromARGB(255, 50, 168, 125),
                                    textColor: const Color.fromARGB(255, 255, 255, 255),
                                    child: const Text('CONNECT'),
                                    onPressed: _isWebSocketClosed() ? () => _openWebSocket(context) : null,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 8.0),
                                  child: RaisedButton(
                                    child: const Text('CLOSE'),
                                    onPressed: _isWebSocketClosed() ? null : () => _closeWebSocket(context),
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
                                prefixIcon: Icon(Icons.send),
                              ),
                            ),
                            RaisedButton(
                              child: const Text('SEND'),
                              onPressed: _isWebSocketClosed() ? null : () => _sendMessage(context),
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
                              key: frdStateKey,
                              showInSnackBar: (String message, BuildContext context) {
                                Scaffold.of(context).hideCurrentSnackBar();
                                Scaffold.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(milliseconds: 1500),
                                    content: Text(
                                        'INFO: Direction Selected -> $message'),
                                  ),
                                );
                              }
                            ),
                            TextField(
                              controller: _flowRainbowDelayController,
                              decoration: const InputDecoration(
                                labelText: 'Delay:',
                                prefixIcon: Icon(Icons.access_time),
                              ),
                            ),
                            RaisedButton(
                              child: const Text('START FLOW RAINBOW'),
                              onPressed: _isWebSocketClosed() || _isTaskRunning ? null : () => _startFlowRainbow(context),
                            ),
                            RaisedButton(
                              child: const Text('STOP FLOW RAINBOW'),
                              onPressed: !_isWebSocketClosed() && _isTaskRunning ? () => _stopTask(context) : null,
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
                            CustomSlider(
                              key: csStateKey,
                              sliderLabel: "Brightness",
                              minValue: 0,
                              maxValue: 255
                            ),
                            RaisedButton(
                              child: const Text('SET BRIGHTNESS'),
                              onPressed: !_isWebSocketClosed() && !_isTaskRunning ? () => _setBrightness(context) : null,
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

  void _setBrightness(BuildContext context) {
    if(_webSocket != null && _isWebSocketConnected) {
      int brightnessValue = int.tryParse(csStateKey.currentState.continuousValue.toStringAsFixed(0)) ?? defaultBrightnessValue;
      GlobalBrightness globalBrightness = GlobalBrightness(brightness: brightnessValue);
      _webSocket.send("set-brightness:" + jsonEncode(globalBrightness) + ":set-brightness");
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: Text('INFO: Setting global brightness to: $brightnessValue'),
        ),
      );
    }
  }

  void _stopTask(BuildContext context) {
    if (_webSocket != null && _isWebSocketConnected) {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: const Text('INFO: Stopping running Task!'),
        ),
      );
      _webSocket.send("stop-task");
      setState(() {
        _isTaskRunning = false;
      });
    }
  }

  void _startFlowRainbow(BuildContext context) {
    if (_flowRainbowDelayController.text.isNotEmpty && _webSocket != null && _isWebSocketConnected) {
      final bool isDelayValid = (delayRegExp.hasMatch(_flowRainbowDelayController.text) ? true : false);
      final int delay = isDelayValid ? int.tryParse(_flowRainbowDelayController.text) ?? 0 : 0;
      FlowRainbow flowRainbow = FlowRainbow(direction: frdStateKey.currentState.flowDirectionString, delay: delay);
      setState(() {
        _isTaskRunning = true;
      });
      _webSocket.send("flow-rainbow:" + jsonEncode(flowRainbow) + ":flow-rainbow");
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: const Text('INFO: Flow Rainbow Started!'),
        ),
      );
    } else {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          content: const Text('WARNING: Delay is empty or WebSocket is not connected!'),
        ),
      );
    }
  }

  void _openWebSocket(BuildContext context) {
    if (_webSocket == null && !_isWebSocketConnected) {
      final int portNumber = int.tryParse(_socketPortController.text) ?? 0;
      final bool isPortValid = (portNumber > 0 && portNumber < 65535 ? true : false);
      if (_socketAddressController.text.isNotEmpty && _socketPortController.text.isNotEmpty && addressRegExp.hasMatch(_socketAddressController.text) && isPortValid) {
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1500),
            content: Text('INFO: WebSocket is connecting to "ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}"!'),
          ),
        );
        _webSocket = WebsocketManager("ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}");
        _webSocket.onMessage((dynamic message) {
          Scaffold.of(context).hideCurrentSnackBar();
          Scaffold.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1500),
              content: Text('DATA MESSAGE: ${message.toString()}'),
            ),
          );
          Map<String, dynamic> jsonObject = jsonDecode(message.toString());
          var webSocketStatus = WebSocketStatusMessage.fromJson(jsonObject);
          if (webSocketStatus.command == "connect" && webSocketStatus.data == "connected") {
            setState(() {
              _isWebSocketConnected = true;
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
              content: Text('CLOSE MESSAGE: $message'),
            ),
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
          content: Text('INFO: WebSocket is disconnecting from "ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}"!'),
        ),
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
          content: Text('INFO: Sending message to "ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}"!'),
        ),
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
    super.dispose();
  }
}