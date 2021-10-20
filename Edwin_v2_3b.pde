/**
* Edwin
* version 2.3 beta
*
* Edwin is a god class that essentially allows you to have layers (multiple sketches) in Processing
* Each "layer" class must implement my interface Kid in order to be compatible with Edwin 
* and then added to Edwin in setup() (or dynamically from your Scheme or whatever) using edwin.addKid()
* Each Kid class gets its own draw, mouse, and keyboard functions so you don't have to
* flood the ones provided by Processing. That means Edwin hijacks mouseMoved() and all like it!
* To use my album/sprite editor just include edwin.addKid(new AlbumEditor()); in your setup()
* When reading my code it may help to know that I often end functions early (if (!precondition) return;)
* Feel free to edit anything and everything in here
* For a small example project see the comment below the Edwin class
*
* Created by mercurus - moonbaseone@hush.com
*/


import java.util.Arrays;
import java.util.BitSet;
import java.util.Collections;
import java.util.Map;
import java.util.HashMap;
import java.awt.Color;
import javax.swing.JColorChooser;
import javax.swing.JOptionPane;


//hijack Processing's mouse/keyboard input functions
void keyPressed(KeyEvent event) { edwin.handleKeyboard(event); }
void keyReleased(KeyEvent event) { edwin.handleKeyboard(event); }
void mouseMoved(MouseEvent event) { edwin.handleMouse(event); }
void mousePressed(MouseEvent event) { edwin.handleMouse(event); }
void mouseDragged(MouseEvent event) { edwin.handleMouse(event); }
void mouseReleased(MouseEvent event) { edwin.handleMouse(event); }
void mouseWheel(MouseEvent event) { edwin.handleMouse(event); }


/**
* I started off trying to implement an Entity Component System
* So far Components haven't been useful for me so they're gone
* Then I renamed Entities to Kids, and Systems to Schemes
* The mouse/keyboard functions for Kid return a String 
* so it can communicate backwards to whoever called it 
* (which may not be necessary most times, so returning an empty string is fine)
*/
interface Kid {
    void draw(PGraphics canvas);
    String mouse(); 
    String keyboard(KeyEvent event);
}


/**
* These are intended to give you a way to manipulate Kids and have them talk to each other
* Create your Scheme class and add it to Edwin similar to adding Kids - edwin.addScheme(new MyScheme());
* All Schemes are called in edwin.think() before the Kids
*/
interface Scheme {
    void play(ArrayList<Kid> kids);
}


/**
* Singleton that you add Kids and Schemes to. It's a fairly small class really
*/
class Edwin {
    PGraphics canvas;
    PFont defaultFont; //not necessary
    ArrayList<Kid> kids, dismissed;
    ArrayList<Scheme> schemes;
    //now for some values you might check in your Kid classes
    XY mouseHoldInitial, mouseLast;
    int mouseHoldStartMillis, mouseHeldMillis, mouseTickLength, mouseTicking;
    int mouseBtnBeginHold, mouseBtnHeld, mouseBtnReleased, mouseWheelValue;
    int bgdColor, lastMillis;
    float elapsedTime; //only used this once so far in Ricochet...
    boolean useSmooth, mouseHoldTicked, mouseHovering;
    boolean isShiftDown, isCtrlDown, isAltDown;

    Edwin() { this(EdColors.DX_BLACK); }
    Edwin(int defaultBgdColor) {
        bgdColor = defaultBgdColor;
        canvas = createGraphics(width, height, P2D);
        defaultFont = createFont(EdFiles.DATA_FOLDER + "consolas.ttf", 12);
        schemes = new ArrayList<Scheme>();
        kids = new ArrayList<Kid>();
        dismissed = new ArrayList<Kid>(); //in a Scheme if some Kid needs to leave use edwin.dismiss(kid);
        mouseHoldInitial = new XY();
        mouseLast = new XY();
        mouseHeldMillis = mouseHoldStartMillis = mouseTicking = lastMillis = 0;
        mouseBtnHeld = mouseBtnBeginHold = mouseBtnReleased = mouseWheelValue = 0;
        mouseHovering = false; //true if the mouse event is a plain move
        mouseHoldTicked = false; //true for one draw() tick every couple ms when you've been holding down a mouse button
        mouseTickLength = 17; //number of cycles between ticks
        useSmooth = true; //use Processing's built-in smooth() or noSmooth()
        isShiftDown = isCtrlDown = isAltDown = false;
        println(":::Edwin::: v2.3b"); 
    }

    void addKid(Kid kid) {
        kids.add(kid);
    }

    void dismissKid(Kid kid) {
        dismissed.add(kid);
    }

    void addScheme(Scheme scheme) {
        schemes.add(scheme);
    }

    void think() {
        elapsedTime = (millis() - lastMillis) / 1000.0;
        lastMillis = millis();

        if (mouseBtnHeld != 0) {
            mouseHeldMillis = millis() - mouseHoldStartMillis;
            if (++mouseTicking > mouseTickLength) {
                mouseTicking = 0;
                mouseHoldTicked = true;
            }
        }

        for (Scheme scheme : schemes) {
            scheme.play(kids);
        }
        for (Kid kid : dismissed) {
            kids.remove(kid);
        }
        dismissed.clear();

        //draw the family
        if (useSmooth) canvas.smooth();
        else canvas.noSmooth();
        canvas.beginDraw();
        canvas.background(bgdColor);
        canvas.textFont(defaultFont);
        for (Kid kid : kids) {
            kid.draw(canvas);
        }
        canvas.endDraw();
        mouseHoldTicked = false;
    }

    void handleMouse(MouseEvent event) {
        boolean resetMouse = false;
        int action = event.getAction();
        if (action == MouseEvent.PRESS) {
            mouseHoldInitial.set(mouseX, mouseY);
            mouseBtnBeginHold = mouseBtnHeld = event.getButton();
            mouseHoldStartMillis = millis();
            mouseBtnReleased = 0;
        }
        else if (action == MouseEvent.RELEASE) {
            mouseBtnReleased = mouseBtnHeld;
            mouseBtnBeginHold = mouseBtnHeld = 0;
            resetMouse = true; //other resets need to happen after calling each Kid so they can use the values first
        }
        else if (action == MouseEvent.DRAG) {
            mouseBtnBeginHold = 0;
        }
        else if (action == MouseEvent.WHEEL) {
            mouseWheelValue = event.getCount(); // 1 == down (toward you), -1 == up (away from you)
        }
        else if (action == MouseEvent.MOVE) {
            mouseHovering = true;
        }

        //notify the kids
        for (Kid kid : kids) {
            kid.mouse();
        }

        //wrap up
        if (resetMouse) {
            mouseHeldMillis = mouseBtnReleased = mouseTicking = 0;
            //mouseHoldInitial.set(mouseX, mouseY);
        }
        mouseLast.set(mouseX, mouseY);
        mouseWheelValue = 0;
        mouseHovering = false;
    }

    /**
    * Keyboard interactions are complicated
    * so each Kid will get handed the event and let them react
    */
    void handleKeyboard(KeyEvent event) {
        isShiftDown = event.isShiftDown();
        isCtrlDown = event.isControlDown();
        isAltDown = event.isAltDown();
        for (Kid kid : kids) {
            kid.keyboard(event);
        }
    }
} //end Edwin


/*** An example project using Edwin:

Edwin edwin;

void setup() {
    size(800, 600);
    edwin = new Edwin();
    edwin.addKid(new Simple());

    edwin.addKid(new PalettePicker(EdColors.dxPalette(), "Set window color") {
        public void colorSelected(int paletteIndex) { 
            edwin.bgdColor = this.colors.get(paletteIndex);
        }
    });
}

void draw() {
    edwin.think();
    image(edwin.canvas, 0, 0);
}

class Simple implements Kid {
    Album buttonAlbum; //Albums do not have coordinates, they're like a condensed spritesheet
    XYWH buttonBody; //we'll use this to track the image's body when drawn

    Simple() {
        buttonAlbum = new Album(GadgetPanel.BUTTON_FILENAME);
        buttonBody = new XYWH(80, 20, buttonAlbum.w, buttonAlbum.h);
    }

    void draw(PGraphics canvas) {
        canvas.image(buttonAlbum.page(GadgetPanel.OK), buttonBody.x, buttonBody.y);
    }

    String mouse() {
        if (edwin.mouseBtnReleased == LEFT && buttonBody.isMouseOver()) {
            println("Button clicked");
        }
        return "";
    }

    String keyboard(KeyEvent event) {
        return "";
    }
}

***/


// ===================================
// UTILITY CLASSES
// ===================================


/** Simple class for holding coordinates. Doesn't do as much as a PVector... */
class XY {
    float x, y;
    XY() { set(0, 0); }
    XY(float _x, float _y) { set(_x, _y); }
    XY clone() { return new XY(x, y); }
    String toString() { return "[x:" + String.format("%.2f", x) + " y:" + String.format("%.2f", y) + "]"; }
    boolean equals(XY other) { return equals(other.x, other.y); }
    boolean equals(float _x, float _y) { return (x == _x && y == _y); }
    void set(XY other) { set(other.x, other.y); }
    void set(float _x, float _y) { x = _x; y = _y; }
    float distance(XY other) { return distance(other.x, other.y); }
    float distance(float _x, float _y) { return sqrt(pow(x - _x, 2) + pow(y - _y, 2)); }
    float angSin(XY other) { return sin(angle(other)); }
    float angCos(XY other) { return cos(angle(other)); }
    float angle(XY other) { return angle(other.x, other.y); }
    float angle(float _x, float _y) { return atan2(y - _y, x - _x); } //radians
    XY midpoint(XY other) { return midpoint(other.x, other.y); }
    XY midpoint(float _x, float _y) { return new XY((x + _x) / 2.0, (y + _y) / 2.0); }
}


/**
* A class for rectangle coordinates. Stores the top-left xy anchor, 
* width and height, plus a handful of helper functions.
* x and y are declared in the parent class XY
* I do this to demonstrate inheritance, not because I'm hopelessly addicted to OOP
*/
class XYWH extends XY {
    float w, h;
    XYWH parent = null;
    XYWH() { set(0, 0, 0, 0); }
    XYWH(float _x, float _y, float _w, float _h) { set(_x, _y, _w, _h); }
    XYWH(float _x, float _y, float _w, float _h, XYWH parent) { set(_x, _y, _w, _h); this.parent = parent; }
    XYWH clone() { return new XYWH(x, y, w, h); }
    String toString() { return "[x:" + x + " y:" + y + " | w:" + w + " h:" + h + "]"; }
    boolean equals(XYWH other) { return equals(other.x, other.y, other.w, other.h); }
    boolean equals(float _x, float _y, float _w, float _h) { return (x == _x && y == _y && w == _w && h == _h); }
    void set(XYWH other) { set(other.x, other.y, other.w, other.h); }
    void set(float _x, float _y, float _w, float _h) { x = _x; y = _y; w = _w; h = _h; }
    void setSize(XYWH other) { setSize(other.w, other.h); }
    void setSize(float _w, float _h) { w = _w; h = _h; }

    /** Returns the x coordinate plus the width, the right boundary */
    float xw() { return x + w; }

    /** Returns the y coordinate plus the height, the bottom boundary */
    float yh() { return y + h; }

    /** These are useful when your object has a parent  */
    float screenX()  { 
        if (parent != null) return parent.screenX() + x; 
        else return x; 
    }
    float screenXW() { 
        if (parent != null) return parent.screenX() + xw(); 
        else return xw(); 
    }
    float screenY()  { 
        if (parent != null) return parent.screenY() + y; 
        else return y; 
    }
    float screenYH() { 
        if (parent != null) return parent.screenY() + yh(); 
        else return yh(); 
    }
    
    /** Returns true if the incoming body overlaps this one */
    boolean intersects(XYWH other) {
        if (other.xw() >= x && other.x <= xw() 
        && other.yh() >= y && other.y <= yh()) {
            return true;
        }
        return false;
    }

    /** Takes a x coordinate and gives you the closest value inbounds */
    float insideX(float _x) {
        if (_x < x) {
            return x;
        }
        else if (_x >= xw()) {
            return xw();
        }
        return _x;
    }

    /** Takes a y coordinate and gives you the closest value inbounds */
    float insideY(float _y) {
        if (_y < y) {
            return y;
        }
        else if (_y >= yh()) {
            return yh();
        }
        return _y;
    }

    /** Returns true if the mouse is inbounds */
    boolean isMouseOver() { return containsPoint(mouseX, mouseY); }
    boolean containsPoint(XY other) { return containsPoint(other.x, other.y); }
    boolean containsPoint(float _x, float _y) {
        if (_x >= screenX() 
        && _x <= screenXW() 
        && _y >= screenY() 
        && _y <= screenYH()) {
            return true;
        }
        return false;
    }
}


/** A class for keeping track of an integer that has a minimum and a maximum. */
class BoundedInt {
    int value, minimum, maximum, step;
    boolean isEnabled, loops;
    BoundedInt(int newMax) { this(0, newMax); }
    BoundedInt(int newMax, boolean loops) { this(0, newMax, 0, 1, loops); }
    BoundedInt(int newMin, int newMax) { this(newMin, newMax, newMin); }
    BoundedInt(int newMin, int newMax, int num) { this(newMin, newMax, num, 1); }
    BoundedInt(int newMin, int newMax, int num, int increment) { this(newMin, newMax, num, increment, false); }
    BoundedInt(int newMin, int newMax, int num, int increment, boolean doesLoop) {
        reset(newMin, newMax, num);
        step = increment; //amount to inc/dec each time
        loops = doesLoop; //if you increment() at max then value gets set to min, and vice versa
        isEnabled = true; //something you can use if you want
    }
    BoundedInt clone() { BoundedInt schwarzenegger = new BoundedInt(minimum, maximum, value, step); schwarzenegger.loops = loops; schwarzenegger.isEnabled = isEnabled; return schwarzenegger; }
    String toString() { return "[min:" + minimum + "|max:" + maximum + "|val:" + value + "]"; }
    void set(int num) { value = min(max(minimum, num), maximum); } //assign value to num, or to minimum/maximum if it's out of bounds
    void reset(int newMin, int newMax) { reset(newMin, newMax, newMin); }
    void reset(int newMin, int newMax, int num) { minimum = newMin; maximum = newMax; value = num; }
    boolean contains(int num) { return (num >= minimum && num <= maximum); }
    boolean atMin() { return (value == minimum); }
    boolean atMax() { return (value == maximum); }
    int randomize() { value = (int)random(minimum, maximum + 1); return value; } //+1 here because the max of random() is exclusive
    int minimize() { value = minimum; return value; }
    int maximize() { value = maximum; return value; }

    int increment() { return increment(step); }
    int increment(int num) {
        if (value + num < minimum) { //if num is negative and moves value below the min
            value = loops ? maximum : minimum;
        }
        else if (value + num > maximum) {
            value = loops ? minimum : maximum;
        }
        else {
            value += num;
        }
        return value;
    }

    int decrement() { return decrement(step); }
    int decrement(int num) {
        if (value - num > maximum) { //if num is negative and moves value above the max
            value = loops ? minimum : maximum;
        }
        else if (value - num < minimum) { 
            value = loops ? maximum : minimum;
        }
        else {
            value -= num;
        }
        return value;
    }

    int incrementMin() { return incrementMin(step); }
    int incrementMin(int num) { return setMin(minimum + num); }
    int decrementMin() { return decrementMin(step); }
    int decrementMin(int num) { return setMin(minimum - num); }
    int setMin(int newMin) {
        if (newMin > maximum) {
            minimum = maximum;
            return minimum;
        }
        minimum = newMin;
        value = max(minimum, value);
        return minimum;
    }

    int incrementMax() { return incrementMax(step); }
    int incrementMax(int num) { return setMax(maximum + num); }
    int decrementMax() { return decrementMax(step); }
    int decrementMax(int num) { return setMax(maximum - num); }
    int setMax(int newMax) {
        if (newMax < minimum) {
            maximum = minimum;
            return maximum;
        }
        maximum = newMax;
        value = min(maximum, value);
        return maximum;
    }
}


/** A class for keeping track of a floating point decimal that has a minimum and a maximum. */
class BoundedFloat {
    float value, minimum, maximum, step;
    boolean isEnabled, loops;
    BoundedFloat(float newMax) { this(0, newMax); }
    BoundedFloat(float newMax, boolean loops) { this(0, newMax, 0, 1, loops); }
    BoundedFloat(float newMin, float newMax) { this(newMin, newMax, newMin); }
    BoundedFloat(float newMin, float newMax, float num) { this(newMin, newMax, num, 1); }
    BoundedFloat(float newMin, float newMax, float num, float increment) { this(newMin, newMax, num, increment, false); }
    BoundedFloat(float newMin, float newMax, float num, float increment, boolean doesLoop) {
        reset(newMin, newMax, num);
        step = increment; //amount to inc/dec each time
        loops = doesLoop; //if you increment() at max then value gets set to min, and vice versa
        isEnabled = true; //something you can use if you want
    }
    BoundedFloat clone() { BoundedFloat schwarzenegger = new BoundedFloat(minimum, maximum, value, step); schwarzenegger.loops = loops; schwarzenegger.isEnabled = isEnabled; return schwarzenegger; }
    String toString() { return "[min:" + minimum + "|max:" + maximum + "|val:" + value + "]"; }
    void set(float num) { value = min(max(minimum, num), maximum); } //assign value to num, or to minimum/maximum if it's out of bounds
    void reset(float newMin, float newMax) { reset(newMin, newMax, newMin); }
    void reset(float newMin, float newMax, float num) { minimum = newMin; maximum = newMax; value = num; }
    boolean contains(float num) { return (num >= minimum && num <= maximum); }
    boolean atMin() { return value == minimum; }
    boolean atMax() { return value == maximum; }
    float randomize() { value = random(minimum, maximum); return value; }
    float minimize() { value = minimum; return value; }
    float maximize() { value = maximum; return value; }

    float increment() { return increment(step); }
    float increment(float num) {
        if (value + num > maximum) {
            if (loops) value = minimum;
            else value = maximum;
            return value;
        }
        value += num;
        return value;
    }

    float decrement() { return decrement(step); }
    float decrement(float num) {
        if (value - num < minimum) {
            if (loops) value = maximum;
            else value = minimum;
            return value;
        }
        value -= num;
        return value;
    }

    float incrementMin() { return incrementMin(step); }
    float incrementMin(float num) { return setMin(minimum + num); }
    float decrementMin() { return decrementMin(step); }
    float decrementMin(float num) { return setMin(minimum - num); }
    float setMin(float newMin) {
        if (newMin > maximum) {
            minimum = maximum;
            return minimum;
        }
        minimum = newMin;
        value = max(minimum, value);
        return minimum;
    }

    float incrementMax() { return incrementMax(step); }
    float incrementMax(float num) { return setMax(maximum + num); }
    float decrementMax() { return decrementMax(step); }
    float decrementMax(float num) { return setMax(maximum - num); }
    float setMax(float newMax) {
        if (newMax < minimum) {
            maximum = minimum;
            return maximum;
        }
        maximum = newMax;
        value = min(maximum, value);
        return maximum;
    }
}


/**
* Basically a callback function
*/
class Command {
    void execute(String arg) {
        println("uh oh, empty Command object [arg=" + arg + "]");
    }
}


/** 
* Give this function an octave count and it will give you perlin noise
* with the max number of points you can have with that number of octaves.
* Values will be between 0 and 1
* See https://www.youtube.com/watch?v=6-0UaeJBumA
*/
float[] perlinNoise1D(int octaves) {
    int count, pitch, sample1, sample2;
    float noiseVal, scale, scaleAcc, scaleBias, blend;
    count = (int)pow(2, octaves);
    scaleBias = 2.0; //2 is standard. lower = more pronounced peaks

    float[] seedArray = new float[count];
    for (int i = 0; i < seedArray.length; i++) {
        seedArray[i] = random(1);
    }

    float[] values = new float[count];
    for (int x = 0; x < count; x++) {
        scale = 1;
        scaleAcc = 0;
        noiseVal = 0;
        for (int o = 0; o < octaves; o++) {
            pitch = count >> o;
            sample1 = (x / pitch) * pitch;
            sample2 = (sample1 + pitch) % count;
            blend = (x - sample1) / (float)pitch;
            noiseVal += scale * ((1 - blend) * seedArray[sample1] + blend * seedArray[sample2]);
            scaleAcc += scale;
            scale /= scaleBias;
        }
        values[x] = noiseVal / scaleAcc;
        //println(values[x]);
    }
    //println("len:" + values.length + ",  first:" + values[0] + ",  last:" + values[values.length - 1]);
    return values;
}

/** broken? tint should probably be between -1.0 and 1.0 */
int colorTint(int colr, float tint) {
    float r = colr >> 16 & 0xFF, //see https://processing.org/reference/red_.html
        g = colr >> 8 & 0xFF, //https://processing.org/reference/green_.html
        b = colr & 0xFF; //https://processing.org/reference/blue_.html
    r = max(0, min(255, r + (r * tint)));
    g = max(0, min(255, g + (g * tint)));
    b = max(0, min(255, b + (b * tint)));
    return color(r, g, b);
}


/** returns your JSON key and value as "key":value, */
String jsonKV(String keyName, int value) { return jsonKV(keyName, String.valueOf(value)); }
String jsonKV(String keyName, float value) { return jsonKV(keyName, String.valueOf(value)); }
String jsonKV(String keyName, boolean value) { return jsonKV(keyName, String.valueOf(value)); }
String jsonKV(String keyName, String value) { return jsonKVNoComma(keyName, value + ","); }
String jsonKVString(String keyName, String value) { return jsonKVNoComma(keyName, "\"" + value + "\","); }
String jsonKVNoComma(String keyName, String value) { return "\"" + keyName + "\":" + value; }


/** Constants */
final String 
TAB = "\t",
HELLO = "hello";

static class EdColors {
    //https://lospec.com/palette-list/dirtyboy
    public static final int 
    INFO = #5881C1,
    UI_LIGHT = #C4CFA1, 
    UI_NORMAL = #8B956D, 
    UI_DARK = #4D533C,
    UI_DARKEST = #1F1F1F,
    UI_EMPHASIS = #6E3232, //#73342E,
    ROW_EVEN = #080808,
    ROW_ODD = #303030,
    //https://lospec.com/palette-list/15p-dx
    DX_RED = #6E3232,
    DX_ORANGE = #BB5735,
    DX_YELLOW_ORANGE = #DF9245,
    DX_YELLOW = #ECD274,
    DX_YELLOW_GREEN = #83A816,
    DX_GREEN = #277224,
    DX_DARK_BLUE = #173B47,
    DX_BLUE = #046894,
    DX_AQUAMARINE = #17A1A9,
    DX_SKY_BLUE = #81DBCD,
    DX_WHITE = #FDF9F1,
    DX_SAND = #C7B295,
    DX_CLAY = #87715B,
    DX_DIRT = #463731,
    DX_BROWN = #201708,
    DX_BLACK = #070403,
    DX_GREY = #55535A;

    public static final int[] dxPalette() {
        return new int[] {
            DX_SAND,
            DX_CLAY,
            DX_DIRT,
            DX_BROWN,
            DX_BLACK,
            DX_YELLOW,
            DX_YELLOW_ORANGE,
            DX_ORANGE,
            DX_RED,
            DX_GREY,
            DX_WHITE,
            DX_SKY_BLUE,
            DX_AQUAMARINE,
            DX_BLUE,
            DX_DARK_BLUE,
            DX_YELLOW_GREEN,
            DX_GREEN
        };
    }
}

/** JSON keys for Album files */
static class EdFiles {
    public static final String DATA_FOLDER = "data/",
    BGD_COLOR = "backgroundColor",
    PX_WIDTH = "width",
    PX_HEIGHT = "height",
    DOTS = "dots",
    PIXEL_LAYERS = "pixelLayers",
    COLOR_PALETTE = "colorPalette",
    PALETTE_INDEX = "paletteIndex",
    TRANSPARENCY = "transparency",
    PIXEL_LAYER_NAME = "pixelLayerName",
    ALBUM_PAGES = "albumPages",
    PAGE_NAME = "pageName",
    LAYER_NUMBERS = "layerNumbers";
}

/**
* Ripped from Java's KeyEvent -- https://docs.oracle.com/javase/8/docs/api/constant-values.html
* Gives finer control over keyboard input. Processing simplified things with their 
* global variables "key" and "keyCode" but these are easier for me.
* You could also use java.awt.event.KeyEvent instead if you know the relevant VK_* constant
* see https://processing.org/reference/keyCode.html
*/
static class Keycodes {
    public static final int UNDEFINED = 0,
    TAB = 9,
    SHIFT = 16, //probably easier to use event.isShiftDown(), event.isAltDown(), event.isControlDown()
    CONTROL = 17,
    ALT = 18,
    LEFT = 37,
    UP = 38,
    RIGHT = 39,
    DOWN = 40,
    //top row numbers
    ZERO = 48,
    ONE = 49,
    TWO = 50,
    THREE = 51,
    FOUR = 52,
    FIVE = 53,
    SIX = 54,
    SEVEN = 55,
    EIGHT = 56,
    NINE = 57,
    //letters obv
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    H = 72,
    I = 73,
    J = 74,
    K = 75,
    L = 76,
    M = 77,
    N = 78,
    O = 79,
    P = 80,
    Q = 81,
    R = 82,
    S = 83,
    T = 84,
    U = 85,
    V = 86,
    W = 87,
    X = 88,
    Y = 89,
    Z = 90,
    NUMPAD0 = 96,
    NUMPAD1 = 97,
    NUMPAD2 = 98,
    NUMPAD3 = 99,
    NUMPAD4 = 100,
    NUMPAD5 = 101,
    NUMPAD6 = 102,
    NUMPAD7 = 103,
    NUMPAD8 = 104,
    NUMPAD9 = 105,
    F1 = 112,
    F2 = 113,
    F3 = 114,
    F4 = 115,
    F5 = 116,
    F6 = 117,
    F7 = 118,
    F8 = 119,
    F9 = 120,
    F10 = 121,
    F11 = 122,
    F12 = 123,
    PAGE_UP = 33,
    PAGE_DOWN = 34,
    END = 35,
    HOME = 36,
    DELETE = 127,
    INSERT = 155,
    BACK_SPACE = 8,
    ENTER = 10,
    ESCAPE = 27,
    SPACE = 32,
    CAPS_LOCK = 20,
    NUM_LOCK = 144,
    SCROLL_LOCK = 145,
    AMPERSAND = 150,
    ASTERISK = 151,
    BACK_QUOTE = 192,
    BACK_SLASH = 92,
    BRACELEFT = 161,
    BRACERIGHT = 162,
    CLEAR = 12,
    CLOSE_BRACKET = 93,
    COLON = 513,
    COMMA = 44,
    CONVERT = 28,
    DECIMAL = 110,
    DIVIDE = 111,
    DOLLAR = 515,
    EQUALS = 61,
    SLASH = 47,
    META = 157,
    MINUS = 45,
    MULTIPLY = 106,
    NUMBER_SIGN = 520,
    OPEN_BRACKET = 91,  
    PERIOD = 46,
    PLUS = 521, 
    PRINTSCREEN = 154,
    QUOTE = 222,
    QUOTEDBL = 152,
    RIGHT_PARENTHESIS = 522,    
    SEMICOLON = 59,
    SEPARATOR = 108,
    SUBTRACT = 109;
}


// ===================================
// DEFAULT KIDS
// ===================================


/**
* Simple class for a rectangle with words in it
*/
class TextLabel implements Kid {
    XYWH body; 
    String text, id;
    Integer textColor, bgdColor, strokeColor; //nullable 
    final int PADDING = 4;

    //TextLabel(String labelText, float x, float y) { this(labelText, x, y, new XYWH()); }
    TextLabel(String labelText, float x, float y, XYWH parent) { this(labelText, x, y, parent, null, null, null); }
    TextLabel(String labelText, float x, float y, XYWH parent, Integer fgd) { this(labelText, x, y, parent, fgd, null, null); }
    TextLabel(String labelText, float x, float y, XYWH parent, Integer fgd, Integer bgd, Integer border) { 
        body = new XYWH(x, y, labelText.length() * 7 + PADDING * 2, 18, parent); //7 here is an estimate of how many pixels wide one character is
        text = labelText;
        textColor = fgd;
        bgdColor = bgd;
        strokeColor = border;
        id = "TextLabel"; //can update if you want I guess. Probably easier to keep a reference to the object itself in your class rather than parse this id
    }

    void draw(PGraphics canvas) {
        if (bgdColor != null || strokeColor != null) {
            if (bgdColor != null) canvas.fill(bgdColor);
            else canvas.noFill();
            if (strokeColor != null) canvas.stroke(strokeColor);
            else canvas.noStroke();
            canvas.strokeWeight(1); //no effect if noStroke()
            canvas.rect(body.x, body.y, body.w, body.h);
        }
        if (textColor != null) canvas.fill(textColor);
        else canvas.fill(EdColors.UI_DARKEST);
        canvas.text(text, body.x + PADDING, body.yh() - PADDING); //text draws from the bottom left going up and right
    }

    String mouse() {
        return "";
    }

    String keyboard(KeyEvent event) {
        return "";
    }
}



/**
* A set of menu buttons that line up in a grid next to each other according to the number of columns specified. 
* The page names supplied (albumPages) become the buttons. To handle a button press you can either
* check its mouse() function to get the page name clicked, or you can override buttonClick()
* Checkboxes start as false (so togglePages should contain the true/enabled/checked album pages, if any)
*/
class GridButtons implements Kid {
    XYWH body;
    Album buttonAlbum;
    String[] buttonPages, altPages, origPages;
    int columns;

    GridButtons(XYWH parent, float anchorX, float anchorY, int numCols, Album album, String[] albumPages) { this(parent, anchorX, anchorY, numCols, album, albumPages, albumPages); }
    GridButtons(XYWH parent, float anchorX, float anchorY, int numCols, Album album, String[] albumPages, String[] togglePages) {
        if (togglePages.length != albumPages.length) throw new IllegalArgumentException("Array lengths of page lists do not match");
        columns = min(max(1, numCols), albumPages.length); //quick error checking
        body = new XYWH(anchorX, anchorY, columns * album.w, ceil(albumPages.length / (float)columns) * album.h, parent);
        buttonAlbum = album;
        buttonPages = albumPages;
        origPages = albumPages.clone();
        altPages = togglePages; 
    }

    /** You can override this or just pay attention to mouse() **/
    void buttonClick(String clicked) { }
    /************************************************************/

    void draw(PGraphics canvas) {
        for (int i = 0; i < buttonPages.length; i++) {
            canvas.image(buttonAlbum.page(buttonPages[i]), 
                body.x + (i % columns) * buttonAlbum.w, 
                body.y + (i / columns) * buttonAlbum.h);
        }
    }

    String mouse() {
        if (!body.isMouseOver()) return "";
        int index = indexAtMouse();
        if (index < buttonPages.length) {
            if (edwin.mouseBtnReleased == LEFT) buttonClick(buttonPages[index]);
            return buttonPages[index]; //respond with the page name of the button the mouse is over
        }
        return "";
    }

    String keyboard(KeyEvent event) {
        return "";
    }

    void toggleImage() { toggleImage(0); }
    void toggleImage(int index) { setCheck(index, (buttonPages[index] == origPages[index])); }
    void setCheck(boolean check) { setCheck(0, check); }
    void setCheck(int index, boolean check) {
        if (check) buttonPages[index] = altPages[index];
        else buttonPages[index] = origPages[index];
    }

    void uncheckAll() {
        for (int i = 0; i < buttonPages.length; i++) {
            setCheck(i, false);
        }
    }

    int indexAtMouse() { return indexAtPosition(mouseX, mouseY); }
    int indexAtPosition(float _x, float _y) {
        //if (!body.isMouseOver()) return -1;
        float relativeX = _x - body.screenX();
        float relativeY = _y - body.screenY();
        int index = (int)(floor(relativeY / buttonAlbum.h) * columns + (relativeX / buttonAlbum.w));
        return index;
    }
}



/**
* Contains basics for a window that floats in the sketch and can be dragged around. 
* Intended to be extended. Requires a little wiring up in the child class like so:
*
*   class MyWindow extends DraggableWindow {
*       MyWindow() {
*           super(myX, myY, myW, myH, "My Window Title");
*           ...
*       }
*
*       void draw(PGraphics canvas) {
*           if (!isVisible) return;
*           super.draw(canvas);
*           canvas.pushMatrix();
*           canvas.translate(body.x, body.y);
*           ...
*           canvas.popMatrix();
*       }
*
*       String mouse() {
*           if (!isVisible) return "";
*           if (super.mouse() != "") return "dragging";
*           ...
*       }
*   }
*
*/
class DraggableWindow implements Kid {
    XYWH body;
    XYWH dragBar;
    XY dragOffset;
    String windowTitle;
    boolean isVisible, beingDragged;
    public static final int UI_PADDING = 5, MINIMUM_SIZE = 40;

    DraggableWindow() { this(round(random(width - 100)), round(random(height - 100))); }
    DraggableWindow(float _x, float _y) { this(_x, _y, 18, 40, "DraggableWindow"); }
    DraggableWindow(float _x, float _y, float _w, float _h, String windowTitle) {
        body = new XYWH(_x, _y, _w, _h);
        dragBar = new XYWH(UI_PADDING, UI_PADDING, 20, 20, body);
        dragOffset = new XY();
        isVisible = true;
        beingDragged = false;
        this.windowTitle = windowTitle;
        setSize(_w, _h);
    }

    void toggleVisibility() {
        isVisible = !isVisible;
    }

    void setSize(float w, float h) {
        body.setSize(w, h);
        dragBar.w = body.w - UI_PADDING * 2;
    }

    void draw(PGraphics canvas) {
        if (!isVisible) return;
        canvas.strokeWeight(2);
        canvas.stroke(EdColors.UI_DARKEST);
        canvas.fill(EdColors.UI_NORMAL);
        canvas.rect(body.x, body.y, body.w, body.h);
        if (!dragBar.isMouseOver()) canvas.noStroke();
        canvas.fill(EdColors.UI_DARK);
        canvas.rect(dragBar.screenX(), dragBar.screenY(), dragBar.w, dragBar.h);
        canvas.fill(EdColors.UI_LIGHT);
        canvas.text(windowTitle, dragBar.screenX() + UI_PADDING, dragBar.screenYH() - UI_PADDING); //text draws from the bottom left going up (rather than images/rects that go top left down)
    }

    String mouse() {
        if (!isVisible) return "";
        if (edwin.mouseBtnBeginHold == LEFT && dragBar.isMouseOver()) {
            beingDragged = true;
            dragOffset.set(mouseX - body.x, mouseY - body.y);
            return "begin drag";
        }
        if (beingDragged) {
            body.set(mouseX - dragOffset.x, mouseY - dragOffset.y);
            body.y = max(0, min(body.y, height - MINIMUM_SIZE));
            body.x = max(MINIMUM_SIZE - body.w, min(body.x, width - MINIMUM_SIZE));
            if (edwin.mouseBtnReleased == LEFT) {
                beingDragged = false;
                return "end drag";
            }
            return "dragging";
        }
        return "";
    }

    String keyboard(KeyEvent event) {
        return "";
    }
}



/**
* A floating draggable window you put GridButtons + labels on.
* Use addItem() to insert a menu line and make sure to 
* override the Command object's execute() to handle the menu click
*/
class GadgetPanel extends DraggableWindow {
    ArrayList<PanelItem> panelItems; //each of these has a GridButtons
    Album buttonAlbum;
    final int TEXT_OFFSET = 9;
    //constants for the Album
    public static final String BUTTON_FILENAME = "basicButtons.alb",
    BLANK = "blank",
    OPEN = "open", 
    SAVE = "save",
    ARROW_N = "arrowN",
    ARROW_S = "arrowS",
    ARROW_E = "arrowE",
    ARROW_W = "arrowW",
    PLUS = "plus",
    MINUS = "minus",
    NO = "no",
    OK = "ok",
    BIGX = "bigx",
    COLOR_WHEEL = "colorWheel",
    START_LIGHT = "start light",
    STOP_LIGHT = "stop light",
    //may remove these
    OVER_UNDER = "over under",
    OVER_UNDER_DOWN = "over under down",
    SIDE_SIDE = "side side",
    SIDE_SIDE_DOWN = "side side down";

    GadgetPanel() { this(""); }
    GadgetPanel(String title) { this(50, 50, title); }
    GadgetPanel(XY anchor) { this(anchor.x, anchor.y, ""); }
    GadgetPanel(XY anchor, String title) { this(anchor.x, anchor.y, title); }
    GadgetPanel(float _x, float _y, String title) { this(_x, _y, title, new Album(BUTTON_FILENAME)); }
    GadgetPanel(float _x, float _y, String title, Album album) {
        super(_x, _y);
        buttonAlbum = album;
        windowTitle = title; //displayed in dragBar
        panelItems = new ArrayList<PanelItem>();
        body.h += UI_PADDING;
    }

    void addItem(String label, String page, Command cmd) { addItem(label, new String[] { page }, cmd); }
    void addItem(String label, String page, String alt, Command cmd) { addItem(label, new String[] { page }, new String[] { alt }, cmd); }
    void addItem(String label, String[] pages, Command cmd) { addItem(label, pages, pages, cmd); }
    void addItem(String label, String[] pages, String[] alts, Command cmd) { addItem(label, new GridButtons(body, 0, 0, 5, buttonAlbum, pages, alts), cmd); }
    void addItem(String label, GridButtons buttons, Command cmd) {
        buttons.body.set(UI_PADDING, body.h - UI_PADDING); //reset position of GridButtons
        panelItems.add(new PanelItem(label, buttons, cmd));
        float itemWidth = buttons.body.w + label.length() * 7 + UI_PADDING * 2; //7 here is an estimate of how many pixels wide one character is
        if (itemWidth > body.w) {
            body.w = itemWidth;
            dragBar.w = body.w - UI_PADDING * 2;
        }
        body.h += buttons.body.h;
    }

    /**
    * Mainly for toggling buttons to their alt state
    */
    GridButtons getButtons(String label) {
        for (PanelItem item : panelItems) {
            if (item.label.equals(label)) {
                return item.buttons;
            }
        }
        println("Uh oh, no GadgetPanel.PanelItem found with the label " + label);
        return null;
    }

    /**
    * Can be called at will from any class that has a GadgetPanel of their own.
    * This lets you execute the code in the Command object with your own argument
    */
    void itemExecute(String label, String arg) {
        for (PanelItem item : panelItems) {
            if (item.label.equals(label)) {
                item.command.execute(arg);
                return;
            }
        }
        println("Uh oh, no GadgetPanel.PanelItem found with the label " + label);
    }

    void draw(PGraphics canvas) {
        if (!isVisible) return;
        super.draw(canvas);
        canvas.pushMatrix();
        canvas.translate(body.x, body.y);
        canvas.fill(EdColors.UI_DARKEST);
        for (PanelItem item : panelItems) {
            item.buttons.draw(canvas);
            canvas.text(item.label, item.labelPos.x, item.labelPos.y);
        }
        canvas.popMatrix();
    }

    String mouse() {
        if (!isVisible) return "";
        if (super.mouse() != "") return "dragging";
        if (edwin.mouseBtnReleased == LEFT && body.isMouseOver()) {
            for (PanelItem item : panelItems) {
                String buttonPage = item.buttons.mouse();
                if (buttonPage != "") {
                    item.command.execute(buttonPage);
                    return buttonPage;
                }
            }
        }
        return "";
    }

    private class PanelItem {
        Command command;
        GridButtons buttons;
        XY labelPos;
        String label;

        PanelItem(String text, GridButtons gridButtons, Command cmd) {
            label = text;
            buttons = gridButtons;
            command = cmd;
            labelPos = new XY(buttons.body.xw() + UI_PADDING, buttons.body.yh() - TEXT_OFFSET);
        }
    }
}



/**
* Restricting to a color palette helps me design stuff
* so I made this color picker. See AlbumEditor for potential usage
*/
public class PalettePicker extends DraggableWindow {
    ArrayList<Integer> colors;
    GridButtons buttons;
    BoundedInt selectedColor;
    XY squareCoord;
    String openFilepath;
    final int SIDE = 24, COLUMN_COUNT = 5;

    PalettePicker() { this(EdColors.dxPalette()); }
    PalettePicker(int[] paletteColors) { this(paletteColors, "Color Palette", true); }
    PalettePicker(int[] paletteColors, String title) { this(paletteColors, title, true); }
    PalettePicker(int[] paletteColors, String title, boolean visible) {
        super();
        colors = new ArrayList<Integer>();
        selectedColor = new BoundedInt(0);
        body.setSize(SIDE * COLUMN_COUNT + UI_PADDING * 2, SIDE * 2 + dragBar.h + UI_PADDING * 4);
        dragBar.setSize(body.w - UI_PADDING * 2, dragBar.h);
        buttons = new GridButtons(body, UI_PADDING + SIDE, UI_PADDING * 2 + dragBar.h, 5, 
            new Album(GadgetPanel.BUTTON_FILENAME), new String[] { GadgetPanel.COLOR_WHEEL, GadgetPanel.PLUS, GadgetPanel.ARROW_S, GadgetPanel.OPEN });
        squareCoord = new XY();
        isVisible = visible;
        windowTitle = title;
        openFilepath = null;
        resetColors(paletteColors);
    }

    int selectedColor() {
        return colors.get(selectedColor.value);
    }

    /** You can override these *************/
    void colorSelected(int paletteIndex) { }
    void colorEdited(int paletteIndex) { }
    /***************************************/

    void resetColors(JSONObject json) { resetColors(json.getJSONArray(EdFiles.COLOR_PALETTE).getIntArray()); }
    void resetColors(int[] paletteColors) {
        colors.clear();
        selectedColor.reset(0, -1);
        for (int i = 0; i < paletteColors.length; i++) {
            colors.add(paletteColors[i]);
            selectedColor.incrementMax();
            colorEdited(i);
        }
        body.h = UI_PADDING * 4 + dragBar.h + buttons.body.h + SIDE * ceil(colors.size() / (float)COLUMN_COUNT);
    }

    void draw(PGraphics canvas) {
        if (!isVisible) return;
        super.draw(canvas);
        canvas.pushMatrix();
        canvas.translate(body.x, body.y);
        canvas.noStroke();
        //menu
        buttons.draw(canvas);
        //square intended to show contrast when your palette color is transparent
        canvas.fill(0);
        canvas.rect(buttons.body.x - SIDE, buttons.body.y, SIDE, SIDE);
        canvas.fill(255);
        canvas.triangle(buttons.body.x - SIDE, buttons.body.y + SIDE, buttons.body.x, buttons.body.y + SIDE, buttons.body.x, buttons.body.y);
        //currently selected color
        canvas.fill(colors.get(selectedColor.value));
        canvas.rect(buttons.body.x - SIDE, buttons.body.y, SIDE, SIDE);
        //draw palette squares
        for (int i = 0; i < colors.size(); i++) {
            squareCoord.y = floor(i / (float)COLUMN_COUNT);
            squareCoord.x = i - (squareCoord.y * COLUMN_COUNT);
            canvas.fill(colors.get(i));
            canvas.rect(
                round(UI_PADDING + squareCoord.x * SIDE), 
                round(UI_PADDING * 3 + SIDE + dragBar.h + squareCoord.y * SIDE), 
                SIDE, 
                SIDE
            );
        }
        canvas.popMatrix();
    }

    String mouse() {
        if (super.mouse() != "") return "dragging";
        if (!isVisible || edwin.mouseBtnReleased != LEFT || !body.isMouseOver()) return "";

        String clicked = buttons.mouse();
        if (clicked == GadgetPanel.COLOR_WHEEL) {
            Color picked = JColorChooser.showDialog(null, "Edit color", new Color(colors.get(selectedColor.value)));
            if (picked == null) return "";
            colors.set(selectedColor.value, picked.getRGB());
            colorEdited(selectedColor.value);
            return "color edited";
        }
        else if (clicked == GadgetPanel.PLUS) {
            Color picked = JColorChooser.showDialog(null, "Add new color", Color.BLACK);
            if (picked == null) return "";
            colors.add(picked.getRGB());
            selectedColor.incrementMax();
            selectedColor.maximize();
            if (colors.size() % COLUMN_COUNT == 1) {
                body.h += SIDE;
            }
            return "new color";
        }
        else if (clicked == GadgetPanel.OPEN) {
            selectInput("Open color palette from file (.alb, .lzr, .pw)", "openFile", null, this);
            return "open";
        }
        else if (clicked == GadgetPanel.ARROW_S) {
            String newPalette = JOptionPane.showInputDialog("Enter hex values of new color palette", "");
            if (newPalette == null) return "";
            try {
                String[] hexValues = newPalette.replaceAll("\\r", " ").replaceAll("\\n", " ").replaceAll("\\t", " ").replaceAll(" ", ",").split(",");
                int[] newColors = new int[hexValues.length];
                int index = 0;
                for (int i = 0; i < hexValues.length; i++) {
                    if (hexValues[i].replace("#", "").trim().length() != 6) continue;
                    String col = hexValues[i].replace("#", "").trim();
                    newColors[index++] = Color.decode("#" + col).getRGB();
                }
                if (index > 0) resetColors(Arrays.copyOf(newColors, index));
            }
            catch (Exception e) {
                JOptionPane.showMessageDialog(null, "Palette could not be read", "Hey", JOptionPane.ERROR_MESSAGE);
            }
            return "new palette from hex";
        }

        //translate mouse position into palette index
        int yIndex = (int)((mouseY - (buttons.body.screenYH() + UI_PADDING)) / SIDE);
        int xIndex = (int)((mouseX - (body.x + UI_PADDING)) / SIDE);
        int index = yIndex * COLUMN_COUNT + xIndex;
        if (index >= 0 && index < colors.size()) {
            selectedColor.set(index);
            colorSelected(selectedColor.value);
            return "color selected";
        }
        return "";
    }

    void openFile(File file) {
        if (file == null) return; //user hit cancel or closed
        openFilepath = file.getAbsolutePath();
        try {
            JSONObject json = loadJSONObject(openFilepath);
            resetColors(json);
        }
        catch (Exception e) {
            JOptionPane.showMessageDialog(null, "Palette could not be read", "Hey", JOptionPane.ERROR_MESSAGE);
        }
        finally {
            openFilepath = null;
        }
    }

    String keyboard(KeyEvent event) {
        return "";
    }

    String asJsonKV() {
        return jsonKV(EdFiles.COLOR_PALETTE, colors.toString());
    }
}



/** 
* Place and scale a reference image for making stuff with other stuff.
* Use the middle mouse button to drag it around, or arrows keys for 1 pixel movement.
* Was originally created for my LightLattice
* Somewhat obsolete now...
*/
public class ReferenceImagePositioner implements Kid {
    PImage refImage;
    File imageFile;
    XYWH body;
    BoundedInt scale;
    GadgetPanel gPanel;
    int origW, origH;
    boolean imageVisible;
    final String SCALE = "scale",
    RELOAD = "reload",
    IS_VISIBLE = "visible";

    ReferenceImagePositioner() { this(""); }
    ReferenceImagePositioner(String imageFilename) {
        body = new XYWH();
        scale = new BoundedInt(10, 500, 100, 10);
        refImage = null;
        imageFile = null;
        imageVisible = false;
        gPanel = new GadgetPanel(50, 50, "(I) Reference Img");

        gPanel.addItem("open image", GadgetPanel.OPEN, new Command() {
            void execute(String arg) {
                selectInput("Open reference image (.jpg or .png)", "openFile", null, ReferenceImagePositioner.this);
            }
        });

        gPanel.addItem(RELOAD, GadgetPanel.OK, new Command() {
            void execute(String arg) {
                openFile(imageFile);
            }
        });

        gPanel.addItem(SCALE, new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS }, new Command() {
            void execute(String arg) {
                if (refImage == null) {
                    gPanel.windowTitle = "no image open";
                    return;
                }
                else if (arg == GadgetPanel.PLUS) {
                    scale.increment();
                }
                else if (arg == GadgetPanel.MINUS) {
                    scale.decrement();
                }
                gPanel.windowTitle = SCALE + ":" + scale.value + "%";
                refImage.resize((int)(origW * (scale.value / 100.0)), (int)(origH * (scale.value / 100.0)));
            }
        });

        gPanel.addItem(IS_VISIBLE, GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
            void execute(String arg) {
                imageVisible = !imageVisible;
                gPanel.windowTitle = IS_VISIBLE + ":" + imageVisible;
                gPanel.getButtons(IS_VISIBLE).toggleImage();
            }
        });
        
        if (imageFilename != "") {
            openFile(imageFilename);
        }
    }

    void draw(PGraphics canvas) {
        if (imageVisible && refImage != null) canvas.image(refImage, body.x, body.y);
        gPanel.draw(canvas);
    }

    String mouse() {
        if (!gPanel.isVisible) return "";
        if (gPanel.mouse() != "") {
            return "gadgetPanel";
        }
        // else if (edwin.mouseBtnHeld == CENTER) {
        //  body.set(mouseX, mouseY);
        //  setGPLabel();
        // }
        return "";
    }

    void setGPLabel() { gPanel.windowTitle = "x:" + (int)body.x +  "|y:" + (int)body.y; }

    String keyboard(KeyEvent event) {
        if (event.getAction() != KeyEvent.PRESS) {
            return "";
        }
        int kc = event.getKeyCode();
        if (kc == Keycodes.I) {
            gPanel.toggleVisibility();
        }
        else if (!gPanel.isVisible) {
            return "";
        }
        // else if (event.isShiftDown()) {
        //  if (kc == Keycodes.LEFT) {
        //      body.x--;
        //      setGPLabel();
        //  }
        //  else if (kc == Keycodes.RIGHT) {
        //      body.x++;
        //      setGPLabel();
        //  }
        //  else if (kc == Keycodes.UP) {
        //      body.y--;
        //      setGPLabel();
        //  }
        //  else if (kc == Keycodes.DOWN) {
        //      body.y++;
        //      setGPLabel();
        //  }
        // }
        return "";
    }

    void openFile(String imageFilename) { openFile(new File("C:\\code\\Processing\\EdwinGerm\\data\\", imageFilename));  } //TODO relative path
    void openFile(File file) {
        if (file == null) return; //user hit cancel or closed
        imageFile = file;
        refImage = loadImage(imageFile.getAbsolutePath());
        origW = refImage.width;
        origH = refImage.height;
        body.setSize(origW, origH);
        scale.set(100);
        imageVisible = true;
        gPanel.windowTitle = imageFile.getName();
        gPanel.getButtons(IS_VISIBLE).setCheck(true);
    }
}


// JOptionPane.showMessageDialog(null, "omg lookout", "Hey", JOptionPane.INFORMATION_MESSAGE);
// int selected = JOptionPane.showConfirmDialog(null, "Really wanna delete this?", "Delete?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
// if (selected == JOptionPane.YES_OPTION) { ... }
