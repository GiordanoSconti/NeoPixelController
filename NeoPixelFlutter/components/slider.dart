import 'package:flutter/material.dart';

class CustomSlider extends StatefulWidget {
  final String sliderLabel;
  final double minValue;
  final double maxValue;
  CustomSlider({Key key, this.sliderLabel = "Value", this.minValue = 0, this.maxValue = 100}): super(key: key);
  @override
  CustomSliderState createState() => CustomSliderState();
}

class CustomSliderState extends State<CustomSlider> {
  double _continuousValue;
  double get continuousValue => _continuousValue;
  @override
  void initState() {
    _continuousValue = widget.maxValue;
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
                        onSubmitted: (value) {
                          final newValue = double.tryParse(value);
                          if (newValue != null && newValue != _continuousValue) {
                            setState(() {
                              _continuousValue = newValue.clamp(0, 100) as double;
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                          text: _continuousValue.toStringAsFixed(0),
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
