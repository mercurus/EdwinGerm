/** 
* This lets you place multiple Laserbolts on the screen and 
* lets you play with their parameters live. Eventually
* it will also be able to save arrangements you've made 
*/
public class LaserboltPositioner implements Kid {
    ArrayList<Laserbolt> lasers;
    Laserbolt selectedLaser;
    GadgetPanel gPanel;
    PalettePicker palette;
    String openFilepath;
    int anchorDiameter;
    //keys for the JSON file
    final String LASERBOLT_LIST = "laserbolt list",
    COLOR_MAIN = "color 0",
    COLOR_HILIGHT = "color 1",
    ORIGIN_X = "origin x",
    ORIGIN_Y = "origin y",
    DESTINATION_X = "destination x",
    DESTINATION_Y = "destination y",
    //labels for the GadgetPanel 
    IS_VISIBLE = "is visible",
    PERFECT_ZZ = "perfect zig zag",
    JOLTS = "jolts",
    TIMER_LIMIT = "timer limit",
    SEG_LENGTH = "segment length",
    PLACE_MIN = "placement min",
    PLACE_MAX = "placement max",
    PLACE_ANG_MIN = "place angle min",
    PLACE_ANG_MAX = "place angle max",
    THICK_MIN = "thickness min",
    THICK_MAX = "thickness max",
    THICK_INC = "thickness inc",
    THICK_MUL = "thickness mul";

    LaserboltPositioner() { this(null, true); }
    LaserboltPositioner(String filename) { this(filename, false); }
    LaserboltPositioner(String filename, boolean gadgetPanelVisible) { 
        if (filename != null) filename = EdFiles.DATA_FOLDER + filename;
        openFilepath = filename;
        anchorDiameter = 70;
        lasers = new ArrayList<Laserbolt>();
        addLaser();
        palette = new PalettePicker(new int[] { #69D1C5, #3B898C }, "Laserbolt Colors", false) {
            void colorSelected(int paletteIndex) { }
            void colorEdited(int paletteIndex) { 
                for (Laserbolt laser : lasers) {
                    if (laser.palette0 == paletteIndex) laser.color0 = colors.get(paletteIndex);
                    if (laser.palette1 == paletteIndex) laser.color1 = colors.get(paletteIndex);
                    laser.jolt();
                }
            }
        };

        //now we define the GadgetPanel menu which will have a lot of buttons...
        gPanel = new GadgetPanel(500, 100, "(L) Laserbolts!");
        gPanel.isVisible = gadgetPanelVisible;
        String[] minusPlus = new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS };
        
        gPanel.addItem("open|save", new String[] { GadgetPanel.OPEN, GadgetPanel.SAVE }, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.OPEN) {
                    selectInput("Open Lasers...", "openFile", null, LaserboltPositioner.this);
                }
                else { // GadgetPanel.SAVE
                    selectOutput("Save Lasers...", "saveFile", null, LaserboltPositioner.this);
                }
            }
        });

        gPanel.addItem("colors", new String[] { GadgetPanel.COLOR_WHEEL, GadgetPanel.ARROW_N, GadgetPanel.ARROW_E }, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.COLOR_WHEEL) {
                    palette.toggleVisibility();
                    palette.body.set(mouseX, mouseY);
                }
                else if (arg == GadgetPanel.ARROW_N) {
                    selectedLaser.color0 = palette.selectedColor();
                    selectedLaser.palette0 = palette.selectedColor.value;
                }
                else { // if (arg == GadgetPanel.ARROW_E) {
                    selectedLaser.color1 = palette.selectedColor();
                    selectedLaser.palette1 = palette.selectedColor.value;
                }
                selectedLaser.jolt();
            }
        });

        gPanel.addItem("selected", new String[] { GadgetPanel.ARROW_W, GadgetPanel.ARROW_E }, new Command() {
            void execute(String arg) {
                int selIndex = lasers.indexOf(selectedLaser);
                if (arg == GadgetPanel.ARROW_W) {
                    if (selIndex > 0) {
                        selIndex--;
                        selectedLaser = lasers.get(selIndex);
                    }
                }
                else { //GadgetPanel.ARROW_E
                    if (selIndex < lasers.size() - 1) {
                        selIndex++;
                        selectedLaser = lasers.get(selIndex);
                    }
                }
                gPanel.windowTitle = "selected index:" + selIndex;
                gPanel.getButtons(PERFECT_ZZ).setCheck(selectedLaser.perfectZigZag); //set checkboxes of newly selected laser
                gPanel.getButtons(JOLTS).setCheck(selectedLaser.jolts); //it's a little awkward right now
                gPanel.getButtons(IS_VISIBLE).setCheck(selectedLaser.isVisible); 
            }
        });

        gPanel.addItem("new laser", GadgetPanel.OK, new Command() {
            void execute(String arg) {
                addLaser();
                gPanel.windowTitle = "new laser created"; 
                gPanel.getButtons(PERFECT_ZZ).setCheck(true); //set checkboxes to true for the new laser
                gPanel.getButtons(JOLTS).setCheck(true); 
                gPanel.getButtons(IS_VISIBLE).setCheck(true); 
            }
        });

        gPanel.addItem("clone laser", GadgetPanel.OK, new Command() {
            void execute(String arg) {
                cloneLaser();
                gPanel.windowTitle = "laser cloned"; 
            }
        });

        gPanel.addItem("delete laser", GadgetPanel.NO, new Command() {
            void execute(String arg) {
                gPanel.windowTitle = "not implemented yet";
            }
        });

        gPanel.addItem(PLACE_MIN, minusPlus, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.MINUS) {
                    selectedLaser.placeRadius.decrementMin();
                }
                else { //GadgetPanel.PLUS
                    selectedLaser.placeRadius.incrementMin();
                }
                gPanel.windowTitle = PLACE_MIN + ":" + selectedLaser.placeRadius.minimum;
                selectedLaser.jolt();
            }
        });

        gPanel.addItem(PLACE_MAX, minusPlus, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.MINUS) {
                    selectedLaser.placeRadius.decrementMax();
                }
                else { //GadgetPanel.PLUS
                    selectedLaser.placeRadius.incrementMax();
                }
                gPanel.windowTitle = PLACE_MAX + ":" + selectedLaser.placeRadius.maximum;
                selectedLaser.jolt();
            }
        });

        gPanel.addItem(PLACE_ANG_MIN, minusPlus, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.MINUS) {
                    selectedLaser.placeAngle.decrementMin();
                }
                else { //GadgetPanel.PLUS
                    selectedLaser.placeAngle.incrementMin();
                }
                gPanel.windowTitle = PLACE_ANG_MIN + ":" + String.format("%.4f", selectedLaser.placeAngle.minimum);
                selectedLaser.jolt();
            }
        });

        gPanel.addItem(PLACE_ANG_MAX, minusPlus, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.MINUS) {
                    selectedLaser.placeAngle.decrementMax();
                }
                else { //GadgetPanel.PLUS
                    selectedLaser.placeAngle.incrementMax();
                }
                gPanel.windowTitle = PLACE_ANG_MAX + ":" + String.format("%.4f", selectedLaser.placeAngle.maximum);
                selectedLaser.jolt();
            }
        });

        gPanel.addItem(PERFECT_ZZ, GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
            void execute(String arg) {
                selectedLaser.perfectZigZag = !selectedLaser.perfectZigZag; //toggle
                gPanel.windowTitle = PERFECT_ZZ + ":" + selectedLaser.perfectZigZag;
                gPanel.getButtons(PERFECT_ZZ).toggleImage();
                selectedLaser.jolt();
            }
        });
        gPanel.getButtons(PERFECT_ZZ).setCheck(true); //all checkboxes start as false...

        gPanel.addItem(JOLTS, GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
            void execute(String arg) {
                selectedLaser.jolts = !selectedLaser.jolts; //toggle
                gPanel.windowTitle = JOLTS + ":" + selectedLaser.jolts;
                gPanel.getButtons(JOLTS).toggleImage();
                selectedLaser.jolt();
            }
        });
        gPanel.getButtons(JOLTS).setCheck(true);

        gPanel.addItem(TIMER_LIMIT, minusPlus, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.MINUS) {
                    selectedLaser.timer.decrementMax(5);
                }
                else { //GadgetPanel.PLUS
                    selectedLaser.timer.incrementMax(5);
                }
                gPanel.windowTitle = TIMER_LIMIT + ":" + selectedLaser.timer.maximum;
                selectedLaser.jolt();
            }
        });

        gPanel.addItem(SEG_LENGTH, minusPlus, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.MINUS) {
                    selectedLaser.segmentLength.decrement();
                }
                else { //GadgetPanel.PLUS
                    selectedLaser.segmentLength.increment();
                }
                gPanel.windowTitle = SEG_LENGTH + ":" + selectedLaser.segmentLength.value;
                selectedLaser.jolt();
            }
        });

        gPanel.addItem(THICK_MIN, minusPlus, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.MINUS) {
                    selectedLaser.thickness.decrementMin();
                }
                else { //GadgetPanel.PLUS
                    selectedLaser.thickness.incrementMin();
                }
                gPanel.windowTitle = THICK_MIN + ":" + selectedLaser.thickness.minimum;
                selectedLaser.jolt();
            }
        });

        gPanel.addItem(THICK_MAX, minusPlus, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.MINUS) {
                    selectedLaser.thickness.decrementMax();
                }
                else { //GadgetPanel.PLUS
                    selectedLaser.thickness.incrementMax();
                }
                gPanel.windowTitle = THICK_MAX + ":" + selectedLaser.thickness.maximum;
                selectedLaser.jolt();
            }
        });

        gPanel.addItem(THICK_INC, minusPlus, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.MINUS) {
                    selectedLaser.powInc.decrement();
                }
                else { //GadgetPanel.PLUS
                    selectedLaser.powInc.increment();
                }
                gPanel.windowTitle = THICK_INC + ":" + selectedLaser.powInc.value;
                selectedLaser.jolt();
            }
        });

        gPanel.addItem(THICK_MUL, minusPlus, new Command() {
            void execute(String arg) {
                if (arg == GadgetPanel.MINUS) {
                    selectedLaser.powIncInc.decrement();
                }
                else { //GadgetPanel.PLUS
                    selectedLaser.powIncInc.increment();
                }
                gPanel.windowTitle = THICK_MUL + ":" + String.format("%.2f", selectedLaser.powIncInc.value);
                selectedLaser.jolt();
            }
        });

        gPanel.addItem(IS_VISIBLE, GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
            void execute(String arg) {
                selectedLaser.isVisible = !selectedLaser.isVisible; //toggle
                gPanel.windowTitle = IS_VISIBLE + ":" + selectedLaser.isVisible;
                gPanel.getButtons(IS_VISIBLE).toggleImage();
                selectedLaser.jolt();
            }
        });
        gPanel.getButtons(IS_VISIBLE).setCheck(true);
    }

    void addLaser() {
        int margin = 80;
        selectedLaser = new Laserbolt(margin, margin, margin, height - margin);
        lasers.add(selectedLaser);
    }

    void cloneLaser() {
        selectedLaser = selectedLaser.clone();
        lasers.add(selectedLaser);
    }

    void draw(PGraphics canvas) {
        if (openFilepath != null) digestFile();
        //edit anchors
        if (gPanel.isVisible) {
            canvas.noStroke();
            canvas.fill(EdColors.DX_RED, 100);
            canvas.ellipse(selectedLaser.anchor0.x, selectedLaser.anchor0.y, anchorDiameter, anchorDiameter);
            canvas.ellipse(selectedLaser.anchor1.x, selectedLaser.anchor1.y, anchorDiameter, anchorDiameter);
            gPanel.draw(canvas);
            palette.draw(canvas);
        }
        for (Laserbolt laser : lasers) {
            laser.draw(canvas);
        }
    }

    String mouse() {
        if (!gPanel.isVisible) return "";

        if (palette.mouse() != "" || gPanel.mouse() != "") {
            //selectedLaser.jolt();
            return HELLO;
        }
        else if (edwin.mouseBtnHeld == LEFT) {
            if (selectedLaser.anchor0.distance(mouseX, mouseY) < anchorDiameter * 2) {
                selectedLaser.newAnchor(mouseX, mouseY);
            }
            else if (selectedLaser.anchor1.distance(mouseX, mouseY) < anchorDiameter * 2) {
                selectedLaser.newTarget(mouseX, mouseY);
            }
        }
        return "";
    }

    String keyboard(KeyEvent event) {
        if (event.getAction() != KeyEvent.RELEASE) {
            return "";
        }
        int kc = event.getKeyCode();
        if (kc == Keycodes.L) {
            gPanel.toggleVisibility();
            return HELLO;
        }
        else if (!gPanel.isVisible) {
            return "";
        }
        else if (kc == Keycodes.LEFT) {
            gPanel.itemExecute("selected", GadgetPanel.ARROW_W);
            return HELLO;
        }
        else if (kc == Keycodes.RIGHT) {
            gPanel.itemExecute("selected", GadgetPanel.ARROW_E);
            return HELLO;
        }
        else if (kc == Keycodes.ONE) {
            selectedLaser.color0 = palette.selectedColor();
            selectedLaser.palette0 = palette.selectedColor.value;
            selectedLaser.jolt();
        }
        else if (kc == Keycodes.TWO) { 
            selectedLaser.color1 = palette.selectedColor();
            selectedLaser.palette1 = palette.selectedColor.value;
            selectedLaser.jolt();
        }
        return "";
    }

    void openFile(File file) {
        if (file == null) return; //user hit cancel or closed
        openFilepath = file.getAbsolutePath(); 
        //Next time draw() is called it'll call digestAlbum() so we don't screw with variables potentially in use 
        //since we might be in the middle of drawing at this time. Then openFilepath becomes null.
    }

    /** Load file into editor variables */
    void digestFile() {
        JSONObject json = loadJSONObject(openFilepath);
        openFilepath = null;
        lasers.clear();
        palette.resetColors(json);
        JSONArray jsonLasers = json.getJSONArray(LASERBOLT_LIST);
        for (int i = 0; i < jsonLasers.size(); i++) {
            JSONObject jsonLaser = jsonLasers.getJSONObject(i);
            Laserbolt laser = new Laserbolt(
                new XY(jsonLaser.getFloat(ORIGIN_X), jsonLaser.getFloat(ORIGIN_Y)),
                new XY(jsonLaser.getFloat(DESTINATION_X), jsonLaser.getFloat(DESTINATION_Y)), 
                palette.colors.get(jsonLaser.getInt(COLOR_MAIN)), 
                palette.colors.get(jsonLaser.getInt(COLOR_HILIGHT)));
            laser.palette0 = jsonLaser.getInt(COLOR_MAIN);
            laser.palette1 = jsonLaser.getInt(COLOR_HILIGHT);
            laser.isVisible = jsonLaser.getBoolean(IS_VISIBLE);
            laser.perfectZigZag = jsonLaser.getBoolean(PERFECT_ZZ);
            laser.jolts = jsonLaser.getBoolean(JOLTS);
            laser.timer.reset(0, jsonLaser.getInt(TIMER_LIMIT));
            laser.segmentLength.set(jsonLaser.getInt(SEG_LENGTH));
            laser.placeRadius.reset(jsonLaser.getInt(PLACE_MIN), jsonLaser.getInt(PLACE_MAX));
            laser.placeAngle.reset(jsonLaser.getFloat(PLACE_ANG_MIN), jsonLaser.getFloat(PLACE_ANG_MAX));
            laser.thickness.reset(jsonLaser.getInt(THICK_MIN), jsonLaser.getInt(THICK_MAX));
            laser.powInc.set(jsonLaser.getInt(THICK_INC));
            laser.powIncInc.set(jsonLaser.getInt(THICK_MUL));
            laser.jolt();
            lasers.add(laser);
        }
        selectedLaser = lasers.get(0);
    }

    void saveFile(File file) {
        if (file == null) return; //user closed window or hit cancel
        ArrayList<String> fileLines = new ArrayList<String>();
        fileLines.add("{"); //opening bracket
        fileLines.add(palette.asJsonKV());
        fileLines.add(jsonKVNoComma(LASERBOLT_LIST, "[{"));
        for (int i = 0; i < lasers.size(); i++) {
            if (i > 0) fileLines.add("},{"); //separation between layer objects in this array
            Laserbolt laser = lasers.get(i);
            fileLines.add(TAB + jsonKV(ORIGIN_X, laser.anchor0.x));
            fileLines.add(TAB + jsonKV(ORIGIN_Y, laser.anchor0.y));
            fileLines.add(TAB + jsonKV(DESTINATION_X, laser.anchor1.x));
            fileLines.add(TAB + jsonKV(DESTINATION_Y, laser.anchor1.y));
            fileLines.add(TAB + jsonKV(COLOR_MAIN, laser.palette0));
            fileLines.add(TAB + jsonKV(COLOR_HILIGHT, laser.palette1));
            fileLines.add(TAB + jsonKV(IS_VISIBLE, laser.isVisible));
            fileLines.add(TAB + jsonKV(PERFECT_ZZ, laser.perfectZigZag));
            fileLines.add(TAB + jsonKV(JOLTS, laser.jolts));
            fileLines.add(TAB + jsonKV(TIMER_LIMIT, laser.timer.maximum));
            fileLines.add(TAB + jsonKV(SEG_LENGTH, laser.segmentLength.value));
            fileLines.add(TAB + jsonKV(PLACE_MIN, laser.placeRadius.minimum));
            fileLines.add(TAB + jsonKV(PLACE_MAX, laser.placeRadius.maximum));
            fileLines.add(TAB + jsonKV(PLACE_ANG_MIN, laser.placeAngle.minimum));
            fileLines.add(TAB + jsonKV(PLACE_ANG_MAX, laser.placeAngle.maximum));
            fileLines.add(TAB + jsonKV(THICK_MIN, laser.thickness.minimum));
            fileLines.add(TAB + jsonKV(THICK_MAX, laser.thickness.maximum));
            fileLines.add(TAB + jsonKV(THICK_INC, laser.powInc.value));
            fileLines.add(TAB + jsonKV(THICK_MUL, laser.powIncInc.value));
        }
        fileLines.add("}]"); //close list
        fileLines.add("}"); //final closing bracket
        saveStrings(file.getAbsolutePath(), fileLines.toArray(new String[0]));
    }
}



/** 
* A polygon zigzag line that jolts between two points 
*/
class Laserbolt implements Kid {
    BoundedInt timer, segmentLength, thickness, placeRadius, powInc;
    BoundedFloat placeAngle, powIncInc;
    PShape laserBeam;
    PShape[] hilights;
    //LaserPoint[] lPoints;
    XY anchor0, anchor1;
    int color0, color1, palette0, palette1;
    boolean perfectZigZag, jolts, isVisible;

    Laserbolt(XY anchor, XY dest) { this(anchor.x, anchor.y, dest.x, dest.y); }
    Laserbolt(XY anchor, XY dest, int colorMain, int colorHilight) { this(anchor.x, anchor.y, dest.x, dest.y, colorMain, colorHilight); }
    Laserbolt(float anchorX, float anchorY, float destX, float destY) { this(anchorX, anchorY, destX, destY, #69D1C5, #3B898C); }
    Laserbolt(float anchorX, float anchorY, float destX, float destY, int colorMain, int colorHilight) {
        anchor0 = new XY(anchorX, anchorY);
        anchor1 = new XY(destX, destY);
        color0 = colorMain;
        color1 = colorHilight;
        perfectZigZag = jolts = isVisible = true;
        palette0 = palette1 = -1;
        timer = new BoundedInt(80);
        segmentLength = new BoundedInt(10, 300, 80, 5);
        thickness = new BoundedInt(8, 24, 8, 2);
        placeRadius = new BoundedInt(10, 30, 10, 2);
        powInc = new BoundedInt(20);
        powIncInc = new BoundedFloat(0, 20, 0, 0.5);
        placeAngle = new BoundedFloat(-QUARTER_PI / 3, QUARTER_PI / 3, 0, QUARTER_PI / 30);
        jolt();
    }

    void draw(PGraphics canvas) {
        if (!isVisible) return;
        timer.increment();
        if (jolts && timer.atMax()) {
            timer.randomize();
            jolt(); 
        }
        canvas.shape(laserBeam);
        for (PShape hilight : hilights) {
            canvas.shape(hilight);
        }
    }

    void newAnchor(XY anchor) { newAnchor(anchor.x, anchor.y); }
    void newAnchor(float x, float y) {
        anchor0.set(x, y);
        jolt();
    }

    void jolt() { newTarget(anchor1); } //generate new form without picking different points
    void newTarget(XY dest) { newTarget(dest.x, dest.y); }
    void newTarget(float x, float y) {
        anchor1.set(x, y);
        XY inline = anchor0; //used for finding each point along the line
        int numPoints = (int)max(anchor0.distance(anchor1) / segmentLength.value, 1); //at least 1 point along line
        LaserPoint[] lPoints = new LaserPoint[numPoints];
        float segDist = anchor0.distance(anchor1) / (numPoints + 1); //makes the stretching transition a little smoother than using segmentLength.value directly
        XY pointAt = anchor0; 
        float pow = 0, powPlus = powInc.value;
        boolean isOdd;
        for (int i = 0; i < numPoints; i++) {
            inline = new XY(inline.x - segDist * anchor0.angCos(anchor1), inline.y - segDist * anchor0.angSin(anchor1));
            //inline = new XY(inline.x - segmentLength.value * anchor0.angCos(anchor1), inline.y - segmentLength.value * anchor0.angSin(anchor1));
            if (i > 0) pointAt = lPoints[i - 1].anchor; ///////////
            isOdd = perfectZigZag ? (i % 2 == 1) : (random(1) > 0.5);
            lPoints[i] = new LaserPoint(inline, pointAt, isOdd, thickness.randomize() + pow, placeRadius.randomize(), placeAngle.randomize()); //random(-QUARTER_PI, QUARTER_PI) placeAngle.randomize()
            pow += powPlus;
            powPlus += powIncInc.value;
        }

        //define beam polygon
        //go up along the left side then down the right
        laserBeam = createShape();
        laserBeam.beginShape();
        laserBeam.noStroke();
        laserBeam.fill(color0);
        laserBeam.vertex(anchor0.x, anchor0.y);
        for (int i = 0; i < lPoints.length; i++) {
            laserBeam.vertex(lPoints[i].left.x, lPoints[i].left.y);
        }
        laserBeam.vertex(anchor1.x, anchor1.y);
        for (int i = lPoints.length - 1; i >= 0; i--) {
            laserBeam.vertex(lPoints[i].right.x, lPoints[i].right.y);
        }
        laserBeam.endShape(CLOSE);
        
        //define quads that break up the solid beam
        hilights = new PShape[(int)(numPoints / 3)];
        int indx = 0;
        for (int i = 2; i < lPoints.length; i += 3) {
            PShape diamond = createShape();
            diamond.beginShape();
            diamond.noStroke();
            diamond.fill(color1);
            if (indx % 2 == 1) {
                diamond.vertex(lPoints[i].left.x, lPoints[i].left.y);
                diamond.vertex(lPoints[i - 1].left.x, lPoints[i - 1].left.y);
                diamond.vertex(lPoints[i - 2].left.x, lPoints[i - 2].left.y);
                diamond.vertex(lPoints[i - 1].right.x, lPoints[i - 1].right.y);
            }
            else {
                diamond.vertex(lPoints[i].right.x, lPoints[i].right.y);
                diamond.vertex(lPoints[i - 1].right.x, lPoints[i - 1].right.y);
                diamond.vertex(lPoints[i - 2].right.x, lPoints[i - 2].right.y);
                diamond.vertex(lPoints[i - 1].left.x, lPoints[i - 1].left.y);
            }
            diamond.endShape(CLOSE);
            hilights[indx++] = diamond;
        }
    }

    Laserbolt clone() {
        Laserbolt schwarzenegger = new Laserbolt(anchor0.clone(), anchor1.clone(), color0, color1);
        schwarzenegger.timer = timer.clone();
        schwarzenegger.segmentLength = segmentLength.clone();
        schwarzenegger.thickness = thickness.clone();
        schwarzenegger.placeRadius = placeRadius.clone();
        schwarzenegger.powInc = powInc.clone();
        schwarzenegger.powIncInc = powIncInc.clone();
        schwarzenegger.placeAngle = placeAngle.clone();
        schwarzenegger.perfectZigZag = perfectZigZag;
        schwarzenegger.jolts = jolts;
        schwarzenegger.jolt();
        return schwarzenegger;
    }

    String mouse() {
        return "";
    }

    String keyboard(KeyEvent event) {
        return "";
    }

    private class LaserPoint {
        XY absoluteAnchor, anchor, left, right;
        boolean odd;

        LaserPoint(XY anc, XY aim, boolean isOdd, float thickness, float placeRadius, float placeAngVar) {
            absoluteAnchor = anc;
            odd = isOdd; 
            float placeAngle = anchor0.angle(anchor1) + (odd ? HALF_PI : -HALF_PI) + placeAngVar;
            anchor = new XY(absoluteAnchor.x - placeRadius * cos(placeAngle), absoluteAnchor.y - placeRadius * sin(placeAngle));
            //define edge points on laser
            float aimAngle = anchor0.angle(anchor1) + HALF_PI;
            //float aimAngle = anchor.angle(aim);
            left = new XY(anchor.x - thickness * cos(aimAngle), anchor.y - thickness * sin(aimAngle));
            aimAngle -= PI;
            right = new XY(anchor.x - thickness * cos(aimAngle), anchor.y - thickness * sin(aimAngle));
        }
    }

} //end Laserbolt
