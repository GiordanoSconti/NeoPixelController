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
| hexRGBValue   | This is the color all the leds will be set to.      | #rrggbb ; where rr = Red Value, gg = Green Value, bb = Blue Value |
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
