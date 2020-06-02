import 'package:flutter/material.dart';

enum _DirectionOption {
  left,
  right
}

class FlowRainbowDirectionSelector extends StatefulWidget {
  const FlowRainbowDirectionSelector({Key key, this.showInSnackBar}): super(key: key);
  final void Function(String value, BuildContext context) showInSnackBar;
  @override
  FlowRainbowDirectionState createState() => FlowRainbowDirectionState();
}

class FlowRainbowDirectionState extends State<FlowRainbowDirectionSelector> {
  _DirectionOption _directionOption;
  String flowDirectionString = "left";
  void showAndSetMenuSelection(BuildContext context, _DirectionOption value) {
    final String valueString = directionOptionToString(value);
    setState(() {
      _directionOption = value;
      flowDirectionString = valueString.toLowerCase();
    });
    widget.showInSnackBar(
      valueString,
      context
    );
  }
  String directionOptionToString(_DirectionOption value) => {
    _DirectionOption.left: "Left",
    _DirectionOption.right: "Right"
  }[value];
  @override
  void initState() {
    super.initState();
    _directionOption = _DirectionOption.left;
  }
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent e) {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null)
        {
          currentFocus.focusedChild.unfocus();
          currentFocus.unfocus();
        }
        else if(!currentFocus.hasPrimaryFocus)
          currentFocus.unfocus();
      },
      child: PopupMenuButton<_DirectionOption>(
        padding: EdgeInsets.zero,
        initialValue: _directionOption,
        onSelected: (value) => showAndSetMenuSelection(context, value),
        child: ListTile(
          leading: Container(
            margin: const EdgeInsets.only(left: 10),
            child: const Icon(Icons.directions)
          ),
          contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
          title: const Text("Direction:", textAlign: TextAlign.start),
          subtitle: Text("${directionOptionToString(_directionOption)}")
        ),
        itemBuilder: (context) => <PopupMenuItem<_DirectionOption>>[
          PopupMenuItem<_DirectionOption>(
            value: _DirectionOption.left,
            child: const Text("Left")
          ),
          PopupMenuItem<_DirectionOption>(
            value: _DirectionOption.right,
            child: const Text("Right")
          ),
        ],
      ),
    );
  }
}