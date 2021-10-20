/*
* Sigil for the motivation and inspiration to create generative art
*/
class GSigil implements Kid {
    XY origin;
    PShape[] polys;

    GSigil() { this(15); }
    GSigil(float unitLength) { this(width - (5 * unitLength), unitLength, unitLength); }
    GSigil(float x, float y, float unitLength) {
        origin = new XY(x, y);
        polys = new PShape[6 * 2];
        define(unitLength);
    }

    void define(float unit) {
        unit = max(unit, 3);
        for (int i = 0; i < polys.length; i++) {
            polys[i] = createShape();
            polys[i].beginShape();
            polys[i].noFill();
            polys[i].stroke(i < 6 ? EdColors.DX_DARK_BLUE : EdColors.DX_BLUE);
            polys[i].strokeWeight(i < 6 ? 3 : 1);
        }

        for (int i = 0; i <= 6; i += 6) {
            //top left
            polys[i+0].vertex(unit*1, unit*0);
            polys[i+0].vertex(unit*1, unit*1);
            polys[i+0].vertex(unit*0, unit*2);
            polys[i+0].vertex(unit*0, unit*1);
            
            //left
            polys[i+1].vertex(unit*0, unit*2);
            polys[i+1].vertex(unit*1, unit*3);
            polys[i+1].vertex(unit*1, unit*5);
            polys[i+1].vertex(unit*0, unit*4);
            
            //bottom
            polys[i+2].vertex(unit*1, unit*5);
            polys[i+2].vertex(unit*1, unit*6);
            polys[i+2].vertex(unit*2, unit*8);
            polys[i+2].vertex(unit*3, unit*6);
            polys[i+2].vertex(unit*3, unit*5);
            polys[i+2].vertex(unit*2, unit*6);
            
            //right
            polys[i+3].vertex(unit*4, unit*2);
            polys[i+3].vertex(unit*4, unit*4);
            polys[i+3].vertex(unit*3, unit*5);
            polys[i+3].vertex(unit*3, unit*3);

            //top right
            polys[i+4].vertex(unit*3, unit*0);
            polys[i+4].vertex(unit*3, unit*1);
            polys[i+4].vertex(unit*4, unit*2);
            polys[i+4].vertex(unit*4, unit*1);

            //top
            polys[i+5].vertex(unit*2, unit*0);
            polys[i+5].vertex(unit*3, unit*2);
            polys[i+5].vertex(unit*2, unit*3);
            polys[i+5].vertex(unit*1, unit*2);
        }

        for (int i = 0; i < polys.length; i++) {
            polys[i].endShape(CLOSE);
        }
    }

    void draw(PGraphics canvas) {
        canvas.pushMatrix();
        canvas.translate(origin.x, origin.y);
        for (int i = 0; i < polys.length; i++) {
            canvas.shape(polys[i]);
        }
        canvas.popMatrix();
    }

    String mouse() {
        return "";
    }

    String keyboard(KeyEvent event) {
        return "";
    }
}