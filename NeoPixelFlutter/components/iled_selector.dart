import 'package:flutter/material.dart';

enum _LedIndexOption {
  all,
  single
}

class LedIndexSelector extends StatefulWidget {
  const LedIndexSelector({Key key, this.showInSnackBar}): super(key: key);
  final void Function(String value, BuildContext context) showInSnackBar;
  @override
  LedIndexState createState() => LedIndexState();
}

class LedIndexState extends State<LedIndexSelector> {
  _LedIndexOption _ledIndexOption;
  String ledIndexString = "all";
  void showAndSetMenuSelection(BuildContext context, _LedIndexOption value) {
    final String valueString = ledIndexOptionToString(value);
    setState(() {
      _ledIndexOption = value;
      ledIndexString = valueString.toLowerCase();
    });
    widget.showInSnackBar(
      valueString,
      context
    );
  }
  String ledIndexOptionToString(_LedIndexOption value) => {
    _LedIndexOption.all: "All",
    _LedIndexOption.single: "Single"
  }[value];
  @override
  void initState() {
    super.initState();
    _ledIndexOption = _LedIndexOption.all;
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
      child: PopupMenuButton<_LedIndexOption>(
        padding: EdgeInsets.zero,
        initialValue: _ledIndexOption,
        onSelected: (value) => showAndSetMenuSelection(context, value),
        child: ListTile(
          leading: Container(
            margin: const EdgeInsets.only(left: 10),
            child: const Icon(Icons.list)
          ),
          contentPadding: EdgeInsets.only(left: 0.0, right: 0.0),
          title: const Text("Index Selector:", textAlign: TextAlign.start),
          subtitle: Text("${ledIndexOptionToString(_ledIndexOption)}")
        ),
        itemBuilder: (context) => <PopupMenuItem<_LedIndexOption>>[
          PopupMenuItem<_LedIndexOption>(
            value: _LedIndexOption.all,
            child: const Text("All")
          ),
          PopupMenuItem<_LedIndexOption>(
            value: _LedIndexOption.single,
            child: const Text("Single")
          ),
        ],
      ),
    );
  }
}