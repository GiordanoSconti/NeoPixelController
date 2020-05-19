# NeoPixelController
ESP32 Firmware to manage RGBW LED Strip (WS2812B) through WiFi.

# How to use it:
There are several commands the firmware can accept:
* ### Set-Music Command:
```javascript
let jsObject = {"hexRGBValue": "#000000", "brightness": 64};
WebSocket.send("set-music:" + JSON.stringify(jsObject) + ":set-music");
```
This command can be used to send real time changes to all the leds.

Javascript Object Parameters:
| Name          | Description                                         | Possible Values                                                   |
| ------------- |:----------------------------------------------------|:------------------------------------------------------------------|
| hexRGBValue   | This is the color all the leds will be set to.      | hexadecimal string: "#rrggbb" ; where rr = Red Value, gg = Green Value, bb = Blue Value |
| brightness    | This is the brightness all the leds will be set to. | Number between 0 and 255, both included.                          |

* ### Set-Rainbow Command:
```javascript
WebSocket.send("set-rainbow");
```
This command can be used to reproduce a static rainbow effect.

No Parameters are needed.

* ### Get-Led-Colors Command:
```javascript
WebSocket.send("get-led-colors");
```
This command can be used to get the current colors of the leds.

No Parameters are needed.

* ### Stop-Task Command:
```javascript
WebSocket.send("stop-task");
```
This command can be used to stop a running task before sending other commands.

No Parameters are needed.

* ### Set-Pattern Command:
```javascript
let jsObjectOnce = {
    "mode": "once",
	"leds": [{"id": "all", "start-id": "0", "end-id": "0","color": "#ffffff", "brightness": 64, "delay": 0}]
};
WebSocket.send("set-pattern:" + JSON.stringify(jsObjectOnce) + ":set-pattern");
let jsObjectLoop = {
    "mode": "loop",
	"leds": [{"id": "all", "start-id": "0", "end-id": "0", "color": "#ff0000", "brightness": 64, "delay": 500}, {"id": "all", "start-id": "0", "end-id": "0", "color": "#000000", "brightness": 64, "delay": 500}]
};
WebSocket.send("set-pattern:" + JSON.stringify(jsObjectLoop) + ":set-pattern");
let jsObjectReverse = {
    "mode": "reverse",
	"leds": [{"id": "all", "start-id": "0", "end-id": "0", "color": "#ff0000", "brightness": 64, "delay": 500}, {"id": "all", "start-id": "0", "end-id": "0", "color": "#000000", "brightness": 64, "delay": 500}]
};
WebSocket.send("set-pattern:" + JSON.stringify(jsObjectReverse) + ":set-pattern");
let jsObjectFlowColors = {
    "mode": "flow-colors",
    "leds": [{"id": "range", "start-id": "0", "end-id": "29", "color": "#ff0000", "brightness": 64, "delay": 0}, {"id": "range", "start-id": "30", "end-id": "59", "color": "#ffa500", "brightness": 64, "delay": 0}, {"id": "range", "start-id": "60", "end-id": "89", "color": "#ffff00", "brightness": 64, "delay": 0}, {"id": "range", "start-id": "90", "end-id": "119", "color": "#00ff00", "brightness": 64, "delay": 0}, {"id": "range", "start-id": "120", "end-id": "149", "color": "#00ffff", "brightness": 64, "delay": 500}]
};
WebSocket.send("set-pattern:" + JSON.stringify(jsObjectFlowColors) + ":set-pattern");
```
This command can be used to program in real time the LED Strip.

There are four modes, each with a different goal:

#### Once:
It is used to execute only once in a row all the commands contained in the "leds" parameter.

#### Loop:
It is used to execute all the commands contained in the "leds" parameter in an infinite loop, in clockwise order.

#### Reverse:
It is used to execute all the commands contained in the "leds" parameter in an infinite loop, in counterclockwise order.

#### Flow-colors:
It is used to execute all the commands contained in the "leds" parameter in an infinite loop, but the elements the "leds" parameter is composed of are made scrolling at every cycle.

Javascript Object Parameters:
| Name          | Description                                             | Possible Values                                   |
|---------------|:--------------------------------------------------------|:--------------------------------------------------|
| mode          | This is the mode with which you program the LED Strip.  | string: "once", "loop", "reverse", "flow-colors"  |
| leds          | This is the commands list.                              | an array of CommadParameters objects.             |

CommandParameters:
| Name          | Description                                                              | Possible Values                                                                          |
|---------------|:-------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------|
| id            | This allows you to select a range of leds, a single led or all the leds. | "all", "range" or a number between 0 and NUM_LEDS - 1 (both included), in string format. |
| start-id      | This allows you to choose the starting led of the range.                 | A number between 0 and NUM_LEDS - 1, both included, in string format.                    |
| end-id        | This allows you to choose the ending led of the range.                   | A number between 0 and NUM_LEDS - 1, both included, in string format.                    |
| color         | The color of a single led, of a range of leds or of all the leds.        | hexadecimal string: "#rrggbb" ; where rr = Red Value, gg = Green Value, bb = Blue Value  |
| brightness    | The brightness of a single led, of a range of leds or of all the leds.   | A number between 0 and 255, both included.                                               |
| delay         | The delay between the current command and the next one.                  | A number which represents the delay in milliseconds.                                     |

* ### Get-Led-Color Command:
```javascript
let jsObjectGetLedColor = {"iLed": "0"};
WebSocket.send("get-led-color:" + JSON.stringify(jsObjectGetLedColor) + ":get-led-color");
```
This command can be use to get a single led color.

Javascript Object Parameters:
| Name          | Description                                                            | Possible Values                                                       |
| ------------- |:-----------------------------------------------------------------------|:----------------------------------------------------------------------|
| iLed          | This is the index of the led you want to retrieve the color from.      | A number between 0 and NUM_LEDS - 1, both included, in string format. |

* ### Set-Color Command:
```javascript
let jsObjectSetColor = {"hexRGBValue": "#ff0000", "iLed": "149"};
WebSocket.send("set-color:" + JSON.stringify(jsObjectSetColor) + ":set-color");
```
This command can be used to set a single color led.

Javascript Object Parameters:
| Name          | Description                                                            | Possible Values                                                                          |
| ------------- |:-----------------------------------------------------------------------|:-----------------------------------------------------------------------------------------|
| hexRGBValue   | This is the color all the leds will be set to.                         | hexadecimal string: "#rrggbb" ; where rr = Red Value, gg = Green Value, bb = Blue Value  |
| iLed          | This is the index of the led you want to retrieve the color from.      | A number between 0 and NUM_LEDS - 1, both included, in string format.                    |
