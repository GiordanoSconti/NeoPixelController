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

No parameters are needed.

* ### Get-Led-Colors Command:
```javascript
WebSocket.send("get-led-colors");
```
This command can be used to get the current colors of the leds.

No parameters are needed.

* ### Stop-Task Command:
```javascript
WebSocket.send("stop-task");
```
This command can be used to stop a running task. You need to use it before sending other commands if you used one of these: set-pattern; flow-rainbow.

No parameters are needed.

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
| color         | The color of a single led, a range of leds or all the leds.              | hexadecimal string: "#rrggbb" ; where rr = Red Value, gg = Green Value, bb = Blue Value  |
| brightness    | The brightness of a single led, a range of leds or all the leds.         | A number between 0 and 255, both included.                                               |
| delay         | The delay between the current command and the next one.                  | A number which represents the delay in milliseconds.                                     |

* ### Get-Led-Color Command:
```javascript
let jsObjectGetLedColor = {"iLed": "0"};
WebSocket.send("get-led-color:" + JSON.stringify(jsObjectGetLedColor) + ":get-led-color");
```
This command can be use to get the color of a led.

Javascript Object Parameters:
| Name          | Description                                                            | Possible Values                                                       |
| ------------- |:-----------------------------------------------------------------------|:----------------------------------------------------------------------|
| iLed          | This is the index of the led you want to retrieve the color from.      | A number between 0 and NUM_LEDS - 1, both included, in string format. |

* ### Set-Color Command:
```javascript
let jsObjectSetColor = {"hexRGBValue": "#ff0000", "iLed": "149"};
WebSocket.send("set-color:" + JSON.stringify(jsObjectSetColor) + ":set-color");
```
This command can be used to set the color of a led.

Javascript Object Parameters:
| Name          | Description                                                            | Possible Values                                                                          |
| ------------- |:-----------------------------------------------------------------------|:-----------------------------------------------------------------------------------------|
| hexRGBValue   | This is the color the led will be set to.                              | hexadecimal string: "#rrggbb" ; where rr = Red Value, gg = Green Value, bb = Blue Value  |
| iLed          | This is the index of the led you want to set the color to.             | A number between 0 and NUM_LEDS - 1, both included, in string format.                    |

* ### Set-Colors Command:
```javascript
let jsObjectSetColors = {"1":"#ff00ff","2":"#ff00ff","3":"#ff00ff","4":"#ff00ff","5":"#ff00ff"..., "148": "#ff00ff", "149": "#ff00ff"};
WebSocket.send("set-colors:" + JSON.stringify(jsObjectSetColors) + ":set-colors");
```
This command can be used to set all the leds with different colors. You must set all the leds.

Javascript Object Parameters:
| Name                                                                                        | Description                                                                 | Possible Values                                                                          |
| --------------------------------------------------------------------------------------------|:----------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------|
| iLed ; where iLed is a number between 0 and NUM_LEDS - 1 (both included) in string format   | This is the color the single led will be set to.                            | hexadecimal string: "#rrggbb" ; where rr = Red Value, gg = Green Value, bb = Blue Value  |

* ### Flow-Rainbow Command:
```javascript
let jsObjectFlowRainbow = {"direction": "left", "delay": 15};
WebSocket.send("flow-rainbow:" + JSON.stringify(jsObjectSetColors) + ":flow-rainbow");
```
This command can be used to reproduce a static rainbow effect, but every some milliseconds (delay parameter) it will be made scrolling in the left or right direction (depending on the direction parameter).

Javascript Object Parameters:
| Name          | Description                                                              | Possible Values                                                                          |
|---------------|:-------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------|
| direction     | This allows you to choose the rainbow direction.                         | string: "right" or "left"                                                                |
| delay         | This allows you to choose the rainbow speed.                      | A number which represents the delay in milliseconds.                                     |

* ### Set-Colors-Brightness Command:
```javascript
let jsObjectSetColorsBrightness = {"1": {"hexRGBValue": "#ff00ff", "brightness": 64},"2":{"hexRGBValue": "#ff00ff", "brightness": 64},"3":{"hexRGBValue": "#ff00ff", "brightness": 64}..., "148": {"hexRGBValue": "#ff00ff", "brightness": 64}, "149": {"hexRGBValue": "#ff00ff", "brightness": 64}};
WebSocket.send("set-colors-brightness:" + JSON.stringify(jsObjectSetColorsBrightness) + ":set-colors-brightness");
```
This command can be used to set all the leds with different colors and different brightness. You must set all the leds.

Javascript Object Parameters:
| Name                                                                                        | Description                                                                 | Possible Values                                                                          |
| --------------------------------------------------------------------------------------------|:----------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------|
| iLed ; where iLed is a number between 0 and NUM_LEDS - 1 (both included) in string format   | This is the led the color and the brightness will be set to.                | LedParameters                                                                            |

LedParameters:
| Name          | Description                                         | Possible Values                                                                         |
| ------------- |:----------------------------------------------------|:----------------------------------------------------------------------------------------|
| hexRGBValue   | This is the color the led will be set to.           | hexadecimal string: "#rrggbb" ; where rr = Red Value, gg = Green Value, bb = Blue Value |
| brightness    | This is the brightness the led will be set to.      | Number between 0 and 255, both included.                                                |

# Dependencies:
* [FastLED Library](https://github.com/FastLED/FastLED)
* [ArduinoJson Library](https://github.com/bblanchon/ArduinoJson)
* [ArduinoWebsockets Library](https://github.com/gilmaimon/ArduinoWebsockets)
* [ESP32 Arduino Core](https://github.com/espressif/arduino-esp32)
* [Arduino IDE](https://www.arduino.cc/en/Main/Software)

# Brightness Management:
By changing "#define BRIGHTNESS_FADE_BY" value you can move the offset of fadeToBlackBy, which is 0 by default. When you need to change the brightness of the leds you have to keep in mind this one. If you want full control over the brightness, you need to set "#define BRIGHTNESS" to 255 and "#define BRIGHTNESS_FADE_BY" to 0 in order to set "brightness" parameter freely. Keep in mind that by doing this you set the global brightness at full. By the way, you have to change even the power settings because by default the power is limited at 5W (5V, 1A).

# Important Settings:
* ssidName = Name of your Network.
* ssidPassword = Password of your Network.
* #define NEO_PIN = DOUT PIN of the LED Strip.
* #define NUM_LEDS = Number of leds the strip is composed of.
* #define BRIGHTNESS = Brightness of all the leds.
* #define BRIGHTNESS_FADE_BY = Offset for fadeToBlackBy method.
* #define SERVER_PORT_NUMBER = WebSocket Server port on which the server listens.
* #define DITHER_FLAG = Temporal Dithering flag.
