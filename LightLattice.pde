/** 
* This lets you make a wireframe figure 
* and make a lightshow on its polygons.
* File saved as .ll
* Press L to toggle UI visibility
*
* THIS IS NOT IN A FINISHED STATE
* AND NEEDS A MAJOR REWORK...
*/
public class LightLattice extends DraggableWindow {
    ArrayList<XY> allDots;
    ArrayList<LatticePolygon> allPolygons;
    ArrayList<LatticePath> allPaths;
    ArrayList<LatticePulse> allPulses;
    ArrayList<LatticeCharge> allCharges;
    ArrayList<PathPulse> activePulses, finishedPulses;
    GridButtons modeButtons, openSaveButtons;
    PalettePicker palette;
    Album basicButtonAlbum;
    PImage referenceImage, unscaledReference;
    BoundedInt defaultCharge;
    BoundedFloat figureScale;
    XY offset, figureDragOffset;
    String openFilepath;
    boolean figureBeingDragged, referenceImageVisible;
    //edit modes
    ModeFigure modeFigure;
    ModePath modePath;
    ModePulse modePulse;
    ModeMorph modeMorph;
    int editMode;
    //Album and pages for edit modes
    final String BUTTON_FILENAME = "lightLatticeButtons.alb",
    BUTTON_FIGURE = "modeFigure",
    BUTTON_FIGURE_CHECKED = "modeFigureChecked",
    BUTTON_PATH = "modePath",
    BUTTON_PATH_CHECKED = "modePathChecked",
    BUTTON_MORPH = "modeMorph",
    BUTTON_MORPH_CHECKED = "modeMorphChecked",
    WAND = "wand",
    WAND_CHECKED = "wandChecked",
    BLANK = "blank",
    BLANK_CHECKED = "blankChecked",
    //file json keys
    OFFSET_X = "offset x",
    OFFSET_Y = "offset y",
    POLYGONS = "polygons",
    PATHS = "paths",
    NAME = "name",
    FRAMES = "frames",
    VALUES = "values";
    //Constants for tracking editMode
    final int EDIT_FIGURE = 0,
    EDIT_PATH = 1,
    EDIT_PULSE = 2,
    EDIT_MORPH = 3,
    //radius...
    PATH_R = 4;

    LightLattice() { this(true); }
    LightLattice(boolean initiallyVisible) {
        super(0, 0);
        isVisible = initiallyVisible; //only applies to editing windows, not the figure
        modeButtons = new GridButtons(body, UI_PADDING, dragBar.h + UI_PADDING * 2, 1, 
            new Album(BUTTON_FILENAME), 
            new String[] { BUTTON_FIGURE, BUTTON_PATH, BLANK, BUTTON_MORPH, WAND },
            new String[] { BUTTON_FIGURE_CHECKED, BUTTON_PATH_CHECKED, BLANK_CHECKED, BUTTON_MORPH_CHECKED, WAND_CHECKED }
        );
        modeButtons.setCheck(0, true); //figure mode
        openSaveButtons = new GridButtons(body, UI_PADDING, modeButtons.body.yh(), 1, 
            new Album(AlbumEditor.BUTTON_FILENAME), 
            new String[] { AlbumEditor.SAVE, AlbumEditor.OPEN }
        );
        body.setSize(modeButtons.body.w + UI_PADDING * 2, openSaveButtons.body.yh() + UI_PADDING);
        dragBar.w = modeButtons.body.w;
        basicButtonAlbum = new Album(GadgetPanel.BUTTON_FILENAME);
        allDots = new ArrayList<XY>();
        allDots.add(new XY(200, 200));
        allPolygons = new ArrayList<LatticePolygon>();
        allPaths = new ArrayList<LatticePath>();
        allPaths.add(new LatticePath());
        allPulses = new ArrayList<LatticePulse>();
        activePulses = new ArrayList<PathPulse>();
        finishedPulses = new ArrayList<PathPulse>();
        figureScale = new BoundedFloat(0.5, 5.0, 1.0, 0.5);
        offset = new XY(0, 0);
        figureDragOffset = new XY(0, 0);
        figureBeingDragged = referenceImageVisible = false;
        referenceImage = unscaledReference = null;
        openFilepath = null;
        //default figure colors
        int BORDER_W = 1, HILIGHT_W = 2; 
        palette = new PalettePicker(new int[] { #173b47, #046894, #17a1a9, #81dbcd, #fdf9f1, #201708, #463731, #87715b }, "Lattice colors", false);
        allCharges = new ArrayList<LatticeCharge>();
        allCharges.add(new LatticeCharge(BORDER_W, HILIGHT_W, 5, 0, 0));
        allCharges.add(new LatticeCharge(BORDER_W, HILIGHT_W, 5, 1, 0));
        allCharges.add(new LatticeCharge(BORDER_W, HILIGHT_W, 5, 1, 1));
        allCharges.add(new LatticeCharge(BORDER_W, HILIGHT_W, 6, 2, 1));
        allCharges.add(new LatticeCharge(BORDER_W, HILIGHT_W, 6, 2, 2));
        allCharges.add(new LatticeCharge(BORDER_W, HILIGHT_W, 6, 3, 2));
        allCharges.add(new LatticeCharge(BORDER_W, HILIGHT_W, 6, 3, 3));
        allCharges.add(new LatticeCharge(BORDER_W, HILIGHT_W, 7, 4, 3));
        allCharges.add(new LatticeCharge(BORDER_W, HILIGHT_W, 7, 4, 4));
        defaultCharge = new BoundedInt(0, allCharges.size() - 1, 0);
        //edit modes
        modeFigure = new ModeFigure();
        modePath = new ModePath();
        modePulse = new ModePulse();
        modeMorph = new ModeMorph();
        editMode = EDIT_FIGURE;
    }

    void draw(PGraphics canvas) {
        if (openFilepath != null) digestFile();
        canvas.pushMatrix();
        canvas.translate(offset.x, offset.y);
        //reference image
        if (isVisible && referenceImageVisible && editMode == EDIT_FIGURE) {
            canvas.image(referenceImage, 0, 0);
        }
        //animations that adjust charge
        for (PathPulse pathPulse : activePulses) {
            pathPulse.progress();
        }
        //figure
        for (LatticePolygon polygon : allPolygons) {
            polygon.draw(canvas);
        }
        canvas.popMatrix();
        //remove animations
        for (PathPulse pathPulse : finishedPulses) {
            activePulses.remove(pathPulse);
        }

        //UI stuff
        if (!isVisible) return;
        //First we route by edit mode
        if (editMode == EDIT_FIGURE) modeFigure.draw(canvas);
        else if (editMode == EDIT_PATH) modePath.draw(canvas);
        else if (editMode == EDIT_PULSE) modePulse.draw(canvas);
        else if (editMode == EDIT_MORPH) modeMorph.draw(canvas);

        //DraggableWindow stuff
        super.draw(canvas);
        canvas.pushMatrix();
        canvas.translate(body.x, body.y);
        modeButtons.draw(canvas);
        openSaveButtons.draw(canvas);
        canvas.popMatrix();
        //and finally the PalettePicker
        palette.draw(canvas);
    }

    String mouse() { 
        if (!isVisible) return ""; //if UI isn't visible then we're not going to handle the event
        if (palette.mouse() != "") return "palette changes";
        if (super.mouse() != "") return "dragging";

        //offset dragging
        if (edwin.mouseBtnBeginHold == CENTER) {
            figureBeingDragged = true;
            figureDragOffset.set(mouseX - offset.x, mouseY - offset.y);
            return "begin drag";
        }
        if (figureBeingDragged) {
            offset.set(mouseX - figureDragOffset.x, mouseY - figureDragOffset.y);
            if (edwin.mouseBtnReleased == CENTER) {
                figureBeingDragged = false;
                return "end drag";
            }
            return "dragging";
        }

        //check buttons in LightLattice/DraggableWindow
        if (edwin.mouseBtnReleased == LEFT && body.isMouseOver()) {
            String clicked = modeButtons.mouse();
            if (clicked != "" && !clicked.endsWith("Checked")) {
                //to treat the modes like a radio button group we uncheck all buttons then flip back on the relevant one
                modeButtons.uncheckAll();
                switch (clicked) {
                    case BUTTON_FIGURE:
                        editMode = EDIT_FIGURE;
                        modeButtons.toggleImage(0);
                        break;
                    case BUTTON_PATH:
                        editMode = EDIT_PATH;
                        modeButtons.toggleImage(1);
                        break;
                    case BLANK:
                        editMode = EDIT_PULSE;
                        modeButtons.toggleImage(2);
                        break;
                    case BUTTON_MORPH:
                        editMode = EDIT_MORPH;
                        modeButtons.toggleImage(3);
                        break;
                    case WAND: //orchestration
                        modeButtons.toggleImage(4);
                        break;
                }
                return clicked;
            }
            clicked = openSaveButtons.mouse();
            switch (clicked) {
                case AlbumEditor.OPEN:
                    selectInput("Open Light Lattice (.ll)", "openFile", null, this);
                    break;
                case AlbumEditor.SAVE:
                    selectOutput("Save Light Lattice (.ll)", "saveFile", null, this);
                    break;
                case "":
                    return "";
            }
            return clicked;
        }

        //route mouse event
        if (editMode == EDIT_FIGURE && modeFigure.mouse() != "") return "figure editing";
        else if (editMode == EDIT_PATH && modePath.mouse() != "") return "path editing";
        else if (editMode == EDIT_PULSE && modePulse.mouse() != "") return "pulse editing";
        else if (editMode == EDIT_MORPH && modeMorph.mouse() != "") return "morph editing";
        return "";
    }

    String keyboard(KeyEvent event) {
        if (event.getAction() == KeyEvent.RELEASE && event.getKeyCode() == Keycodes.L) {
            toggleVisibility();
            return "toggle UI visibility";
        }
        if (!isVisible) return "";
        //route keyboard event
        if (editMode == EDIT_FIGURE && modeFigure.keyboard(event) != "") return "figure editing";
        else if (editMode == EDIT_PATH && modePath.keyboard(event) != "") return "path editing";
        else if (editMode == EDIT_PULSE && modePulse.keyboard(event) != "") return "pulse editing";
        else if (editMode == EDIT_MORPH && modeMorph.keyboard(event) != "") return "morph editing";
        return "";
    }

    void openFile(File file) {
        if (file == null) return; //user hit cancel or closed
        openFilepath = file.getAbsolutePath();
    }

    void digestFile() {
        JSONObject json = loadJSONObject(openFilepath);
        openFilepath = null;
        offset.set(json.getFloat(OFFSET_X), json.getFloat(OFFSET_Y));
        palette.resetColors(json);

        //anchors
        allDots.clear();
        for (String coords : json.getJSONArray(EdFiles.DOTS).getStringArray()) {
            String[] values = coords.split("\\.");
            allDots.add(new XY(Float.valueOf(values[0]), Float.valueOf(values[1])));
        }
        modeFigure.closestAnchor = allDots.get(0);

        //polygons
        allPolygons.clear();
        for (int i = 0; i < json.getJSONArray(POLYGONS).size(); i++) {
            JSONObject jsonPolygon = json.getJSONArray(POLYGONS).getJSONObject(i);
            XY[] anchors = new XY[jsonPolygon.getJSONArray(EdFiles.DOTS).size()];
            int a = 0;
            for (int anchorIndex : jsonPolygon.getJSONArray(EdFiles.DOTS).getIntArray()) {
                anchors[a++] = allDots.get(anchorIndex);
            }
            allPolygons.add(new LatticePolygon(anchors));
        }

        //paths - lists of lists...
        allPaths.clear();
        JSONArray jsonPaths = json.getJSONArray(PATHS);
        for (int p = 0; p < jsonPaths.size(); p++) {
            JSONObject jsonPath = jsonPaths.getJSONObject(p);
            LatticePath newPath = new LatticePath();
            newPath.name = jsonPath.getString(NAME);
            for (int f = 0; f < jsonPath.getJSONArray(FRAMES).size(); f++) {
                JSONArray jsonFrames = jsonPath.getJSONArray(FRAMES).getJSONArray(f);
                JSONArray jsonValues = jsonPath.getJSONArray(VALUES).getJSONArray(f);
                if (f > 0) newPath.addFrame();
                for (int i = 0; i < jsonFrames.size(); i++) {
                    newPath.frames.get(f).add(allPolygons.get(jsonFrames.getInt(i)));
                    newPath.frameValues.get(f).add(jsonValues.getInt(i));
                }
            }
            allPaths.add(newPath);
        }

        //store animations
        // allAnimations.clear();
        // JSONObject jsonAnimation;
        // for (int i = 0; i < json.getJSONArray(ANIMATIONS).size(); i++) {
        //  jsonAnimation = json.getJSONArray(ANIMATIONS).getJSONObject(i);
        //  allAnimations.add(new AnimationFrames(jsonAnimation.getString(ANIMATION_NAME), jsonAnimation.getJSONArray(ANIMATION_FRAMES)));
        // }
        // selectedAnimation = allAnimations.get(0);
        // selectedAnimation.drawFrame();
    }

    void saveFile(File file) {
        if (file == null) return; //user hit cancel or closed
        ArrayList<String> fileLines = new ArrayList<String>();
        fileLines.add("{"); //opening bracket
        fileLines.add(jsonKV(OFFSET_X, offset.x));
        fileLines.add(jsonKV(OFFSET_Y, offset.y));
        fileLines.add(palette.asJsonKV());
        fileLines.add(jsonKVNoComma(EdFiles.DOTS, "["));
        int valueCount = -1;
        String line = "";
        //here we save each set of coordinates separated by a period ("xxx.yyy")
        //to make it easier to read and slightly smaller to store
        for (int i = 0; i < allDots.size(); i++) {
            if (++valueCount == 10) {
                valueCount = 0;
                fileLines.add(TAB + line);
                line = "";
            }
            line += "\"" + (int)allDots.get(i).x + "." + (int)allDots.get(i).y + "\", ";
        }
        fileLines.add(TAB + line);
        fileLines.add("],"); //close dots list

        //list polygons as json objects {"dots":[vertex indicies...]}
        fileLines.add(jsonKVNoComma(POLYGONS, "["));
        for (LatticePolygon polygon : allPolygons) {
            String[] dotIndicies = new String[polygon.dots.length];
            for (int i = 0; i < polygon.dots.length; i++) {
                dotIndicies[i] = String.valueOf(allDots.indexOf(polygon.dots[i]));
            }
            fileLines.add(TAB + "{" + jsonKV(EdFiles.DOTS, Arrays.toString(dotIndicies) + "}")); 
        }
        fileLines.add("],"); //close polygon list

        //paths
        fileLines.add(jsonKVNoComma(PATHS, "[{"));
        for (int p = 0; p < allPaths.size(); p++) {
            if (p > 0) fileLines.add("},{"); //separation between layer objects in this array
            LatticePath path = allPaths.get(p);
            fileLines.add(TAB + jsonKVString(NAME, path.name));


            fileLines.add(TAB + jsonKVNoComma(FRAMES, "["));
            for (int f = 0; f < path.frames.size(); f++) {
                String polyIndicies = "[";
                for (int i = 0; i < path.frames.get(f).size(); i++) {
                    if (i > 0) polyIndicies += ", ";
                    polyIndicies += allPolygons.indexOf(path.frames.get(f).get(i));
                }
                fileLines.add(TAB + TAB + polyIndicies + "],"); 
            }
            fileLines.add(TAB + "],"); //close frame poly indicies
            fileLines.add(TAB + jsonKVNoComma(VALUES, "["));
            for (int f = 0; f < path.frameValues.size(); f++) {
                String polyValues = "[";
                for (int i = 0; i < path.frameValues.get(f).size(); i++) {
                    if (i > 0) polyValues += ", ";
                    polyValues += path.frameValues.get(f).get(i);
                }
                fileLines.add(TAB + TAB + polyValues + "],"); 
            }
            fileLines.add(TAB + "]"); //close frame poly values


        }
        fileLines.add("}],"); //close paths list

        //

        //animations
        // fileLines.add(jsonKVNoComma(ANIMATIONS, "[{"));
        // int a = 0;
        // for (AnimationFrames animation : allAnimations) {
        //  if (a++ > 0) fileLines.add("},{"); //separation between animation objects in this array
        //  fileLines.add(TAB + jsonKVString(ANIMATION_NAME, animation.name));
        //  fileLines.add(TAB + jsonKVNoComma(ANIMATION_FRAMES, "["));
        //  for (int i = 0; i < animation.polygonColors.length; i++) {
        //      fileLines.add(TAB + TAB + "{" + jsonKV(FRAME_DELAY, animation.delays[i]) + jsonKV(FRAME_COLORS, "\"" + animation.polygonColors[i] + "\"}"));
        //  }
        //  fileLines.add(TAB + "]"); //close frames for this animation
        // }
        //fileLines.add("}]"); //close animation list

        fileLines.add("}"); //final closing bracket
        saveStrings(file.getAbsolutePath(), fileLines.toArray(new String[0]));
    }

    void openImage(File file) {
        if (file == null) return; //user hit cancel or closed
        unscaledReference = loadImage(file.getAbsolutePath());
        //figureScale.set(1.0);
        modeFigure.getButtons("show image").setCheck(true);
        rescaleImage();
        referenceImageVisible = true;
    }

    void rescaleImage() {
        if (unscaledReference != null) {
            referenceImage = unscaledReference.copy();
            referenceImage.resize((int)(unscaledReference.width * figureScale.value), (int)(unscaledReference.height * figureScale.value));
        }
    }

    /** Get mouse position adjusted for offset and scale */
    XY translateMouse() {
        return new XY((mouseX - offset.x) / figureScale.value, (mouseY - offset.y) / figureScale.value);
    }

    /** 
    * Attributes for polygon charge
    */
    private class LatticeCharge {
        BoundedInt borderWidth, hilightWidth;
        int borderPaletteIndex, hilightPaletteIndex, facePaletteIndex;

        LatticeCharge(int borderW, int hilightW, int borderC, int hilightC, int faceC) {
            borderWidth = new BoundedInt(0, 10, borderW);
            hilightWidth = new BoundedInt(0, 10, hilightW);
            borderPaletteIndex = borderC;
            hilightPaletteIndex = hilightC;
            facePaletteIndex = faceC;
        }
    } //end LatticeCharge

    /** 
    * Face on the lattice 
    */
    private class LatticePolygon {
        XY[] dots;
        XY center;
        BoundedInt chargeLevel;

        LatticePolygon(ArrayList<XY> anchors) { this(anchors.toArray(new XY[0])); }
        LatticePolygon(XY[] anchors) {
            dots = anchors;
            center = new XY(0, 0);
            for (XY dot : dots) {
                center.x += dot.x;
                center.y += dot.y;
            }
            center.x /= dots.length;
            center.y /= dots.length;
            chargeLevel = defaultCharge.clone();
        }

        /**
        * We're not implementing Kid but we will follow convention by defining a draw(PGraphics);
        */
        void draw(PGraphics canvas) {
            LatticeCharge charge = allCharges.get(chargeLevel.value);
            canvas.noStroke();
            //outermost
            if (charge.borderWidth.value > 0) {
                canvas.beginShape();
                canvas.fill(palette.colors.get(charge.borderPaletteIndex));
                for (XY dot : dots) {
                    canvas.vertex(dot.x * figureScale.value, dot.y * figureScale.value);
                }
                canvas.endShape(CLOSE);
            }
            //inner
            if (charge.hilightWidth.value > 0) {
                canvas.beginShape();
                canvas.fill(palette.colors.get(charge.hilightPaletteIndex));
                for (XY dot : getOffsetPoly(charge.borderWidth.value)) {
                    canvas.vertex(dot.x * figureScale.value, dot.y * figureScale.value);
                }
                canvas.endShape(CLOSE);
            }
            //innermost
            canvas.beginShape();
            canvas.fill(palette.colors.get(charge.facePaletteIndex));
            for (XY dot : getOffsetPoly(charge.borderWidth.value + charge.hilightWidth.value)) {
                canvas.vertex(dot.x * figureScale.value, dot.y * figureScale.value);
            }
            canvas.endShape(CLOSE);
        }

        //http://pyright.blogspot.com/2011/02/simple-polygon-offset.html
        //https://stackoverflow.com/questions/1109536/an-algorithm-for-inflating-deflating-offsetting-buffering-polygons

        XY[] getOffsetPoly(float offset) {
            XY[] newPoly = new XY[dots.length];
            for (int i = 0; i < dots.length - 3; i++) {
                newPoly[i] = getPt(dots[i], dots[i + 1], dots[i + 2], offset);
            }
            int last = dots.length - 1;
            newPoly[last - 2] = getPt(dots[last - 2], dots[last - 1], dots[last], offset);
            newPoly[last - 1] = getPt(dots[last - 1], dots[last], dots[0], offset);
            newPoly[last] = getPt(dots[last], dots[0], dots[1], offset);
            return newPoly;
        }

        XY getPt(XY pt1, XY pt2, XY pt3, float offset) {
            // first offset intercept
            float divisor = (pt1.x == pt2.x) ? 1 : pt2.x - pt1.x;
            float m = (pt2.y - pt1.y)/divisor;
            //if (m == Float.POSITIVE_INFINITY || m == Float.NEGATIVE_INFINITY) m = (pt2.y - pt1.y);
            float boffset = getOffsetIntercept(pt1, pt2, m, offset);

            // get second offset intercept
            float divisorprime = (pt2.x == pt3.x) ? 1 : pt3.x - pt2.x;
            float mprime = (pt3.y - pt2.y)/divisorprime;
            //if (mprime == Float.POSITIVE_INFINITY || mprime == Float.NEGATIVE_INFINITY) mprime = (pt3.y - pt2.y);
            float boffsetprime = getOffsetIntercept(pt2, pt3, mprime, offset);

            // get intersection of two offset lines
            float newx = (boffsetprime - boffset)/(m - mprime);
            float newy = m * newx + boffset;
            //println(m + "|" + boffset + "|" + mprime + "|" + boffsetprime + "|" + newx + "|" + newy);
            return new XY(newx, newy);
        }

        float getOffsetIntercept(XY pt1, XY pt2, float m, float offset) {
            float theta = atan2(pt2.y - pt1.y, pt2.x - pt1.x) + HALF_PI;
            return (pt1.y - sin(theta) * offset) - m * (pt1.x - cos(theta) * offset);
        }

        boolean containsPoint(XY point) { return containsPoint(point.x, point.y); }
        boolean containsPoint(float x, float y) {
            // https://stackoverflow.com/a/16391873
            boolean inside = false;
            for (int i = 0, j = dots.length - 1; i < dots.length; j = i++) {
                if ((dots[i].y > y) != (dots[j].y > y) &&
                    x < (dots[j].x - dots[i].x) * (y - dots[i].y) / (dots[j].y - dots[i].y) + dots[i].x) {
                    inside = !inside;
                }
            }
            return inside;
        }
    } //end LatticePolygon

    /**
    * Path of cells on figure that pulses navigate through
    */
    private class LatticePath {
        ArrayList<ArrayList<LatticePolygon>> frames;
        ArrayList<ArrayList<Integer>> frameValues;
        String name;

        LatticePath() {
            frames = new ArrayList<ArrayList<LatticePolygon>>();
            frameValues = new ArrayList<ArrayList<Integer>>();
            name = "path" + allPaths.size();
            addFrame();
        }

        void addFrame() {
            frames.add(new ArrayList<LatticePolygon>());
            frameValues.add(new ArrayList<Integer>());
        }

        void addPoly(LatticePolygon poly, int f) {
            frames.get(f).add(poly);
            frameValues.get(f).add(0);
        }

        void deletePoly(LatticePolygon poly, int f) {
            int index = frames.get(f).indexOf(poly);
            frames.get(f).remove(index);
            frameValues.get(f).remove(index);
        }
    } //end LatticePath

    /**
    * Instructions for adjusting charge along a path
    */
    private class LatticePulse {
        ArrayList<HashMap<Integer, Integer>> instructions;
        BoundedInt delay;
        String name;

        LatticePulse() {
            instructions = new ArrayList<HashMap<Integer, Integer>>();
            instructions.add(new HashMap<Integer, Integer>());
            delay = new BoundedInt(0, 50, 2);
            name = "";
        }

        // void set(int index, int position, int value) {
        //  instructions.get(index).put(position, value);
        // }
    } //end LatticePulse

    /**
    * Handles the playing of the pulse on the path
    */
    private class PathPulse {
        LatticePath path;
        LatticePulse pulse;
        BoundedInt timer;
        int playingIndex;

        PathPulse(LatticePath thePath, LatticePulse thePulse) {
            path = thePath;
            pulse = thePulse;
            timer = new BoundedInt(0, pulse.delay.value, pulse.delay.value - 1);
            timer.loops = true;
            playingIndex = -1;
        }

        //horribly confusing I know...
        void progress() {
            if (timer.increment() < timer.maximum) return;
            if (++playingIndex - pulse.instructions.size() == path.frames.size()) {
                finishedPulses.add(this); //queue for removal
                return;
            }
            for (int f = 0; f < pulse.instructions.size(); f++) {
                int pathIndex = playingIndex - f;
                if (pathIndex >= path.frames.size()) continue;
                else if (pathIndex < 0) break;
                for (int v = -PATH_R; v <= PATH_R; v++) {
                    Integer adjustValue = pulse.instructions.get(f).get(v);
                    if (adjustValue == null) continue;
                    for (int p = 0; p < path.frames.get(pathIndex).size(); p++) {
                        if (path.frameValues.get(pathIndex).get(p) == v) {
                            path.frames.get(pathIndex).get(p).chargeLevel.increment(adjustValue); //change polygon charge level
                        }
                    }
                }
            }
        }
    } //end PathPulse

    /** 
    * Edit anchors and polygons 
    */
    private class ModeFigure extends GadgetPanel {
        LatticePolygon selectedPolygon;
        ArrayList<XY> selectedAnchors;
        XY closestAnchor;
        boolean showDots;
        int dotsAddedThisClick;
        final int DOT_RADIUS = 7;

        ModeFigure() {
            super(modeButtons.body.w + UI_PADDING * 2, 0, "Figure", basicButtonAlbum);
            selectedAnchors = new ArrayList<XY>();
            closestAnchor = allDots.get(0);
            selectedPolygon = null;
            showDots = true;
            dotsAddedThisClick = 0;

            //GadgetPanel items
            addItem("image", GadgetPanel.OPEN, new Command() {
                void execute(String clicked) {
                    selectInput("Select image (.jpg, .png)", "openImage", null, LightLattice.this);
                }
            });

            addItem("show image", GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
                void execute(String clicked) {
                    if (referenceImage == null) {
                        windowTitle = "no image loaded";
                        return;
                    }
                    getButtons("show image").toggleImage();
                    referenceImageVisible = !referenceImageVisible;
                }
            });

            addItem("show dots", GadgetPanel.BLANK, GadgetPanel.BIGX, new Command() {
                void execute(String clicked) {
                    getButtons("show dots").toggleImage();
                    showDots = !showDots;
                }
            });
            getButtons("show dots").setCheck(0, true);

            addItem("scale", new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS }, new Command() {
                void execute(String clicked) {
                    if (clicked == GadgetPanel.MINUS) figureScale.decrement();
                    else figureScale.increment();
                    rescaleImage();
                    windowTitle = "scale:" + figureScale.value;
                }
            });

            addItem("define polygon", GadgetPanel.START_LIGHT, new Command() {
                void execute(String clicked) {
                    definePolygon();
                }
            });

            addItem("dot add|split", new String[] { GadgetPanel.PLUS, GadgetPanel.OVER_UNDER }, new Command() {
                void execute(String clicked) {
                    if (clicked == GadgetPanel.PLUS) {
                        addDot(closestAnchor.x + 20, closestAnchor.y + 20);
                    }
                    else { //if (clicked == GadgetPanel.OVER_UNDER) {
                        splitLine();
                    }
                }
            });

            addItem("disconnect|delete", new String[] { GadgetPanel.BLANK, GadgetPanel.BIGX }, new Command() {
                void execute(String clicked) {
                    if (clicked == GadgetPanel.BLANK) {
                        println("nada");
                        // ArrayList<LatticePolygon> toDelete = new ArrayList<LatticePolygon>();
                        // for (LatticePolygon polygon : allPolygons) {
                        //  if (Arrays.asList(polygon.dots).contains(selectedAnchor)) {
                        //      toDelete.add(polygon);
                        //  }
                        // }
                        // int confirm = JOptionPane.showConfirmDialog(null, "Remove " + toDelete.size() + " polygons connected to dot?", "Delete?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
                        // if (confirm == JOptionPane.YES_OPTION) { 
                        //  for (LatticePolygon del : toDelete) {
                        //      allPolygons.remove(del);
                        //  }
                        // }
                    }
                    else { //if (clicked == GadgetPanel.BIGX) {
                        deleteDot();
                    }
                }
            });

        } //end constructor

        void draw(PGraphics canvas) {
            float s = figureScale.value; //scale
            canvas.pushMatrix();
            canvas.translate(offset.x, offset.y);
            //anchors
            canvas.strokeWeight(1);
            if (showDots) {
                canvas.fill(EdColors.UI_DARKEST);
                canvas.stroke(EdColors.UI_DARK);
                for (XY dot : allDots) {
                    canvas.ellipse(dot.x * s, dot.y * s, DOT_RADIUS, DOT_RADIUS);
                }
            }
            canvas.fill(EdColors.UI_EMPHASIS);
            canvas.ellipse(closestAnchor.x * s, closestAnchor.y * s, DOT_RADIUS, DOT_RADIUS);
            
            //selected anchors
            if (selectedAnchors.size() > 0) {
                canvas.fill(color(#FFFFFF, 100));
                XY lastSelected = selectedAnchors.get(selectedAnchors.size() - 1);
                canvas.ellipse(lastSelected.x * s, lastSelected.y * s, DOT_RADIUS * 3, DOT_RADIUS * 3);
                canvas.stroke(EdColors.UI_EMPHASIS);
                canvas.strokeWeight(3);
                for (int i = 0; i < selectedAnchors.size() - 1; i++) {
                    canvas.line(selectedAnchors.get(i).x * s, selectedAnchors.get(i).y * s, selectedAnchors.get(i + 1).x * s, selectedAnchors.get(i + 1).y * s);
                }
                //implied line that closes the polygon
                if (selectedAnchors.size() > 2) {
                    canvas.stroke(color(#FFFFFF, 100));
                    canvas.line(lastSelected.x * s, lastSelected.y * s, selectedAnchors.get(0).x * s, selectedAnchors.get(0).y * s);
                }
                canvas.strokeWeight(1);
            }

            //mouseover hilighted polygon
            if (selectedPolygon == null) {
                XY mouseTranslated = translateMouse();
                for (LatticePolygon polygon : allPolygons) {
                    if (polygon.containsPoint(mouseTranslated)) {
                        canvas.stroke(color(#FFFFFF, 100));
                        canvas.strokeWeight(3);
                        int last = polygon.dots.length - 1;
                        for (int i = 0; i < last; i++) {
                            canvas.line(polygon.dots[i].x * s, polygon.dots[i].y * s, polygon.dots[i + 1].x * s, polygon.dots[i + 1].y * s);
                        }
                        canvas.line(polygon.dots[last].x * s, polygon.dots[last].y * s, polygon.dots[0].x * s, polygon.dots[0].y * s);
                        break;
                    }
                }
            }
            canvas.popMatrix();
            super.draw(canvas); //GadgetPanel
        }

        String mouse() {
            if (super.mouse() != "") return "dragging";

            //find anchor that's closest to the mouse
            XY mouseTranslated = translateMouse();
            float mouseDist, closestDist;
            closestDist = closestAnchor.distance(mouseTranslated);
            for (XY dot : allDots) {
                mouseDist = dot.distance(mouseTranslated);
                if (mouseDist < closestDist) {
                    closestAnchor = dot;
                    closestDist = mouseDist;
                }
            }
            
            if (edwin.mouseBtnHeld == LEFT) {
                if (edwin.isShiftDown) {
                    closestAnchor.set(mouseTranslated);
                    windowTitle = closestAnchor.toString();
                    return "shift dot";
                }
                else if (mouseTranslated.distance(closestAnchor) < DOT_RADIUS) {
                    if (selectedAnchors.indexOf(closestAnchor) == -1) {
                        //if there's only 1 dot selected and it's not this closest one then deselect
                        if (selectedAnchors.size() == 1 && selectedAnchors.get(0) != closestAnchor && edwin.mouseBtnBeginHold == LEFT) { 
                            selectedAnchors.clear();
                        }
                        selectedAnchors.add(closestAnchor);
                        dotsAddedThisClick++;
                        return "anchor selected";
                    }
                }
            }
            else if (edwin.mouseBtnReleased == LEFT) {
                if (dotsAddedThisClick == 0) {
                    for (LatticePolygon polygon : allPolygons) {
                        if (polygon.containsPoint(mouseTranslated)) {
                            selectedPolygon = polygon;
                            selectedAnchors.clear();
                            selectedAnchors.addAll(Arrays.asList(polygon.dots));
                            return "polygon selected";
                        }
                    }
                    //else if the click is far away from the last selected dot then deselect all
                    if (selectedAnchors.size() > 0 && selectedAnchors.get(selectedAnchors.size() - 1).distance(mouseTranslated) > 30) { 
                        selectedPolygon = null;
                        selectedAnchors.clear();
                    }
                }
                dotsAddedThisClick = 0;
            }
            else if (edwin.mouseBtnReleased == RIGHT) {
                if (closestAnchor.distance(mouseTranslated) < DOT_RADIUS) {
                    if (selectedAnchors.indexOf(closestAnchor) != -1) selectedAnchors.remove(closestAnchor);
                    if (selectedAnchors.size() == 0) selectedPolygon = null;
                    return "deselect dot";
                }
            }
            return "";
        }

        String keyboard(KeyEvent event) {
            int kc = event.getKeyCode();
            if (event.getAction() == KeyEvent.PRESS && event.isShiftDown()) {
                if (kc == Keycodes.UP) {
                    for (XY anchor : selectedAnchors) anchor.y--;
                }
                else if (kc == Keycodes.DOWN) {
                    for (XY anchor : selectedAnchors) anchor.y++;
                }
                else if (kc == Keycodes.LEFT) {
                    for (XY anchor : selectedAnchors) anchor.x--;
                }
                else if (kc == Keycodes.RIGHT) {
                    for (XY anchor : selectedAnchors) anchor.x++;
                }
                else {
                    return "";
                }
                return "dots shifted";
            }
            else if (event.getAction() == KeyEvent.RELEASE) {
                return "";
            }
            if (kc == Keycodes.INSERT) {
                addDot(mouseX, mouseY);
            }
            else if (kc == Keycodes.DELETE) {
                if (selectedPolygon == null) deleteDot();
                else {
                    allPolygons.remove(selectedPolygon); //TODO check for paths that use polygon...
                    selectedPolygon = null;
                    selectedAnchors.clear();
                }
            }
            else if (kc == Keycodes.P) {
                definePolygon();
            }
            else if (kc == Keycodes.SEMICOLON) {
                splitLine();
            }
            else if (kc == Keycodes.BACK_SPACE) {
                selectedAnchors.clear();
                selectedPolygon = null;
            }
            else {
                return "";
            }
            return "";
        }

        void addDot(float x, float y) {
            XY newDot = new XY((x - offset.x) / figureScale.value, (y - offset.y) / figureScale.value);
            allDots.add(newDot);
            selectedAnchors.clear();
            selectedAnchors.add(newDot);
            windowTitle = "dot created:" + (allDots.size() - 1); 
        }

        void deleteDot() {
            if (allDots.size() == 1) {
                windowTitle = "can't delete only dot";
                return;
            }
            else if (selectedAnchors.size() != 1) {
                windowTitle = "select 1 dot";
                return;
            }
            int confirm = JOptionPane.showConfirmDialog(null, "Really delete dot?", "Delete?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
            if (confirm == JOptionPane.YES_OPTION) { 
                allDots.remove(selectedAnchors.get(0));
                selectedAnchors.clear();
                closestAnchor = allDots.get(0);
                windowTitle = "dot deleted";
                //TODO also check for connected polygons
            }
        }

        void definePolygon() {
            if (selectedAnchors.size() > 2) {
                allPolygons.add(new LatticePolygon(selectedAnchors));
                selectedAnchors.clear();
                windowTitle = "polygon added";
            }
            else {
                windowTitle = "need dots > 2";
            }
            selectedPolygon = null;
        }

        void splitLine() {
            if (selectedAnchors.size() != 2) {
                windowTitle = "select 2 dots";
                return;
            }
            XY dot0 = selectedAnchors.get(0);
            XY dot1 = selectedAnchors.get(1);
            XY newDot = dot0.midpoint(dot1);
            allDots.add(newDot);
            selectedAnchors.clear();
            selectedAnchors.add(newDot);
            closestAnchor = newDot;
            //insert new dot into existing polygons that use these two dots adjacently
            for (LatticePolygon polygon : allPolygons) {
                int last = polygon.dots.length - 1;
                int insertPosition = -1;
                //search through dots and check for the two selected ones to determine insertPosition
                for (int i = 0; i < polygon.dots.length; i++) {
                    if (polygon.dots[i] == dot0) {
                        if (i == 0 && polygon.dots[last] == dot1) {
                            insertPosition = last + 1;
                            break;
                        }
                        else if (i == last && polygon.dots[0] == dot1) {
                            insertPosition = 0;
                            break;
                        }
                        else if (i != last && polygon.dots[i + 1] == dot1) {
                            insertPosition = i + 1;
                            break;
                        }
                        else if (i > 0 && i <= last && polygon.dots[i - 1] == dot1) {
                            insertPosition = i - 1;
                            break;
                        }
                    }
                    else if (polygon.dots[i] == dot1) {
                        if (i == 0 && polygon.dots[last] == dot0) {
                            insertPosition = last + 1;
                            break;
                        }
                        else if (i == last && polygon.dots[0] == dot0) {
                            insertPosition = 0;
                            break;
                        }
                        else if (i != last && polygon.dots[i + 1] == dot0) {
                            insertPosition = i + 1;
                            break;
                        }
                        else if (i > 0 && i <= last && polygon.dots[i - 1] == dot0) {
                            insertPosition = i - 1;
                            break;
                        }
                    }
                }
                //polygon dot loop finished. now we see if we need to insert newDot into the polygon
                if (insertPosition == -1) continue;
                XY[] newList = new XY[polygon.dots.length + 1];
                for (int i = 0; i < insertPosition; i++) {
                    newList[i] = polygon.dots[i];
                }
                newList[insertPosition] = newDot;
                for (int i = insertPosition; i < polygon.dots.length; i++) {
                    newList[i + 1] = polygon.dots[i];
                }
                polygon.dots = newList; //assign new points to polygon
            }
        }
    } //end ModeFigure

    /**
    * Edit paths
    * Please pardon the absurd chains of .get()s since I need paths to be a list of lists (and there should be multiple paths...)
    */
    private class ModePath extends GadgetPanel {
        BoundedInt selectedPath, selectedFrame;

        ModePath() {
            super(modeButtons.body.w + UI_PADDING * 2, 0, "Path", basicButtonAlbum);
            selectedPath = new BoundedInt(0, 0);
            selectedFrame = new BoundedInt(0, 0);

            addItem("scale", new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS }, new Command() {
                void execute(String clicked) {
                    if (clicked == GadgetPanel.MINUS) figureScale.decrement();
                    else figureScale.increment();
                    rescaleImage();
                    windowTitle = "scale:" + figureScale.value;
                }
            });

            addItem("selected", new String[] { GadgetPanel.ARROW_W, GadgetPanel.ARROW_E }, new Command() {
                void execute(String clicked) {
                    if (clicked == GadgetPanel.ARROW_W) {
                        selectedPath.decrement();
                    }
                    else {
                        if (selectedPath.atMax()) addPath();
                        else selectedPath.increment();
                    }
                    selectedFrame.setMax(allPaths.get(selectedPath.value).frames.size() - 1);
                    selectedFrame.minimize();
                    windowTitle = selPath().name;
                }
            });

            addItem("frame", new String[] { GadgetPanel.ARROW_W, GadgetPanel.ARROW_E }, new Command() {
                void execute(String clicked) {
                    if (clicked == GadgetPanel.ARROW_W) {
                        decrementFrame();
                    }
                    else {
                        incrementFrame();
                    }
                }
            });

            addItem("name", new String[] { GadgetPanel.OK }, new Command() {
                void execute(String clicked) {
                    String newName = JOptionPane.showInputDialog("Enter new path name", selPath().name);
                    if (newName == null) return;
                    selPath().name = newName;
                    windowTitle = newName;
                }
            });

        }

        /** convenience functions */
        LatticePath selPath() { return allPaths.get(selectedPath.value); }
        ArrayList<LatticePolygon> selFrame() { return selPath().frames.get(selectedFrame.value); }

        void draw(PGraphics canvas) {
            float s = figureScale.value; //scale
            canvas.pushMatrix();
            canvas.translate(offset.x, offset.y);
            canvas.noStroke();
            for (int i = 0; i < selFrame().size(); i++) {
                canvas.fill(255);
                canvas.ellipse(selFrame().get(i).center.x * s, selFrame().get(i).center.y * s, 20, 20);
                canvas.fill(EdColors.UI_EMPHASIS);
                canvas.text(selPath().frameValues.get(selectedFrame.value).get(i), selFrame().get(i).center.x * s - 4, selFrame().get(i).center.y * s + 4);
            }
            canvas.popMatrix();
            super.draw(canvas); //GadgetPanel
        }

        String mouse() {
            if (!isVisible) return "";
            if (super.mouse() != "") return "dragging";

            if (edwin.mouseBtnReleased == 0) return "";
            XY mouseTranslated = translateMouse();

            for (LatticePolygon polygon : allPolygons) {
                if (polygon.containsPoint(mouseTranslated)) {
                    if (edwin.mouseBtnReleased == LEFT && !selFrame().contains(polygon)) selPath().addPoly(polygon, selectedFrame.value);
                    if (edwin.mouseBtnReleased == RIGHT && selFrame().contains(polygon)) selPath().deletePoly(polygon, selectedFrame.value);
                    break;
                }
            }
            
            return "";
        }

        String keyboard(KeyEvent event) {
            if (event.getAction() != KeyEvent.RELEASE) {
                return "";
            }
            XY mouseTranslated = translateMouse();
            int kc = event.getKeyCode();
            if (kc == Keycodes.LEFT) {
                decrementFrame();
            }
            else if (kc == Keycodes.RIGHT) {
                incrementFrame();
            }
            else if (kc == Keycodes.UP) {
                for (LatticePolygon polygon : allPolygons) {
                    int polyIndex = selFrame().indexOf(polygon);
                    if (polygon.containsPoint(mouseTranslated) && polyIndex != -1) {
                        Integer val = selPath().frameValues.get(selectedFrame.value).get(polyIndex);
                        selPath().frameValues.get(selectedFrame.value).set(polyIndex, val + 1);
                        break;
                    }
                }
            }
            else if (kc == Keycodes.DOWN) {
                for (LatticePolygon polygon : allPolygons) {
                    int polyIndex = selFrame().indexOf(polygon);
                    if (polygon.containsPoint(mouseTranslated) && polyIndex != -1) {
                        Integer val = selPath().frameValues.get(selectedFrame.value).get(polyIndex);
                        selPath().frameValues.get(selectedFrame.value).set(polyIndex, val - 1);
                        break;
                    }
                }
            }
            else {
                return "";
            }
            return HELLO;
        }

        void addPath() {
            LatticePath lastPath = allPaths.get(selectedPath.maximum);
            if (lastPath.frames.size() == 1 && lastPath.frames.get(0).size() == 0) {
                JOptionPane.showMessageDialog(null, "Current path is empty. Use current before adding a new one.", "Can't", JOptionPane.INFORMATION_MESSAGE);
                return;
            }
            allPaths.add(new LatticePath());
            selectedPath.incrementMax();
            selectedPath.maximize();
        }

        void addFrame() {
            ArrayList<LatticePolygon> lastFrame = selPath().frames.get(selectedFrame.maximum);
            if (lastFrame.size() == 0) {
                int selected = JOptionPane.showConfirmDialog(null, "Last frame has no polygons. Add new frame anyways?", "New frame after empty?", JOptionPane.YES_NO_OPTION, JOptionPane.WARNING_MESSAGE);
                if (selected != JOptionPane.YES_OPTION) { 
                    return;
                }
            }
            selPath().addFrame();
            selectedFrame.incrementMax();
            selectedFrame.maximize();
        }

        void incrementFrame() {
            if (selectedFrame.atMax()) addFrame();
            else selectedFrame.increment();
            windowTitle = "frame " + selectedFrame.value + "/" + selectedFrame.maximum;
        }

        void decrementFrame() {
            selectedFrame.decrement();
            windowTitle = "frame " + selectedFrame.value + "/" + selectedFrame.maximum;
        }
    } //end ModePath

    /**
    * Edit pulses
    */
    private class ModePulse extends DraggableWindow {
        ArrayList<GridButtons> gridButtons;
        ArrayList<TextLabel> labels;
        LatticePolygon sampleColorPolygon;
        LatticeCharge selectedCharge;
        LatticePulse selectedPulse;
        XYWH chargeGrid;
        float squareY, squareSide;
        final int GRID = 18, GRID_W = PATH_R * 2 + 1, GRID_H = 14;

        ModePulse() {
            super(modeButtons.body.w + UI_PADDING * 2, 0);
            //polygon
            int numPoints = 5, radius = 60;
            float angle = -HALF_PI, increment = TWO_PI / (float)numPoints;
            XY[] polygonPoints = new XY[numPoints];
            for (int i = 0; i < numPoints; i++) {
                polygonPoints[i] = new XY(cos(angle) * radius + radius + UI_PADDING, sin(angle) * radius + radius + dragBar.h + UI_PADDING * 2);
                angle -= increment;
            }
            sampleColorPolygon = new LatticePolygon(polygonPoints);

            //initialize some stuff
            selectedPulse = new LatticePulse();
            allPulses.add(selectedPulse);
            selectedCharge = allCharges.get(defaultCharge.value);
            gridButtons = new ArrayList<GridButtons>();
            labels = new ArrayList<TextLabel>();
            squareY = dragBar.h + radius * 2 + UI_PADDING * 3;
            squareSide = basicButtonAlbum.h;

            //window buttons and labels
            GridButtons borderButtons = new GridButtons(body, UI_PADDING, squareY, 3, basicButtonAlbum, new String[] { GadgetPanel.BLANK, GadgetPanel.MINUS, GadgetPanel.PLUS }) {
                void buttonClick(String clicked) { 
                    if (clicked == GadgetPanel.BLANK) {
                        if (palette.isVisible) selectedCharge.borderPaletteIndex = palette.selectedColor.value;
                    }
                    else if (clicked == GadgetPanel.MINUS) {
                        selectedCharge.borderWidth.decrement();
                    }
                    else { 
                        selectedCharge.borderWidth.increment();
                    }
                }
            };

            GridButtons hilightButtons = new GridButtons(body, UI_PADDING, borderButtons.body.yh(), 3, basicButtonAlbum, new String[] { GadgetPanel.BLANK, GadgetPanel.MINUS, GadgetPanel.PLUS }) {
                void buttonClick(String clicked) { 
                    if (clicked == GadgetPanel.BLANK) {
                        if (palette.isVisible) selectedCharge.hilightPaletteIndex = palette.selectedColor.value;
                    }
                    else if (clicked == GadgetPanel.MINUS) {
                        selectedCharge.hilightWidth.decrement();
                    }
                    else { 
                        selectedCharge.hilightWidth.increment();
                    }
                }
            };

            GridButtons faceButtons = new GridButtons(body, UI_PADDING, hilightButtons.body.yh(), 1, basicButtonAlbum, new String[] { GadgetPanel.BLANK }) {
                void buttonClick(String clicked) { 
                    if (palette.isVisible) selectedCharge.facePaletteIndex = palette.selectedColor.value;
                }
            };

            GridButtons chargeSelectButtons = new GridButtons(body, UI_PADDING, faceButtons.body.yh(), 2, basicButtonAlbum, new String[] { GadgetPanel.ARROW_S, GadgetPanel.ARROW_N }) {
                void buttonClick(String clicked) { 
                    int index = allCharges.indexOf(selectedCharge);
                    if (clicked == GadgetPanel.ARROW_N) {
                        if (index < allCharges.size() - 1) {
                            selectedCharge = allCharges.get(index + 1);
                            sampleColorPolygon.chargeLevel.increment();
                        }
                    }
                    else { 
                        if (index > 0) {
                            selectedCharge = allCharges.get(index - 1);
                            sampleColorPolygon.chargeLevel.decrement();
                        }
                    }
                    windowTitle = "charge:" + sampleColorPolygon.chargeLevel.value;
                }
            };

            GridButtons setDefaultButtons = new GridButtons(body, UI_PADDING, chargeSelectButtons.body.yh(), 1, basicButtonAlbum, new String[] { GadgetPanel.OK }) {
                void buttonClick(String clicked) { 
                    defaultCharge.set(allCharges.indexOf(selectedCharge));
                    for (LatticePolygon polygon : allPolygons) {
                        polygon.chargeLevel.set(defaultCharge.value);
                    }
                }
            };

            GridButtons paletteButtons = new GridButtons(body, UI_PADDING, setDefaultButtons.body.yh(), 1, basicButtonAlbum, new String[] { GadgetPanel.COLOR_WHEEL }) {
                void buttonClick(String clicked) { 
                    palette.body.set(mouseX, mouseY);
                    palette.toggleVisibility();
                }
            };

            gridButtons.add(borderButtons);
            labels.add(new TextLabel("border", borderButtons.body.xw(), borderButtons.body.y, body));
            gridButtons.add(hilightButtons);
            labels.add(new TextLabel("hilight", hilightButtons.body.xw(), hilightButtons.body.y, body));
            gridButtons.add(faceButtons);
            labels.add(new TextLabel("face", faceButtons.body.xw(), faceButtons.body.y, body));
            gridButtons.add(chargeSelectButtons);
            labels.add(new TextLabel("charge", chargeSelectButtons.body.xw(), chargeSelectButtons.body.y, body));
            gridButtons.add(setDefaultButtons);
            labels.add(new TextLabel("use as default", setDefaultButtons.body.xw(), setDefaultButtons.body.y, body));
            gridButtons.add(paletteButtons);
            labels.add(new TextLabel("palette", paletteButtons.body.xw(), paletteButtons.body.y, body));

            //=======================================
            // left ^
            //right v
            //=======================================

            float gridX = radius * 2 + UI_PADDING * 2;
            float gridY = dragBar.h + UI_PADDING;
            for (int i = 0; i < GRID_W; i++) {
                labels.add(new TextLabel(String.valueOf(-PATH_R + i), gridX + GRID * i, gridY, body, EdColors.UI_EMPHASIS));
            }
            chargeGrid = new XYWH(gridX, gridY + 18, GRID * GRID_W, GRID * GRID_H, body);

            GridButtons pulseSelectButtons = new GridButtons(body, chargeGrid.xw() + UI_PADDING, chargeGrid.y, 2, basicButtonAlbum, new String[] { GadgetPanel.ARROW_S, GadgetPanel.ARROW_N }) {
                void buttonClick(String clicked) { 
                    int index = allPulses.indexOf(selectedPulse);
                    if (clicked == GadgetPanel.ARROW_N) {
                        if (index < allPulses.size() - 1) {
                            index++;
                            selectedPulse = allPulses.get(index);
                        }
                    }
                    else { 
                        if (index > 0) {
                            index--;
                            selectedPulse = allPulses.get(index);
                        }
                    }
                    windowTitle = "pulse:" + index;
                }
            };

            GridButtons pulseNameButtons = new GridButtons(body, chargeGrid.xw() + UI_PADDING, pulseSelectButtons.body.yh(), 1, basicButtonAlbum, new String[] { GadgetPanel.OK }) {
                void buttonClick(String clicked) { 
                    String newName = JOptionPane.showInputDialog("Enter new pulse name", modePath.selPath().name);
                    if (newName == null) return;
                    selectedPulse.name = newName;
                    windowTitle = newName;
                }
            };

            GridButtons pulseDelayButtons = new GridButtons(body, chargeGrid.xw() + UI_PADDING, pulseNameButtons.body.yh(), 2, basicButtonAlbum, new String[] { GadgetPanel.MINUS, GadgetPanel.PLUS }) {
                void buttonClick(String clicked) { 
                    if (clicked == GadgetPanel.MINUS) {
                        selectedPulse.delay.decrement();
                    }
                    else {
                        selectedPulse.delay.increment();
                    }
                    windowTitle = "delay:" + selectedPulse.delay.value;
                }
            };

            GridButtons pulsePlayButtons = new GridButtons(body, chargeGrid.xw() + UI_PADDING, pulseDelayButtons.body.yh(), 1, basicButtonAlbum, new String[] { GadgetPanel.ARROW_E }) {
                void buttonClick(String clicked) { 
                    activePulses.add(new PathPulse(modePath.selPath(), selectedPulse));
                }
            };

            gridButtons.add(pulseSelectButtons);
            labels.add(new TextLabel("pulse", pulseSelectButtons.body.xw(), pulseSelectButtons.body.y, body));
            gridButtons.add(pulseNameButtons);
            labels.add(new TextLabel("name", pulseNameButtons.body.xw(), pulseNameButtons.body.y, body));
            gridButtons.add(pulseDelayButtons);
            labels.add(new TextLabel("delay", pulseDelayButtons.body.xw(), pulseDelayButtons.body.y, body));
            gridButtons.add(pulsePlayButtons);
            labels.add(new TextLabel("play", pulsePlayButtons.body.xw(), pulsePlayButtons.body.y, body));

            //DraggableWindow final touches
            body.setSize(pulseSelectButtons.body.xw() + 50, paletteButtons.body.yh() + UI_PADDING);
            dragBar.w = body.w - UI_PADDING * 2;
            windowTitle = "Pulse";
        }

        void draw(PGraphics canvas) {
            //DraggableWindow stuff
            super.draw(canvas);
            canvas.pushMatrix();
            canvas.translate(body.x, body.y);
            canvas.strokeWeight(1);

            //polygon with lazy workaround
            float s = figureScale.value; 
            figureScale.set(1.0);
            sampleColorPolygon.draw(canvas);
            figureScale.set(s);

            //buttons and labels
            for (GridButtons buttons : gridButtons) {
                buttons.draw(canvas);
            }
            for (TextLabel label : labels) {
                label.draw(canvas);
            }

            //palette color squares
            canvas.fill(palette.colors.get(selectedCharge.borderPaletteIndex));
            canvas.rect(UI_PADDING, squareY, squareSide, squareSide);
            canvas.fill(palette.colors.get(selectedCharge.hilightPaletteIndex));
            canvas.rect(UI_PADDING, squareY + squareSide, squareSide, squareSide);
            canvas.fill(palette.colors.get(selectedCharge.facePaletteIndex));
            canvas.rect(UI_PADDING, squareY + squareSide + squareSide, squareSide, squareSide);

            //charge grid and lines
            canvas.fill(EdColors.UI_DARK);
            canvas.rect(chargeGrid.x, chargeGrid.y, chargeGrid.w, chargeGrid.h);
            canvas.stroke(EdColors.UI_DARKEST);
            for (int y = 0; y <= GRID_H; y++) {
                canvas.line(chargeGrid.x, chargeGrid.y + GRID * y, chargeGrid.xw() - 1, chargeGrid.y + GRID * y);
            }
            for (int x = 0; x <= GRID_W; x++) {
                canvas.line(chargeGrid.x + GRID * x, chargeGrid.y, chargeGrid.x + GRID * x, chargeGrid.yh() - 1);
            }
            canvas.stroke(EdColors.UI_LIGHT);
            canvas.line(chargeGrid.x, chargeGrid.y + GRID * selectedPulse.instructions.size(), chargeGrid.xw() - 1, chargeGrid.y + GRID * selectedPulse.instructions.size());

            //hilighted grid cell
            if (chargeGrid.isMouseOver()) {
                int yIndex = (int)((mouseY - chargeGrid.screenY()) / GRID);
                int xIndex = (int)((mouseX - chargeGrid.screenX()) / GRID);
                canvas.stroke(EdColors.UI_EMPHASIS);
                canvas.noFill();
                canvas.rect(chargeGrid.x + xIndex * GRID, chargeGrid.y + yIndex * GRID, GRID, GRID);
            }

            canvas.fill(EdColors.UI_LIGHT);
            for (int y = 0; y < selectedPulse.instructions.size(); y++) {
                for (Integer mapKey : selectedPulse.instructions.get(y).keySet()) {
                    Integer x = mapKey + PATH_R;
                    Integer v = selectedPulse.instructions.get(y).get(mapKey);
                    canvas.text(String.valueOf(v), chargeGrid.x + x * GRID, chargeGrid.y + (y + 1) * GRID - 5);
                }
            }
            
            canvas.popMatrix();
        }

        String mouse() {
            if (!isVisible) return "";
            if (super.mouse() != "") return "dragging";

            if (edwin.mouseBtnReleased == LEFT) {
                for (GridButtons buttons : gridButtons) {
                    if (buttons.mouse() != "") return "button clicked";
                }
            }

            if (chargeGrid.isMouseOver() && edwin.mouseBtnReleased != 0) {
                //coords
                Integer yIndex = Integer.valueOf((int)(mouseY - chargeGrid.screenY()) / GRID);
                Integer xIndex = Integer.valueOf((int)(mouseX - chargeGrid.screenX()) / GRID);
                //potentially increase pulse instruction size
                if (yIndex >= selectedPulse.instructions.size()) {
                    for (int i = selectedPulse.instructions.size(); i <= yIndex; i++) {
                        selectedPulse.instructions.add(new HashMap<Integer, Integer>());
                    }
                }
                //adjust
                Integer currentValue = selectedPulse.instructions.get(yIndex).get(xIndex - PATH_R);
                if (currentValue == null) currentValue = 0;
                if (edwin.mouseBtnReleased == LEFT) currentValue++;
                else if (edwin.mouseBtnReleased == RIGHT) currentValue--;
                //assign
                if (currentValue == 0) selectedPulse.instructions.get(yIndex).remove(xIndex - PATH_R);
                else selectedPulse.instructions.get(yIndex).put(xIndex - PATH_R, currentValue);
                return "grid";
            }
            return "";
        }

        String keyboard(KeyEvent event) {
            if (event.getAction() != KeyEvent.RELEASE) {
                return "";
            }
            int kc = event.getKeyCode();
            if (kc == Keycodes.INSERT) {
            }
            else if (kc == Keycodes.DELETE) {
                
            }
            else if (kc == Keycodes.P) {
                //definePolygon();
            }
            else {
                return "";
            }
            return HELLO;
        }
    } //end ModePulse

    /**
    * Transformations
    */
    private class ModeMorph extends DraggableWindow {
        ModeMorph() {
            super(modeButtons.body.w + UI_PADDING * 2, 0);
            body.setSize(100, 100);
            dragBar.w = body.w - UI_PADDING * 2;
            windowTitle = "Morph";
            //...
        }

        void draw(PGraphics canvas) {
            super.draw(canvas);
            canvas.pushMatrix();
            canvas.translate(body.x, body.y);
            //...
            canvas.popMatrix();
        }

        String mouse() {
            if (super.mouse() != "") return "dragging";
            //...
            return "";
        }
    } //end ModeMorph

} //end LightLattice
