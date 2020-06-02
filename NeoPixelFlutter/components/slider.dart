import 'package:flutter/material.dart';
typedef OnChanged(int newValue);
class CustomSlider extends StatefulWidget {
  final String sliderLabel;
  final double minValue;
  final double maxValue;
  final double startValue;
  final OnChanged onChanged;
  CustomSlider({Key key, this.sliderLabel = "Value", this.minValue = 0, this.maxValue = 100, this.startValue = 255, this.onChanged}): super(key: key);
  @override
  CustomSliderState createState() => CustomSliderState();
}

class CustomSliderState extends State<CustomSlider> {
  double _continuousValue;
  double get continuousValue => _continuousValue;
  @override
  void initState() {
    _continuousValue = widget.startValue;
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: widget.sliderLabel,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 64,
                      height: 48,
                      child: TextField(
                        readOnly: true,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: _continuousValue.toStringAsFixed(0)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Slider(
                value: _continuousValue,
                min: widget.minValue,
                max: widget.maxValue,
                onChanged: (value) {
                  setState(() {
                    _continuousValue = value;
                  });
                  if(widget.onChanged != null)
                    widget.onChanged(int.tryParse(value.toStringAsFixed(0)) ?? 0);
                },
              ),
              Text(widget.sliderLabel),
            ],
          ),
        ],
      ),
    );
  }
}
