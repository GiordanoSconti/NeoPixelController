#include <FastLED.h>
#include <ArduinoWebsockets.h>
#include <WiFi.h>
#include <WiFiClient.h>
#include <ArduinoJson.h>
#include <algorithm>
#include <vector>
#include <cmath>

using namespace websockets;

#define NEO_PIN 5
#define NUM_LEDS 150
#define BRIGHTNESS 64
#define BRIGHTNESS_FADE_BY 0
#define PATTERN_SIZE 160
#define SERVER_PORT_NUMBER 27932
#define DITHER_FLAG 0
#define STARTING_COMMAND_STRINGS_SIZE 10

const char *ssidName = "YOUR-NETWORK-SSID";
const char *ssidPassword = "YOUR-NETWORK-PASSWORD";
WebsocketsServer webSocketServer;
std::vector<WebsocketsClient> allClients;
bool isReceivingJson = false;
bool isWebSocketConnected = false;
bool isDebugEnabled = true;
bool isTaskRunning = false;
bool isWebSocketReceiving = true;
int ledStripBrightness = BRIGHTNESS;
String jsonData = "";
String jsonDataPattern = "";
CRGB leds[NUM_LEDS];
TaskHandle_t taskLoopHandle = NULL;
TaskHandle_t taskReverseHandle = NULL;
TaskHandle_t taskFlowColorsHandle = NULL;
TaskHandle_t taskFlowColorsRainbowHandle = NULL;
typedef struct RainbowSettingsType {
    int delay;
    String direction;
} RainbowSettings;
typedef struct LedPatternType {
    String id;
    String startId;
    String endId;
    int colors[4];
    int delay;
} LedPattern;
typedef struct HsvColorType {
    int h;
    int s;
    int v;
} HsvColor;
typedef struct RgbColorType {
    int r;
    int g;
    int b;  
} RgbColor;
enum CommandType {NO_COMMAND, SET_COLORS_BRIGHTNESS, SET_COLORS, SET_MUSIC, SET_COLOR, SET_PATTERN, GET_LED_COLOR, FLOW_RAINBOW, SET_RAINBOW, GET_LED_COLORS, GET_LED_COUNT, GET_TASK_IS_RUNNING, SET_BRIGHTNESS, SET_LED_BRIGHTNESS, GET_LED_BRIGHTNESS, GET_BRIGHTNESS};
CommandType neoPixelCommand = NO_COMMAND;
String startingCommandStrings[STARTING_COMMAND_STRINGS_SIZE] = {"set-colors:", "set-colors-brightness:", "set-music:", "set-color:", "set-pattern:", "get-led-color:", "flow-rainbow:", "set-led-brightness:", "set-brightness:", "get-led-brightness:"};
std::vector<LedPattern> ledPatterns;
RainbowSettings rainbowSettings;

boolean checkElementIn(String message) {
    for (int i = 0; i < STARTING_COMMAND_STRINGS_SIZE; ++i) {
        if (message.indexOf(startingCommandStrings[i]) > -1)
            return true;
    }
    return false;
}

boolean trySetCommand(String message) {
    boolean isSet = true;
    if(message.indexOf(":set-colors-brightness") > -1)
        neoPixelCommand = SET_COLORS_BRIGHTNESS;
    else if(message.indexOf(":set-colors") > - 1)
        neoPixelCommand = SET_COLORS;
    else if(message.indexOf(":set-music") > -1)
        neoPixelCommand = SET_MUSIC;
    else if(message.indexOf(":set-color") > -1)
        neoPixelCommand = SET_COLOR;
    else if(message.indexOf(":set-pattern") > -1)
        neoPixelCommand = SET_PATTERN;
    else if(message.indexOf(":get-led-color") > -1)
        neoPixelCommand = GET_LED_COLOR;
    else if(message.indexOf(":flow-rainbow") > -1)
        neoPixelCommand = FLOW_RAINBOW;
    else if(message.indexOf(":set-brightness") > -1)
        neoPixelCommand = SET_BRIGHTNESS;
    else if(message.indexOf(":set-led-brightness") > -1)
        neoPixelCommand = SET_LED_BRIGHTNESS;
    else if(message.indexOf(":get-led-brightness") > -1)
        neoPixelCommand = GET_LED_BRIGHTNESS;
    else
        isSet = false;
    return isSet;
    
}

void TaskReverseLedPatterns(void *parameters)
{
    std::vector<LedPattern> *ledPatterns = static_cast<std::vector<LedPattern>*>(parameters);
    clearLeds();
    for (;;) {
          if(isTaskRunning)
          {
              for (std::vector<LedPattern>::iterator it = (*ledPatterns).begin() ; it != (*ledPatterns).end(); ++it)
              {
                  if((*it).id == "all")
                      setNeoPixelMusic((*it).colors);
                  else if((*it).id == "range")
                  {
                      if((*it).startId.toInt() < 0 || (*it).startId.toInt() > (NUM_LEDS - 1) || (*it).endId.toInt() < 0 || (*it).endId.toInt() > (NUM_LEDS - 1) || (*it).startId.toInt() >= (*it).endId.toInt())
                          continue;
                      setNeoPixelRangeColors((*it).colors, (*it).startId.toInt(), (*it).endId.toInt());
                  }
                  else
                      setNeoPixelColor((*it).id.toInt(), (*it).colors);
                  if((*it).delay > 0)
                      delayMilliseconds((*it).delay);
              }
              std::reverse((*ledPatterns).begin(), (*ledPatterns).end());
          }
          else
              break;
    }
    isWebSocketReceiving = true;
    taskReverseHandle = NULL;
    vTaskDelete(taskReverseHandle);
}

void TaskLoopLedPatterns(void *parameters)
{
    std::vector<LedPattern> *ledPatterns = static_cast<std::vector<LedPattern>*>(parameters);
    clearLeds();
    for (;;) {
          if(isTaskRunning)
          {
              for (std::vector<LedPattern>::iterator it = (*ledPatterns).begin() ; it != (*ledPatterns).end(); ++it)
              {
                  if((*it).id == "all")
                      setNeoPixelMusic((*it).colors);
                  else if((*it).id == "range")
                  {
                      if((*it).startId.toInt() < 0 || (*it).startId.toInt() > (NUM_LEDS - 1) || (*it).endId.toInt() < 0 || (*it).endId.toInt() > (NUM_LEDS - 1) || (*it).startId.toInt() >= (*it).endId.toInt())
                          continue;
                      setNeoPixelRangeColors((*it).colors, (*it).startId.toInt(), (*it).endId.toInt());
                  }
                  else
                      setNeoPixelColor((*it).id.toInt(), (*it).colors);
                  if((*it).delay > 0)
                      delayMilliseconds((*it).delay);
              }
          }
          else
              break;
    }
    isWebSocketReceiving = true;
    taskLoopHandle = NULL;
    vTaskDelete(taskLoopHandle);
}

void TaskFlowColorsLedPatterns(void *parameters)
{
    std::vector<LedPattern> *ledPatterns = static_cast<std::vector<LedPattern>*>(parameters);
    clearLeds();
    for (;;) {
          if(isTaskRunning)
          {
              int tempColors[4];
              int previousColors[4];
              bool isFirst = true;
              for (std::vector<LedPattern>::iterator it = (*ledPatterns).begin() ; it != (*ledPatterns).end(); ++it)
              {
                  if((*it).id == "range")
                  {
                      if((*it).startId.toInt() < 0 || (*it).startId.toInt() > (NUM_LEDS - 1) || (*it).endId.toInt() < 0 || (*it).endId.toInt() > (NUM_LEDS - 1) || (*it).startId.toInt() >= (*it).endId.toInt())
                          continue;
                      setNeoPixelRangeColors((*it).colors, (*it).startId.toInt(), (*it).endId.toInt());
                  }
                  if((*it).delay > 0)
                      delayMilliseconds((*it).delay);
                  if(isFirst)
                  {
                      isFirst = false;
                      std::copy(std::begin((*it).colors), std::end((*it).colors), std::begin(previousColors));
                  }
                  else
                  {
                      std::copy(std::begin((*it).colors), std::end((*it).colors), std::begin(tempColors));
                      std::copy(std::begin(previousColors), std::end(previousColors), std::begin((*it).colors));
                      std::copy(std::begin(tempColors), std::end(tempColors), std::begin(previousColors));
                  }
              }
              std::copy(std::begin(previousColors), std::end(previousColors), std::begin((*ledPatterns)[0].colors));
          }
          else
              break;
    }
    isWebSocketReceiving = true;
    taskFlowColorsHandle = NULL;
    vTaskDelete(taskFlowColorsHandle);
}

void TaskFlowColorsRainbow(void *parameters)
{
    RainbowSettings *rainbowSettings = static_cast<RainbowSettings*>(parameters);
    clearLeds();
    setNeoPixelRainbow();
    if((*rainbowSettings).direction == "left")
    {
        for (;;) {
              if(isTaskRunning)
                  flowNeoPixelRainbow("left", (*rainbowSettings).delay);
              else
                  break;
        }
    }
    else if((*rainbowSettings).direction == "right")
    {
        for (;;) {
              if(isTaskRunning)
                  flowNeoPixelRainbow("right", (*rainbowSettings).delay);
              else
                 break;
        }
    }
    isWebSocketReceiving = true;
    taskFlowColorsRainbowHandle = NULL;
    vTaskDelete(taskFlowColorsRainbowHandle);
}

void rgbToHsv(const RgbColor& rgbColor, HsvColor& hsvColor)
{
    int maxValue = std::max(std::max(rgbColor.r, rgbColor.g), rgbColor.b);
    if(maxValue == 0)
    {
        hsvColor.h = 0;
        hsvColor.s = 0;
        hsvColor.v = 0;
        return;
    }
    int minValue = std::min(std::min(rgbColor.r, rgbColor.g), rgbColor.b);
    int deltaValue = maxValue - minValue;
    float hue = 0.0;
    hsvColor.v = static_cast<int>(std::floor(maxValue / 255 * 100));
    hsvColor.s = static_cast<int>(std::floor(deltaValue / maxValue * 100));
    deltaValue = deltaValue == 0 ? 1 : deltaValue;
    if(rgbColor.r == maxValue)
        hue = (rgbColor.g - rgbColor.b) / deltaValue;
    else if(rgbColor.g == maxValue)
        hue = 2 + ((rgbColor.b - rgbColor.r) / deltaValue);
    else
        hue = 4 + ((rgbColor.r - rgbColor.g) / deltaValue);
    hsvColor.h = static_cast<int>(std::floor(hue * 60));
    if(hsvColor.h < 0)
        hsvColor.h += 360;
    return;
}

void setup (void) {
    Serial.begin(115200);
    delayMilliseconds(50);
    FastLED.addLeds<WS2812B, NEO_PIN, GRB>(leds, NUM_LEDS);
    FastLED.setMaxPowerInVoltsAndMilliamps(5, 1000);
    FastLED.setDither(DITHER_FLAG);
    FastLED.setBrightness(BRIGHTNESS);
    delayMilliseconds(50);
    setNeoPixelRGBColor(1);
    Serial.println("NeoPixel started!");
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssidName, ssidPassword);
    Serial.println("");
    while(WiFi.status() != WL_CONNECTED) {
        delayMilliseconds(500);
        Serial.print(".");
    }
    Serial.println("");
    Serial.print("Connected to ");
    Serial.println(ssidName);
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    setNeoPixelRGBColor(2);
    webSocketServer.listen(SERVER_PORT_NUMBER);
    delayMilliseconds(500);
    if(!webSocketServer.available())
    {
        Serial.println("Error starting WebSocket server!");
        while (1) {
            delayMilliseconds(50);
        }
    }
    Serial.println("WebSocket server started.");
    setNeoPixelRGBColor(3);
}

void loop(void) {
    if(!isWebSocketConnected)
    {
        if(webSocketServer.poll())
        {
            allClients.erase(allClients.begin(), allClients.end());
            delayMilliseconds(50);
            WebsocketsClient webSocketClient = webSocketServer.accept();
            Serial.println("Client Connected!");
            webSocketClient.send("{\"status\":{\"command\":\"connect\",\"data\":\"connected\"}}");
            delayMilliseconds(50);
            webSocketClient.onMessage(onMessageCallback);
            webSocketClient.onEvent(onEventsCallback);
            allClients.push_back(webSocketClient);
            delayMilliseconds(50);
            isWebSocketConnected = true;
        }
    }
    else
    {
        pollAllClients();
        if(neoPixelCommand != NO_COMMAND)
        {
            switch(neoPixelCommand)
            {
                case SET_COLORS_BRIGHTNESS:
                    setColors(true);
                    break;
                case SET_COLORS:
                    setColors(false);
                    break;
                case SET_MUSIC:
                    setMusic();
                    break;
                case SET_COLOR:
                    setColor();
                    break;
                case SET_PATTERN:
                    setPattern();
                    break;
                case GET_LED_COLOR:
                    getColor();
                    break;
                case FLOW_RAINBOW:
                    setFlowRainbow();
                    break;
                case SET_RAINBOW:
                    setNeoPixelRainbow();
                    break;
                case GET_LED_COLORS:
                    getNeoPixelColors();
                    break;
                case SET_LED_BRIGHTNESS:
                    setLedBrightness();
                    break;
                case SET_BRIGHTNESS:
                    setGlobalBrightness();
                    break;
                case GET_LED_BRIGHTNESS:
                    getLedBrightness();
                    break;
                case GET_BRIGHTNESS:
                    allClients[0].send("{\"data\":" + String(ledStripBrightness) + "}");
                    break;
                case GET_LED_COUNT:
                    allClients[0].send("{\"data\":" + String(NUM_LEDS) + "}");
                    break;
                case GET_TASK_IS_RUNNING:
                    allClients[0].send("{\"data\":" + (isTaskRunning ? String("true") : String("false")) + "}");
                    break;
            }
            neoPixelCommand = NO_COMMAND;
            jsonData = "";
            isReceivingJson = false;
        }
    }
    delayMilliseconds(50);
}

void delayMilliseconds(int milliseconds) { 
    for (int i = 0; i <= milliseconds; ++i){
        delay(1);
        yield();
    }
}

void setNeoPixelRGBColor(int rgbColor)
{
    int colors[3] = {0, 0, 0};
    if(rgbColor == 1)
    {
        colors[0] = 255;
        setNeoPixelColorsUniform(colors);
    }
    else if(rgbColor == 2)
    {
        colors[1] = 255;
        setNeoPixelColorsUniform(colors);
    }
    else if(rgbColor == 3)
    {
        colors[2] = 255;
        setNeoPixelColorsUniform(colors);
    }
}

void setNeoPixelColors(int colors[][4], bool isSetColorsBrightness, int startId, int endId){
    for(int i = startId; i < endId; i++) {
        leds[i].setRGB(colors[i][0], colors[i][1], colors[i][2]);
        if(isSetColorsBrightness)
            leds[i].fadeToBlackBy(colors[i][3] + BRIGHTNESS_FADE_BY);
    }
    FastLED.show();
    delayMilliseconds(50);
    if(isSetColorsBrightness)
        allClients[0].send("{\"status\":{\"command\":\"set-colors-brightness\",\"data\":\"colors-brightness-set\"}}");
    else
        allClients[0].send("{\"status\":{\"command\":\"set-colors\",\"data\":\"colors-set\"}}");
}

void setNeoPixelMusic(int colors[])
{
    for(int i = 0; i < NUM_LEDS; i++) {
        leds[i].setRGB(colors[0], colors[1], colors[2]);
        leds[i].fadeToBlackBy(colors[3] + BRIGHTNESS_FADE_BY);
    }
    FastLED.show();
    delayMilliseconds(50);
    allClients[0].send("{\"status\":{\"command\":\"set-music\",\"data\":\"task-started\"}}");
}

void setNeoPixelRangeColors(int colors[], int startId, int endId)
{
    for(int i = startId; i <= endId; i++) {
        leds[i].setRGB(colors[0], colors[1], colors[2]);
        leds[i].fadeToBlackBy(colors[3] + BRIGHTNESS_FADE_BY);
    }
    FastLED.show();
    delayMilliseconds(50);
}

void setNeoPixelColorsUniform(int colors[])
{
    for(int i = 0; i < NUM_LEDS; i++) {
        leds[i].setRGB(colors[0], colors[1], colors[2]);
    }
    FastLED.show();
    delayMilliseconds(50);
}

void setNeoPixelColor(int iLed, int colors[])
{
    leds[iLed].setRGB(colors[0], colors[1], colors[2]);
    FastLED.show();
    delayMilliseconds(50);
    allClients[0].send("{\"status\":{\"command\":\"set-color\",\"data\":\"led-color-set\"}}");
}

void setNeoPixelBrightness(int iLed, int brightnessValue)
{
    HsvColor hsvColor;
    RgbColor rgbColor;
    rgbColor.r = leds[iLed].r;
    rgbColor.g = leds[iLed].g;
    rgbColor.b = leds[iLed].b;
    rgbToHsv(rgbColor, hsvColor);
    leds[iLed] = CHSV(hsvColor.h, hsvColor.s, brightnessValue);
    FastLED.show();
    delayMilliseconds(50);
    allClients[0].send("{\"status\":{\"command\":\"set-led-brightness\",\"data\":\"led-brightness-set\"}}");
}

void getNeoPixelBrightness(int iLed){
    HsvColor hsvColor;
    RgbColor rgbColor;
    rgbColor.r = leds[iLed].r;
    rgbColor.g = leds[iLed].g;
    rgbColor.b = leds[iLed].b;
    rgbToHsv(rgbColor, hsvColor);
    if(!isTaskRunning)
      allClients[0].send("{\"data\":" + String(hsvColor.v) + "}");
}

void setNeoPixelRainbow(){
    fill_rainbow(leds, NUM_LEDS, 0, 255/NUM_LEDS);
    fadeToBlackBy(leds, NUM_LEDS, BRIGHTNESS_FADE_BY);
    FastLED.show();
    delayMilliseconds(50);
    if(!isTaskRunning)
      allClients[0].send("{\"status\":{\"command\":\"set-rainbow\",\"data\":\"rainbow-set\"}}");
}

void getNeoPixelColors(){
    String jsonData = "{\"data\":[";
    for(int i = 0; i < NUM_LEDS; i++) {
        if(i < NUM_LEDS-1)
            jsonData += "{\"red\":" + String(leds[i].r) + ",\"green\":" + String(leds[i].g) + ",\"blue\":" + String(leds[i].b) + "},";
        else
            jsonData += "{\"red\":" + String(leds[i].r) + ",\"green\":" + String(leds[i].g) + ",\"blue\":" + String(leds[i].b) + "}]}";
    }
    if(!isTaskRunning)
      allClients[0].send(jsonData);
}

void getNeoPixelColor(int iLed){
    String jsonData = "{\"red\":" + String(leds[iLed].r) + ",\"green\":" + String(leds[iLed].g) + ",\"blue\":" + String(leds[iLed].b) + "}";
    if(!isTaskRunning)
      allClients[0].send(jsonData);
}

void flowNeoPixelRainbow(const String& flowDirection, const int delayMs){
    int tempColors[3];
    int previousColors[3];
    bool isFirst = true;
    if(flowDirection == "right")
    {
        for (int i = 0; i < NUM_LEDS; ++i)
        {
            if(isFirst)
            {
                isFirst = false;
                previousColors[0] = leds[i].r;
                previousColors[1] = leds[i].g;
                previousColors[2] = leds[i].b;
            }
            else
            {
                tempColors[0] = leds[i].r;
                tempColors[1] = leds[i].g;
                tempColors[2] = leds[i].b;
                leds[i].setRGB(previousColors[0], previousColors[1], previousColors[2]);
                previousColors[0] = tempColors[0];
                previousColors[1] = tempColors[1];
                previousColors[2] = tempColors[2];
            }
        }
        leds[0].setRGB(previousColors[0], previousColors[1], previousColors[2]);
    }
    else if(flowDirection == "left")
    {
        for (int i = (NUM_LEDS - 1); i >= 0; --i)
        {
            if(isFirst)
            {
                isFirst = false;
                previousColors[0] = leds[i].r;
                previousColors[1] = leds[i].g;
                previousColors[2] = leds[i].b;
            }
            else
            {
                tempColors[0] = leds[i].r;
                tempColors[1] = leds[i].g;
                tempColors[2] = leds[i].b;
                leds[i].setRGB(previousColors[0], previousColors[1], previousColors[2]);
                previousColors[0] = tempColors[0];
                previousColors[1] = tempColors[1];
                previousColors[2] = tempColors[2];
            }
        }
        leds[NUM_LEDS - 1].setRGB(previousColors[0], previousColors[1], previousColors[2]);
    }
    FastLED.show();
    delayMilliseconds(delayMs);
}

void clearLeds() {
    FastLED.clear();
    delayMilliseconds(50);
}

void pollAllClients() {
    for(auto& client : allClients) {
        client.poll();
        delayMilliseconds(1);
    }
}

void onMessageCallback(WebsocketsMessage message) {
    if(isDebugEnabled)
      Serial.println(message.data());
    if(isReceivingJson)
    {
        jsonData += message.data();
        trySetCommand(jsonData);
    }
    else
    {
        if(message.data() == "stop-task")
        {
            if(isTaskRunning)
                isTaskRunning = false;
            delayMilliseconds(1000);
        }
        else if(message.data() == "enable-debug")
            isDebugEnabled = true;
        else if(message.data() == "disable-debug")
            isDebugEnabled = false;
        else if(message.data() == "get-led-count")
            neoPixelCommand = GET_LED_COUNT;
        else if(message.data() == "get-task-is-running")
            neoPixelCommand = GET_TASK_IS_RUNNING;
        else if(message.data() == "get-brightness")
            neoPixelCommand = GET_BRIGHTNESS;
        else if(!isTaskRunning && isWebSocketReceiving)
        {
            if(message.data() == "set-rainbow")
                neoPixelCommand = SET_RAINBOW;
            else if(message.data() == "get-led-colors")
                neoPixelCommand = GET_LED_COLORS;
            else if(checkElementIn(message.data()))
            {
                jsonData = message.data();
                if(!trySetCommand(jsonData))
                    isReceivingJson = true;
            }
        }
    }
}

void setMusic()
{
    jsonData = jsonData.substring(jsonData.indexOf("set-music:") + 10, jsonData.indexOf(":set-music"));
    DynamicJsonDocument dynamicJsonDocument(1024);
    DeserializationError deserializationError = deserializeJson(dynamicJsonDocument, jsonData);
    delayMilliseconds(1);
    if (deserializationError) {
        Serial.print("deserializeJson() failed: ");
        Serial.println(deserializationError.c_str());
        Serial.println(jsonData);
        return;
    }
    delayMilliseconds(1);
    int colors[4];
    String hexValue = dynamicJsonDocument["hexRGBValue"];
    hexValue = hexValue.substring(hexValue.indexOf("#")+1);
    long long int rgbValue = strtoll(hexValue.c_str(), NULL, 16);
    byte rValue = (byte)(rgbValue >> 16);
    byte gValue = (byte)(rgbValue >> 8);
    byte bValue = (byte)(rgbValue);
    colors[0] = rValue;
    colors[1] = gValue;
    colors[2] = bValue;
    colors[3] = dynamicJsonDocument["brightness"];
    if(colors[3] < 0)
        colors[3] = 0;
    else if(colors[3] > ledStripBrightness)
        colors[3] = ledStripBrightness;
    delayMilliseconds(1);
    setNeoPixelMusic(colors);
}

void setPattern()
{
    bool isFirstPattern = true;
    ledPatterns.erase(ledPatterns.begin(), ledPatterns.end());
    jsonData = jsonData.substring(jsonData.indexOf("set-pattern:") + 12, jsonData.indexOf(":set-pattern"));
    String patternMode = jsonData.substring(jsonData.indexOf("\"mode\":\"") + 8, jsonData.indexOf("\","));
    jsonData = jsonData.substring(jsonData.indexOf("\"leds\":[") + 8, jsonData.indexOf("]"));
    do {
        if(!isFirstPattern)
            jsonData = jsonData.substring(jsonData.indexOf(",") + 1);
        DynamicJsonDocument dynamicJsonDocument(PATTERN_SIZE);
        DeserializationError deserializationError = deserializeJson(dynamicJsonDocument, jsonData);
        delayMilliseconds(1);
        if (deserializationError) {
            Serial.print("deserializeJson() failed: ");
            Serial.println(deserializationError.c_str());
            Serial.println(jsonData);
            return;
        }
        delayMilliseconds(1);
        LedPattern ledPattern;
        String ledId = dynamicJsonDocument["id"];
        ledPattern.id = ledId;
        String ledStartId = dynamicJsonDocument["start-id"];
        ledPattern.startId = ledStartId;
        String ledEndId = dynamicJsonDocument["end-id"];
        ledPattern.endId = ledEndId;
        String hexValue = dynamicJsonDocument["color"];
        hexValue = hexValue.substring(hexValue.indexOf("#")+1);
        long long int rgbValue = strtoll(hexValue.c_str(), NULL, 16);
        byte rValue = (byte)(rgbValue >> 16);
        byte gValue = (byte)(rgbValue >> 8);
        byte bValue = (byte)(rgbValue);
        ledPattern.colors[0] = rValue;
        ledPattern.colors[1] = gValue;
        ledPattern.colors[2] = bValue;
        ledPattern.colors[3] = dynamicJsonDocument["brightness"];
        if(ledPattern.colors[3] < 0)
            ledPattern.colors[3] = 0;
        else if(ledPattern.colors[3] > ledStripBrightness)
            ledPattern.colors[3] = ledStripBrightness;
        ledPattern.delay = (dynamicJsonDocument["delay"] > 0 ? dynamicJsonDocument["delay"] : 0);
        ledPatterns.push_back(ledPattern);
        jsonData = jsonData.substring(jsonData.indexOf("}") + 1);
        if(isFirstPattern)
            isFirstPattern = false;
    } while(jsonData.indexOf(",") > -1);
    allClients[0].send("{\"status\":{\"command\":\"set-pattern\",\"data\":\"task-started\"}}");
    delayMilliseconds(500);
    if(patternMode == "reverse")
    {
        xTaskCreatePinnedToCore(
            TaskReverseLedPatterns,                  /* pvTaskCode (Task Function Code Reference) */
            "TaskReverseLedPatterns",            /* pcName (Task Name) */
            1000,                   /* usStackDepth (Stack Size in Words) */
            &ledPatterns,                   /* pvParameters (Parameters) */
            1,                      /* uxPriority (Task Priority: 0-24) */
            &taskReverseHandle,            /* pxCreatedTask (Task Handle) */
            1                       /* xCoreID (Core 0 or 1: Setup and Loop are executed on Core 1; RF Control Functions are executed on Core 0); */
        );
        isWebSocketReceiving = false;
        isTaskRunning = true;
    }
    else if(patternMode == "loop")
    {
        xTaskCreatePinnedToCore(
            TaskLoopLedPatterns,                  /* pvTaskCode (Task Function Code Reference) */
            "TaskLoopLedPatterns",            /* pcName (Task Name) */
            1000,                   /* usStackDepth (Stack Size in Words) */
            &ledPatterns,                   /* pvParameters (Parameters) */
            1,                      /* uxPriority (Task Priority: 0-24) */
            &taskLoopHandle,            /* pxCreatedTask (Task Handle) */
            1                       /* xCoreID (Core 0 or 1: Setup and Loop are executed on Core 1; RF Control Functions are executed on Core 0); */
        );
        isWebSocketReceiving = false;
        isTaskRunning = true;
    }
    else if(patternMode == "flow-colors")
    {
        xTaskCreatePinnedToCore(
            TaskFlowColorsLedPatterns,                  /* pvTaskCode (Task Function Code Reference) */
            "TaskFlowColorsLedPatterns",            /* pcName (Task Name) */
            1000,                   /* usStackDepth (Stack Size in Words) */
            &ledPatterns,                   /* pvParameters (Parameters) */
            1,                      /* uxPriority (Task Priority: 0-24) */
            &taskFlowColorsHandle,            /* pxCreatedTask (Task Handle) */
            1                       /* xCoreID (Core 0 or 1: Setup and Loop are executed on Core 1; RF Control Functions are executed on Core 0); */
        );
        isWebSocketReceiving = false;
        isTaskRunning = true;
    }
    else if(patternMode == "once")
    {
          for (std::vector<LedPattern>::iterator it = ledPatterns.begin() ; it != ledPatterns.end(); ++it)
          {
              if((*it).id == "all")
                  setNeoPixelMusic((*it).colors);
              else if((*it).id == "range")
              {
                  if((*it).startId.toInt() < 0 || (*it).startId.toInt() > (NUM_LEDS - 1) || (*it).endId.toInt() < 0 || (*it).endId.toInt() > (NUM_LEDS - 1) || (*it).startId.toInt() >= (*it).endId.toInt())
                      continue;
                  setNeoPixelRangeColors((*it).colors, (*it).startId.toInt(), (*it).endId.toInt());
              }
              else
                  setNeoPixelColor((*it).id.toInt(), (*it).colors);
              if((*it).delay > 0)
                  delayMilliseconds((*it).delay);
          }
    }
}

void setFlowRainbow() {
    jsonData = jsonData.substring(jsonData.indexOf("flow-rainbow:") + 13, jsonData.indexOf(":flow-rainbow"));
    DynamicJsonDocument dynamicJsonDocument(54);
    DeserializationError deserializationError = deserializeJson(dynamicJsonDocument, jsonData);
    delayMilliseconds(1);
    if (deserializationError) {
        Serial.print("deserializeJson() failed: ");
        Serial.println(deserializationError.c_str());
        Serial.println(jsonData);
        return;
    }
    delayMilliseconds(1);
    rainbowSettings.delay = (dynamicJsonDocument["delay"] > 0 ? dynamicJsonDocument["delay"] : 0);
    String directionValue = dynamicJsonDocument["direction"];
    rainbowSettings.direction = directionValue;
    delayMilliseconds(1);
    allClients[0].send("{\"status\":{\"command\":\"flow-rainbow\",\"data\":\"task-started\"}}");
    delayMilliseconds(500);
    xTaskCreatePinnedToCore(
        TaskFlowColorsRainbow,                  /* pvTaskCode (Task Function Code Reference) */
        "TaskFlowColorsRainbow",            /* pcName (Task Name) */
        1000,                   /* usStackDepth (Stack Size in Words) */
        &rainbowSettings,                   /* pvParameters (Parameters) */
        1,                      /* uxPriority (Task Priority: 0-24) */
        &taskFlowColorsRainbowHandle,            /* pxCreatedTask (Task Handle) */
        1                       /* xCoreID (Core 0 or 1: Setup and Loop are executed on Core 1; RF Control Functions are executed on Core 0); */
    );
    isWebSocketReceiving = false;
    isTaskRunning = true;
}

void setColor()
{
    jsonData = jsonData.substring(jsonData.indexOf("set-color:") + 10, jsonData.indexOf(":set-color"));
    DynamicJsonDocument dynamicJsonDocument(61);
    DeserializationError deserializationError = deserializeJson(dynamicJsonDocument, jsonData);
    delayMilliseconds(1);
    if (deserializationError) {
        Serial.print("deserializeJson() failed: ");
        Serial.println(deserializationError.c_str());
        Serial.println(jsonData);
        return;
    }
    delayMilliseconds(1);
    int colors[3];
    String hexValue = dynamicJsonDocument["hexRGBValue"];
    hexValue = hexValue.substring(hexValue.indexOf("#")+1);
    long long int rgbValue = strtoll(hexValue.c_str(), NULL, 16);
    byte rValue = (byte)(rgbValue >> 16);
    byte gValue = (byte)(rgbValue >> 8);
    byte bValue = (byte)(rgbValue);
    colors[0] = rValue;
    colors[1] = gValue;
    colors[2] = bValue;
    String iLedValue = dynamicJsonDocument["iLed"];
    int iLed = iLedValue.toInt();
    delayMilliseconds(1);
    if(iLed >= 0 && iLed <= (NUM_LEDS-1))
        setNeoPixelColor(iLed, colors);
    else
        allClients[0].send("{\"status\":{\"command\":\"set-color\",\"data\":\"index-out-of-range\"}}");
}

void setLedBrightness()
{
    jsonData = jsonData.substring(jsonData.indexOf("set-led-brightness:") + 19, jsonData.indexOf(":set-led-brightness"));
    DynamicJsonDocument dynamicJsonDocument(52);
    DeserializationError deserializationError = deserializeJson(dynamicJsonDocument, jsonData);
    delayMilliseconds(1);
    if (deserializationError) {
        Serial.print("deserializeJson() failed: ");
        Serial.println(deserializationError.c_str());
        Serial.println(jsonData);
        return;
    }
    delayMilliseconds(1);
    int brightnessValue = dynamicJsonDocument["brightness"];
    String iLedValue = dynamicJsonDocument["iLed"];
    int iLed = iLedValue.toInt();
    delayMilliseconds(1);
    if((iLed >= 0 && iLed <= (NUM_LEDS-1)) && (brightnessValue >= 0 && brightnessValue <= ledStripBrightness))
        setNeoPixelBrightness(iLed, brightnessValue);
    else if(brightnessValue >= 0 && brightnessValue <= ledStripBrightness)
        allClients[0].send("{\"status\":{\"command\":\"set-led-brightness\" ,\"data\":\"brightness-out-of-range\"}}");
    else if(iLed >= 0 && iLed <= (NUM_LEDS-1))
        allClients[0].send("{\"status\":{\"command\":\"set-led-brightness\",\"data\":\"index-out-of-range\"}}");
}

void getLedBrightness()
{
    jsonData = jsonData.substring(jsonData.indexOf("get-led-brightness:") + 19, jsonData.indexOf(":get-led-brightness"));
    DynamicJsonDocument dynamicJsonDocument(25);
    DeserializationError deserializationError = deserializeJson(dynamicJsonDocument, jsonData);
    delayMilliseconds(1);
    if (deserializationError) {
        Serial.print("deserializeJson() failed: ");
        Serial.println(deserializationError.c_str());
        Serial.println(jsonData);
        return;
    }
    delayMilliseconds(1);
    String iLedValue = dynamicJsonDocument["iLed"];
    int iLed = iLedValue.toInt();
    delayMilliseconds(1);
    if(iLed >= 0 && iLed <= (NUM_LEDS-1))
        getNeoPixelBrightness(iLed);
    else
        allClients[0].send("{\"status\":{\"command\":\"get-led-brightness\",\"data\":\"index-out-of-range\"}}");
}

void setGlobalBrightness()
{
    jsonData = jsonData.substring(jsonData.indexOf("set-brightness:") + 15, jsonData.indexOf(":set-brightness"));
    DynamicJsonDocument dynamicJsonDocument(27);
    DeserializationError deserializationError = deserializeJson(dynamicJsonDocument, jsonData);
    delayMilliseconds(1);
    if (deserializationError) {
        Serial.print("deserializeJson() failed: ");
        Serial.println(deserializationError.c_str());
        Serial.println(jsonData);
        return;
    }
    delayMilliseconds(1);
    int brightnessValue = dynamicJsonDocument["brightness"];
    if(brightnessValue >= 0 && brightnessValue <= 255)
    {
        ledStripBrightness = brightnessValue;
        FastLED.setBrightness(brightnessValue);
        allClients[0].send("{\"status\":{\"command\":\"set-brightness\",\"data\":\"global-brightness-set\"}}");
    }
}

void setColors(bool isSetColorsBrightness)
{
    int jsonDocumentSize = 0;
    if(isSetColorsBrightness)
    {
        jsonData = jsonData.substring(jsonData.indexOf("set-colors-brightness:") + 22, jsonData.indexOf(":set-colors-brightness"));
        jsonDocumentSize = 16400;
    }
    else
    {
        jsonData = jsonData.substring(jsonData.indexOf("set-colors:") + 11, jsonData.indexOf(":set-colors"));
        jsonDocumentSize = 4096;
    }
    DynamicJsonDocument dynamicJsonDocument(jsonDocumentSize);
    DeserializationError deserializationError = deserializeJson(dynamicJsonDocument, jsonData);
    delayMilliseconds(1);
    if (deserializationError) {
        Serial.print("deserializeJson() failed: ");
        Serial.println(deserializationError.c_str());
        Serial.println(jsonData);
        return;
    }
    delayMilliseconds(50);
    int colors[NUM_LEDS][4];
    if(isSetColorsBrightness)
    {
        for(int i = 0; i < 150; ++i)
        {
            String hexValue = dynamicJsonDocument[String(i+1)]["hexRGBValue"];
            hexValue = hexValue.substring(hexValue.indexOf("#")+1);
            long long int rgbValue = strtoll(hexValue.c_str(), NULL, 16);
            byte rValue = (byte)(rgbValue >> 16);
            byte gValue = (byte)(rgbValue >> 8);
            byte bValue = (byte)(rgbValue);
            colors[i][0] = rValue;
            colors[i][1] = gValue;
            colors[i][2] = bValue;
            colors[i][3] = dynamicJsonDocument[String(i+1)]["brightness"];
            if(colors[i][3] < 0)
                colors[i][3] = 0;
            else if(colors[i][3] > ledStripBrightness)
                colors[i][3] = ledStripBrightness;
            delayMilliseconds(1);
        }
    }
    else
    {
        for(int i = 0; i < 150; ++i)
        {
            String hexValue = dynamicJsonDocument[String(i+1)];
            hexValue = hexValue.substring(hexValue.indexOf("#")+1);
            long long int rgbValue = strtoll(hexValue.c_str(), NULL, 16);
            byte rValue = (byte)(rgbValue >> 16);
            byte gValue = (byte)(rgbValue >> 8);
            byte bValue = (byte)(rgbValue);
            colors[i][0] = rValue;
            colors[i][1] = gValue;
            colors[i][2] = bValue;
            colors[i][3] = 0;
            delayMilliseconds(1);
        }
    }
    setNeoPixelColors(colors, isSetColorsBrightness, 0, NUM_LEDS);
}

void getColor(){
    jsonData = jsonData.substring(jsonData.indexOf("get-led-color:") + 14, jsonData.indexOf(":get-led-color"));
    DynamicJsonDocument dynamicJsonDocument(25);
    DeserializationError deserializationError = deserializeJson(dynamicJsonDocument, jsonData);
    delayMilliseconds(1);
    if (deserializationError) {
        Serial.print("deserializeJson() failed: ");
        Serial.println(deserializationError.c_str());
        Serial.println(jsonData);
        return;
    }
    delayMilliseconds(1);
    String iLedValue = dynamicJsonDocument["iLed"];
    int iLed = iLedValue.toInt();
    delayMilliseconds(1);
    if(iLed >= 0 && iLed <= (NUM_LEDS-1))
        getNeoPixelColor(iLed);
    else
        allClients[0].send("{\"status\":{\"command\":\"get-led-color\",\"data\":\"index-out-of-range\"}}");
}

void onEventsCallback(WebsocketsEvent event, String data) {
    if(event == WebsocketsEvent::ConnectionOpened) {
        Serial.println("Connection Opened");
    } else if(event == WebsocketsEvent::ConnectionClosed) {
        Serial.println("Connection Closed");
        isWebSocketConnected = false;
    } else if(event == WebsocketsEvent::GotPing) {
        Serial.println("Got a Ping!");
    } else if(event == WebsocketsEvent::GotPong) {
        Serial.println("Got a Pong!");
    }
}
