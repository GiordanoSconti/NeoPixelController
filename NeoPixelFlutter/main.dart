import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:websocket_manager/websocket_manager.dart';
import 'package:flutter/material.dart';
import 'components/frd_selector.dart' show FlowRainbowDirectionSelector, FlowRainbowDirectionState;
import 'components/slider.dart' show CustomSlider;

void main() => runApp(MyApp());

class FlowRainbow {
  final int delay;
  final String direction;
  FlowRainbow({this.delay, this.direction});
  FlowRainbow.fromJson(Map<String, dynamic> json): delay = json['delay'], direction = json['direction'];
  Map<String, dynamic> toJson() =>
  {
    'delay': delay,
    'direction': direction,
  };
}

class WebSocketStatusMessage {
  final String command;
  final String data;
  WebSocketStatusMessage({this.command, this.data});
  WebSocketStatusMessage.fromJson(Map<String, dynamic> json): command = json['status']['command'], data = json['status']['data'];
  Map<String, dynamic> toJson() =>
  {
    'status': {
      'command': command,
      'data': data
    }
  };
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = 'WS2812B LED Strip Controller';
    return MaterialApp(
      title: title,
      home: MyHomePage(
        title: title
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  MyHomePage({Key key, @required this.title})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _socketAddressController = TextEditingController();
  final TextEditingController _socketPortController = TextEditingController();
  final TextEditingController _flowRainbowDelayController = TextEditingController();
  final GlobalKey<FlowRainbowDirectionState> frdStateKey = GlobalKey<FlowRainbowDirectionState>();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _socketAddressController,
                      decoration: InputDecoration(labelText: 'Type the remote address'),
                    ),
                    TextField(
                      controller: _socketPortController,
                      decoration: InputDecoration(labelText: 'Type the remote port')
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      child: RaisedButton(
                        child: Text('CONNECT'),
                        onPressed: _isWebSocketClosed() ? () => _openWebSocket(context) : null,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 8.0),
                      child: RaisedButton(
                        child: Text('CLOSE'),
                        onPressed: _isWebSocketClosed() ? null : () => _closeWebSocket(context),
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(labelText: 'Send a message'),
                    ),
                  ],
                ),
                Container(
                  child: RaisedButton(
                    child: Text('SEND'),
                    onPressed: _isWebSocketClosed() ? null : () => _sendMessage(context),
                  )
                ),
                FlowRainbowDirectionSelector(key: frdStateKey, showInSnackBar: (String message, BuildContext context) {
                  Scaffold.of(context).hideCurrentSnackBar();
                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      duration: Duration(milliseconds: 1500),
                      content: Text(
                        'INFO: Direction Selected -> $message'
                      ),
                    ),
                  );
                }),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _flowRainbowDelayController, 
                      decoration: InputDecoration(labelText: 'Delay:'),
                    ),
                    RaisedButton(
                      child: Text('START FLOW RAINBOW'),
                      onPressed: _isWebSocketClosed() || _isTaskRunning ? null : () => _startFlowRainbow(context),
                    ),
                    RaisedButton(
                      child: Text('STOP FLOW RAINBOW'),
                      onPressed: !_isWebSocketClosed() && _isTaskRunning ? () => _stopTask(context) : null,
                    ),
                  ],
                ),
                CustomSlider(sliderLabel: "Brightness", minValue: 0, maxValue: 100),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _stopTask(BuildContext context){
    if(_webSocket != null && _isWebSocketConnected){
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: Duration(milliseconds: 1500),
          content: Text(
            'INFO: Stopping running Task!'
          ),
        ),
      );
      _webSocket.send("stop-task");
      setState((){
        _isTaskRunning = false;
      });
    }
  }

  void _startFlowRainbow(BuildContext context){
      final String direction = frdStateKey.currentState.flowDirectionString;
      if(_flowRainbowDelayController.text.isNotEmpty && _webSocket != null && _isWebSocketConnected)
      {
        final int delay = int.parse(_flowRainbowDelayController.text);
        FlowRainbow flowRainbow = FlowRainbow(direction: direction, delay: delay);
        setState((){
          _isTaskRunning = true;
        });
        _webSocket.send("flow-rainbow:" + jsonEncode(flowRainbow) + ":flow-rainbow");
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(
          SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text(
              'INFO: Flow Rainbow Started!'
            ),
          ),
        );
      } else {
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(
          SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text(
              'WARNING: Delay is empty or WebSocket is not connected!'
            ),
          ),
        );
      }
  }

  void _openWebSocket(BuildContext context){
    if (_webSocket == null && !_isWebSocketConnected) {
      if(_socketAddressController.text.isNotEmpty && _socketPortController.text.isNotEmpty)
      {
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(
          SnackBar(
            duration: Duration(milliseconds: 1500),
            content: Text(
              'INFO: WebSocket is connecting to "ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}"!'
            ),
          ),
        );
        _webSocket = WebsocketManager("ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}");
        _webSocket.onMessage((dynamic message) {
          Scaffold.of(context).hideCurrentSnackBar();
          Scaffold.of(context).showSnackBar(
            SnackBar(
              duration: Duration(milliseconds: 1500),
              content: Text(
                'DATA MESSAGE: ${message.toString()}'
              ),
            ),
          );
          Map<String, dynamic> jsonObject = jsonDecode(message.toString());
          var webSocketStatus = WebSocketStatusMessage.fromJson(jsonObject);
          if(webSocketStatus.command == "connect" && webSocketStatus.data == "connected")
          {
            setState((){
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
              duration: Duration(milliseconds: 1500),
              content: Text(
                'CLOSE MESSAGE: $message'
              ),
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
          duration: Duration(milliseconds: 1500),
          content: Text(
            'INFO: WebSocket is disconnecting from "ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}"!'
          ),
        ),
      );
      _webSocket.close();
    }
  }

  bool _isWebSocketClosed()
  {
    return !_isWebSocketConnected;
  }

  void _sendMessage(BuildContext context) {
    if (_messageController.text.isNotEmpty && _isWebSocketConnected) {
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
        SnackBar(
          duration: Duration(milliseconds: 1500),
          content: Text(
            'INFO: Sending message to "ws://${_socketAddressController.text.trim()}:${_socketPortController.text.trim()}"!'
          ),
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
    super.dispose();
  }
}
