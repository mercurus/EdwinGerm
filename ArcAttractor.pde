/**
* 
*/
class ArcAttractor implements Kid {
    Section[] sections;
    final XY center = new XY(width * 0.5, height * 0.5);
    
    ArcAttractor() { this(6); }
    ArcAttractor(int numSections) {
        numSections = max(numSections, 1);
        float angleIncrement = TWO_PI / (float)numSections;
        float offset = numSections * 0.005; //creates a gap in between sections so edges don't bump into each other
        offset = 0; //or not
        
        // int[] colors = new int[] { EdColors.DX_YELLOW_ORANGE, EdColors.DX_RED, EdColors.DX_GREEN, EdColors.DX_YELLOW, EdColors.DX_CLAY, EdColors.DX_BLUE };
        sections = new Section[numSections];
        int colr = color(255 * 0.2, 255 * 0.2, 255 * 0.2);
        for (int i = 0; i < sections.length; i++) {
            sections[i] = new Section(angleIncrement * i + offset, angleIncrement * (i + 1) - offset, 9, colr, i); //colors[i]
        }
    }

    void draw(PGraphics canvas) {
        canvas.noFill();
        // canvas.strokeCap(SQUARE);
        canvas.strokeWeight(32);

        for (Section section : sections) {
            section.draw(canvas); //seems easier to keep the draw logic within the class
        }
    }

    String mouse() {
        return "";
    }

    String keyboard(KeyEvent event) {
        return "";
    }

    private class Section {
        BoundedFloat angleBounds;
        BoundedFloat[] tracerPositions;
        float[] arcLengths, tracerLengths;
        float totalPathLength, tierLength;
        int colr;

        Section(float angleStart, float angleEnd, int numTiers, int colr, int index) {
            this.colr = colr;
            angleBounds = new BoundedFloat(angleStart, angleEnd);
            totalPathLength = 0;

            float radius, circumference;
            float maxRadius = max(width, height) * 0.6;
            float sectionAngle = angleEnd - angleStart;
            tierLength = maxRadius / (float)numTiers;
            arcLengths = new float[numTiers];
            for (int i = 0; i < numTiers; i++) {
                radius = tierLength * (numTiers - i);
                circumference = TWO_PI * radius;
                arcLengths[i] = (sectionAngle / TWO_PI) * circumference;
                totalPathLength += arcLengths[i] + tierLength;
            }

            int numTracers = 4;
            float tracerLen = 350, speed = 2.5, start = 0;
            float partialLen = (totalPathLength + tracerLen) / (numTracers * 2);
            tracerPositions = new BoundedFloat[numTracers];
            tracerLengths = new float[numTracers];
            for (int i = 0; i < numTracers; i++) {
                start = -tracerLen + (i * partialLen * 2) + partialLen * (index % 2);
                tracerPositions[i] = new BoundedFloat(-tracerLen, totalPathLength, start, speed, true);
                tracerLengths[i] = tracerLen; //these don't all need to be the same length...
            }
        }

        void draw(PGraphics canvas) {
            canvas.stroke(colr);
            boolean isEven;
            float back, front, currentPos, endPos, currentRadius;

            for (int t = 0; t < tracerPositions.length; t++) {
                //end points of the tracer
                back = tracerPositions[t].increment();
                front = back + tracerLengths[t];
                //var for tracking where we are on the path
                currentPos = 0;

                //loop through each tier and draw relevant portions of arc and line
                for (int i = 0; i < arcLengths.length; i++) {
                    if (front < currentPos) break; //leave early if we know there's nothing left to draw
                    currentRadius = tierLength * (arcLengths.length - i);
                    isEven = (i % 2 == 0);
                    endPos = currentPos + arcLengths[i];
                    
                    //determine arc
                    if (back <= endPos && front >= currentPos) {
                        float angle1 = 0, angle2 = 0;

                        if (back < currentPos) { //arc starts at beginning
                            if (isEven) angle1 = angleBounds.minimum;
                            else angle2 = angleBounds.maximum;
                        }
                        else { //partial arc starts after beginning
                            if (isEven) angle1 = angleBounds.minimum + arcAngle(currentRadius, back - currentPos);
                            else angle2 = angleBounds.maximum - arcAngle(currentRadius, back - currentPos);
                        }

                        if (front > endPos) { //arc stops at end
                            if (isEven) angle2 = angleBounds.maximum;
                            else angle1 = angleBounds.minimum;
                        }
                        else { //partial arc stops before end
                            if (isEven) angle2 = angleBounds.maximum - arcAngle(currentRadius, endPos - front);
                            else angle1 = angleBounds.minimum + arcAngle(currentRadius, endPos - front);
                        }

                        //draw
                        canvas.arc(
                            center.x, center.y, 
                            currentRadius * 2, currentRadius * 2, 
                            angle1, angle2
                        );
                    }

                    currentPos += arcLengths[i]; //add length of arc
                    endPos = currentPos + tierLength;

                    //determine line
                    if (back <= endPos && front >= currentPos) {
                        float angle = (isEven ? angleBounds.maximum : angleBounds.minimum);
                        float radius1 = 0, radius2 = 0;

                        if (back < currentPos) { //line starts at beginning
                            radius1 = currentRadius;
                        }
                        else { //partial line starts after beginning
                            radius1 = currentRadius - (back - currentPos);
                        }

                        if (front > endPos) { //line stops at end
                            radius2 = currentRadius - tierLength;
                        }
                        else { //partial line stops before end
                            radius2 = currentRadius - tierLength + (endPos - front);
                        }

                        //draw
                        canvas.line(
                            center.x + cos(angle) * radius1, 
                            center.y + sin(angle) * radius1, 
                            center.x + cos(angle) * radius2, 
                            center.y + sin(angle) * radius2
                        );
                    }

                    currentPos += tierLength; //add length of line
                } //for i
            } //for t

        }

        float arcAngle(float radius, float arcLen) {
            float circumference = TWO_PI * radius;
            // float arcLength = (angleFromCenter / TWO_PI) * circumference;
            float angle = arcLen / circumference * TWO_PI;
            return angle;
        }
    }

}
