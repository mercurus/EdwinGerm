/**
* Bouncing balls
*/
class Ricochet implements Kid {
    Arena[] arenas;
    Album ballAlbum, portalAlbum, bgdAlbum;
    boolean play, reloadAlbum;
    float pace;
    final float ROTATION_SPEED = TWO_PI / 10000.0;
    final int BALLS_PER_ARENA = 4,
    HEX_RADIUS = 220,
    PORTAL_RADIUS = 15; //changing this won't change the sprite size...
    HashMap<String, Integer> colorMap;

    Ricochet() {
        int pad = 10;
        arenas = new Arena[4];
        arenas[0] = new Arena(HEX_RADIUS + pad, HEX_RADIUS + pad, true, "Blue", new int[] { 2, -1, 3, -1, 1, -1 });
        arenas[1] = new Arena(HEX_RADIUS * 3, HEX_RADIUS + pad, false, "Red", new int[] { 2, -1, 0, -1, 3, -1 });
        arenas[2] = new Arena(HEX_RADIUS + pad, HEX_RADIUS * 3, false, "Green", new int[] { -1, 0, -1, 1, -1, 3 });
        arenas[3] = new Arena(HEX_RADIUS * 3, HEX_RADIUS * 3, true, "Yellow", new int[] { -1, 2, -1, 1, -1, 0 });
        ballAlbum = new Album("tiles/sweetieballs.alb"); //https://lospec.com/palette-list/sweetie-16
        portalAlbum = new Album("tiles/portals.alb");
        bgdAlbum = new Album("tiles/hex.alb");
        reloadAlbum = false;
        play = true;
        pace = 1.0 - (0.12 * 3);
        edwin.bgdColor = #1a1c2c;
        colorMap = new HashMap<String, Integer>();
        colorMap.put("Blue", #3b5dc9);
        colorMap.put("Red", #b13e53);
        colorMap.put("Green", #257179);
        colorMap.put("Yellow", #ef7d57);
        println("Ricochet / o \\");
    }

    void draw(PGraphics canvas) {
        //this is so I could edit the sprites and see their updates live (edit sprite with AlbumEditor > save file > press r to reload)
        if (reloadAlbum) {
            ballAlbum.reload();
            portalAlbum.reload();
            bgdAlbum.reload();
            reloadAlbum = false;
        }

        for (Arena a : arenas) {
            if (play) a.update();
            canvas.pushMatrix();
            canvas.translate(a.center.x, a.center.y);

            //hexagon shapes
            PShape hexBorder = createShape();
            hexBorder.beginShape();
            hexBorder.stroke(#333c57);
            hexBorder.strokeWeight(5);
            hexBorder.fill(#566c86);
            PShape innerHex = createShape();
            innerHex.beginShape();
            innerHex.noStroke();
            innerHex.fill(#94b0c2);
            //corners of hexagons
            for (int i = 0; i < 6; i++) {
                hexBorder.vertex(a.corners[i].x, a.corners[i].y);
                innerHex.vertex(a.insideCorners[i].x, a.insideCorners[i].y);
            }
            hexBorder.endShape(CLOSE);
            innerHex.endShape();
            canvas.shape(hexBorder, 0, 0);
            canvas.shape(innerHex, 0, 0);

            //center teleporter
            canvas.rotate(a.theta.value);
            canvas.image(bgdAlbum.page(a.definingColor), -bgdAlbum.w / 2.0, -bgdAlbum.h / 2.0);

            canvas.popMatrix();

            //portals
            for (int i = 0; i < 6; i++) {
                int portal = (int)a.portals[i].z;
                String page = (portal < 0) ? "Charger" : arenas[portal].definingColor;

                canvas.pushMatrix();
                canvas.translate(a.center.x + a.portals[i].x, a.center.y + a.portals[i].y);
                canvas.rotate(atan2(a.portals[i].y, a.portals[i].x));
                canvas.image(portalAlbum.page(page), -portalAlbum.w / 2.0, -portalAlbum.h / 2.0);
                canvas.popMatrix();
            }
        } //end for a

        //balls
        canvas.noFill();
        canvas.strokeWeight(3);
        for (Arena a : arenas) {
            for (Ball ball : a.balls) {
                //lines to ball that recently telported
                if (ball.portal != null) {
                    float opacity = (ball.lineTimer.maximum - ball.lineTimer.value) / (float)ball.lineTimer.maximum * 255;
                    canvas.stroke(colorMap.get(a.definingColor), opacity);
                    canvas.line(ball.portal.x, ball.portal.y, a.center.x + ball.pos.x, a.center.y + ball.pos.y);
                    canvas.ellipse(a.center.x + ball.pos.x, a.center.y + ball.pos.y, 35, 35);
                    if (play && ball.lineTimer.increment() == ball.lineTimer.maximum) {
                        //disable
                        ball.lineTimer.minimize();
                        ball.portal = null;
                    }
                }
                //sprite
                canvas.pushMatrix();
                canvas.translate(a.center.x + ball.pos.x, a.center.y + ball.pos.y);
                canvas.rotate(atan2(ball.vel.y, ball.vel.x));
                canvas.image(ballAlbum.page(ball.page + (ball.charged ? "Charged" : "")), -ballAlbum.w * 0.5, -ballAlbum.h * 0.5);
                canvas.popMatrix();
            }
        }
    } //end draw

    String mouse() {
        return "";
    }

    String keyboard(KeyEvent event) {
        if (event.getAction() == KeyEvent.RELEASE) {
            int kc = event.getKeyCode();
            if (kc == Keycodes.R) reloadAlbum = true;
            else if (kc == Keycodes.P) play = !play;
            else if (kc == Keycodes.ONE) pace = 0.52; 
            else if (kc == Keycodes.TWO) pace = 0.64; 
            else if (kc == Keycodes.THREE) pace = 0.76; 
            else if (kc == Keycodes.FOUR) pace = 0.88; 
            else if (kc == Keycodes.FIVE) pace = 1.0; 
            else if (kc == Keycodes.SIX) pace = 1.12; 
            else if (kc == Keycodes.SEVEN) pace = 1.24; 
            else if (kc == Keycodes.EIGHT) pace = 1.36; 
            else if (kc == Keycodes.NINE) pace = 1.48; 
            else if (kc == Keycodes.ZERO) pace = 0.0; 
        }
        return "";
    }

    private class Ball {
        PVector pos, vel, acc, oldPos, portal;
        BoundedInt lineTimer;
        float radius, mass, simTimeRemaining;
        boolean charged;
        String page; //in the album

        Ball() { this(""); }
        Ball(String page) {
            this.page = page;
            pos = PVector.random2D().mult(10);
            vel = PVector.random2D().mult(10);
            acc = new PVector(0, 0);
            oldPos = new PVector(0, 0);
            portal = null;
            lineTimer = new BoundedInt(35);
            charged = true;
            //make constants?
            mass = 4;
            radius = 10;
        }
    }

    //hexagon
    private class Arena {
        PVector center;
        PVector[] corners, portals, insideCorners;
        ArrayList<Ball> balls;
        BoundedFloat theta;
        int gravity;
        String definingColor;
        static final float SIXTH_OF_CIRCLE = TWO_PI / 6.0;

        Arena(float x, float y, boolean clockwise, String definingColor, int[] portals) {
            if (portals.length != 6) throw new IllegalArgumentException("It's a hexagon and needs 6 items");
            center = new PVector(x, y);
            this.definingColor = definingColor;
            this.portals = new PVector[6];
            corners = new PVector[6];
            insideCorners = new PVector[6];
            //just initialize, the actual positions get calculated in update()
            for (int i = 0; i < 6; i++) {
                corners[i] = new PVector(0, 0);
                insideCorners[i] = new PVector(0, 0);
                this.portals[i] = new PVector(0, 0, portals[i]);
            }

            balls = new ArrayList<Ball>();
            for (int i = 0; i < BALLS_PER_ARENA; i++) {
                balls.add(new Ball(definingColor));
            }

            if (clockwise) theta = new BoundedFloat(0, TWO_PI, 0, ROTATION_SPEED);
            else theta = new BoundedFloat(0, TWO_PI, HALF_PI, -ROTATION_SPEED);
            theta.loops = true;

            gravity = 555 * (clockwise ? 1 : -1);
        }

        void update() {
            float spokeAngle = theta.increment();
            float cosA, sinA;
            for (int i = 0; i < 6; i++) {
                cosA = cos(spokeAngle);
                sinA = sin(spokeAngle);
                corners[i].set(cosA * HEX_RADIUS, sinA * HEX_RADIUS);
                insideCorners[i].set(cosA * HEX_RADIUS * 0.77, sinA * HEX_RADIUS * 0.77);
                portals[i].set(cosA * (HEX_RADIUS - PORTAL_RADIUS - 10), sinA * (HEX_RADIUS - PORTAL_RADIUS - 10), portals[i].z);
                spokeAngle += SIXTH_OF_CIRCLE; //next spoke
            }

            //Big thanks to Javidx9 (OneLoneCoder)
            //the ball physics code is ripped straight from:
            //https://github.com/OneLoneCoder/videos/blob/master/OneLoneCoder_Balls2.cpp
            //https://www.youtube.com/watch?v=LPzyNOHY3A4
            //https://www.youtube.com/watch?v=ebq7L2Wtbl4
            ArrayList<Pair<Ball, Ball>> collidingPairs = new ArrayList<Pair<Ball, Ball>>();
            ArrayList<Ball> toRemove = new ArrayList<Ball>();

            // Multiple simulation updates with small time steps permit more accurate physics
            // and realistic results at the expense of CPU time of course
            int nSimulationUpdates = 4;

            // Multiple collision trees require more steps to resolve. Normally we would
            // continue simulation until the object has no simulation time left for this
            // epoch, however this is risky as the system may never find stability, so we
            // can clamp it here
            int nMaxSimulationSteps = 8;

            // Break up the frame elapsed time into smaller deltas for each simulation update
            float simElapsedTime = edwin.elapsedTime / (float)nSimulationUpdates * pace; //mess with this to affect play speed

            //check if any ball hits a portal or is outside the bounds
            for (Ball ball : balls) {
                //see if it's outside bounds
                if (ball.pos.x < -HEX_RADIUS 
                || ball.pos.y < -HEX_RADIUS
                || ball.pos.x > HEX_RADIUS
                || ball.pos.y > HEX_RADIUS) {
                    ball.portal = center.copy().add(ball.pos);
                    ball.pos.set(0, 0);
                    ball.vel.set(PVector.random2D().mult(10));
                    //println("reset");
                    continue;
                }
                //check for teleport
                for (int p = 0; p < portals.length; p++) {
                    if (doCirclesOverlap(ball.pos.x, ball.pos.y, ball.radius, portals[p].x, portals[p].y, PORTAL_RADIUS - 3)) {
                        int a = (int)portals[p].z;
                        if (a < 0) {
                            ball.charged = true;
                            break;
                        }
                        arenas[a].balls.add(ball);
                        toRemove.add(ball);
                        ball.pos.set(0, 0);
                        ball.portal = center.copy().add(portals[p]);
                        ball.lineTimer.minimize();
                        // ball.charged = true;
                    }
                }
            }
            //clear out balls that teleported to another arena
            for (Ball ball : toRemove) {
                balls.remove(ball);
            }

            // Main simulation loop
            for (int i = 0; i < nSimulationUpdates; i++) {
                for (Ball ball : balls) {
                    // Set all balls time to maximum for this epoch
                    ball.simTimeRemaining = simElapsedTime;
                }
                // Erode simulation time on a per object basis, depending upon what happens
                // to it during its journey through this epoch
                for (int j = 0; j < nMaxSimulationSteps; j++) {
                    // Update Ball Positions
                    for (Ball ball : balls) {
                        if (ball.simTimeRemaining > 0.0f) {
                            // Store original position this epoch
                            ball.oldPos.set(ball.pos); 
                            //wind drag and gravity
                            ball.acc.set(-ball.vel.x * 0.1, -ball.vel.y * 0.75 + gravity); 
                            //add acceleration to velocity
                            ball.vel.add(ball.acc.copy().mult(ball.simTimeRemaining));                             
                            //max speed
                            // if (ball.vel.mag() > 700) {
                            //     ball.vel.setMag(500); 
                            //     println("maxed out");
                            // }
                            //add velocity to position
                            ball.pos.add(ball.vel.copy().mult(ball.simTimeRemaining));
                            // Stop ball when velocity is neglible
                            // if (ball.vel.x*ball.vel.x + ball.vel.y*ball.vel.y < 0.5) {
                            //     ball.vel.set(0, 0);
                            // }
                        }
                    }


                    // Work out static collisions with walls and displace balls so no overlaps
                    for (Ball ball : balls) {
                        // float fDeltaTime = ball.simTimeRemaining;

                        // Against Edges
                        int lastC = 5;
                        for (int c = 0; c < 6; c++) {
                            // Check that line formed by velocity vector, intersects with line segment
                            PVector start = corners[c];
                            PVector end = corners[lastC];
                            lastC = c;

                            float fLineX1 = end.x - start.x;
                            float fLineY1 = end.y - start.y;

                            float fLineX2 = ball.pos.x - start.x;
                            float fLineY2 = ball.pos.y - start.y;

                            float fEdgeLength = fLineX1 * fLineX1 + fLineY1 * fLineY1;

                            // This is nifty - It uses the DP of the line segment vs the line to the object, to work out
                            // how much of the segment is in the "shadow" of the object vector. The min and max clamp
                            // this to lie between 0 and the line segment length, which is then normalised. We can
                            // use this to calculate the closest point on the line segment
                            float t = max(0, min(fEdgeLength, (fLineX1 * fLineX2 + fLineY1 * fLineY2))) / fEdgeLength;

                            // Which we do here
                            float fClosestPointX = start.x + t * fLineX1;
                            float fClosestPointY = start.y + t * fLineY1;

                            // And once we know the closest point, we can check if the ball has collided with the segment in the
                            // same way we check if two balls have collided
                            float fDistance = sqrt((ball.pos.x - fClosestPointX)*(ball.pos.x - fClosestPointX) + (ball.pos.y - fClosestPointY)*(ball.pos.y - fClosestPointY));

                            if (fDistance <= ball.radius) {
                                // Collision has occurred (with a wall) treat collision point as a ball that cannot move. To make this
                                // compatible with the dynamic resolution code below, we add a fake ball 
                                // so it behaves like a solid object when the momentum calculations are performed
                                Ball fakeball = new Ball();
                                fakeball.radius = 1;
                                fakeball.mass = ball.mass * 0.77; //cushion the impact
                                fakeball.pos.set(fClosestPointX, fClosestPointY);
                                fakeball.vel.set(-ball.vel.x, -ball.vel.y);
                                if (ball.charged) {
                                    PVector flatIncrease = new PVector(gravity, gravity).rotate(PI);
                                    // PVector bounce = new PVector(0, 0);
                                    float mag = abs(fakeball.vel.mag());
                                    if (mag < 100) {
                                        fakeball.vel.add(flatIncrease.mult(0.1)).mult(2.4);
                                        // println("< 100");
                                    }
                                    else if (mag < 200) {
                                        fakeball.vel.add(flatIncrease.mult(0.05)).mult(2.2);
                                        // println("< 200");
                                    }
                                    else if (mag < 300) {
                                        fakeball.vel.add(flatIncrease.mult(0.025)).mult(2.0);
                                        // println("< 300");
                                    }
                                    else {
                                        fakeball.vel.mult(1.6);
                                        // println("else " + mag + "" + fakeball.vel.toString());
                                    }
                                    ball.charged = false;
                                }
                                
                                // Add collision to vector of collisions for dynamic resolution
                                collidingPairs.add(new Pair<Ball, Ball>(ball, fakeball));

                                // Calculate displacement required
                                float fOverlap = fDistance - ball.radius - fakeball.radius;

                                // Displace Current Ball away from collision
                                ball.pos.x -= fOverlap * (ball.pos.x - fakeball.pos.x) / fDistance;
                                ball.pos.y -= fOverlap * (ball.pos.y - fakeball.pos.y) / fDistance;
                            }
                        }

                        // Against other balls
                        for (Ball target : balls) {
                            if (ball == target) continue; // Do not check against self
                            
                            if (doBallsOverlap(ball, target)) {
                                // Collision has occured
                                collidingPairs.add(new Pair<Ball, Ball>(ball, target));

                                // Distance between ball centers
                                float fDistance = sqrt((ball.pos.x - target.pos.x)*(ball.pos.x - target.pos.x) + (ball.pos.y - target.pos.y)*(ball.pos.y - target.pos.y));

                                // Calculate displacement required
                                float fOverlap = 0.5f * (fDistance - ball.radius - target.radius);

                                // Displace Current Ball away from collision
                                ball.pos.x -= fOverlap * (ball.pos.x - target.pos.x) / fDistance;
                                ball.pos.y -= fOverlap * (ball.pos.y - target.pos.y) / fDistance;

                                // Displace Target Ball away from collision - Note, this should affect the timing of the target ball
                                // and it does, but this is absorbed by the target ball calculating its own time delta later on
                                target.pos.x += fOverlap * (ball.pos.x - target.pos.x) / fDistance;
                                target.pos.y += fOverlap * (ball.pos.y - target.pos.y) / fDistance;
                            }
                            
                        }

                        // Time displacement - we knew the velocity of the ball, so we can estimate the distance it should have covered
                        // however due to collisions it could not do the full distance, so we look at the actual distance to the collision
                        // point and calculate how much time that journey would have taken using the speed of the object. Therefore
                        // we can now work out how much time remains in that timestep.
                        float fIntendedSpeed    = sqrt(ball.vel.x * ball.vel.x + ball.vel.y * ball.vel.y);
                        float fIntendedDistance = fIntendedSpeed * ball.simTimeRemaining;
                        float fActualDistance   = sqrt((ball.pos.x - ball.oldPos.x)*(ball.pos.x - ball.oldPos.x) + (ball.pos.y - ball.oldPos.y)*(ball.pos.y - ball.oldPos.y));
                        float fActualTime = fActualDistance / fIntendedSpeed;

                        // After static resolution, there may be some time still left for this epoch, so allow simulation to continue
                        ball.simTimeRemaining = ball.simTimeRemaining - fActualTime;
                    }

                    // Now work out dynamic collisions
                    float fEfficiency = 1.00f;
                    float tMag = 150; //threshold magnitude
                    for (Pair<Ball, Ball> pair : collidingPairs) {
                        Ball b1 = pair.one;
                        Ball b2 = pair.two;

                        // Distance between balls
                        float fDistance = sqrt((b1.pos.x - b2.pos.x)*(b1.pos.x - b2.pos.x) + (b1.pos.y - b2.pos.y)*(b1.pos.y - b2.pos.y));

                        // Normal
                        float nx = (b2.pos.x - b1.pos.x) / fDistance;
                        float ny = (b2.pos.y - b1.pos.y) / fDistance;

                        // Tangent
                        float tx = -ny;
                        float ty = nx;

                        // Dot Product Tangent
                        float dpTan1 = b1.vel.x * tx + b1.vel.y * ty;
                        float dpTan2 = b2.vel.x * tx + b2.vel.y * ty;

                        // Dot Product Normal
                        float dpNorm1 = b1.vel.x * nx + b1.vel.y * ny;
                        float dpNorm2 = b2.vel.x * nx + b2.vel.y * ny;

                        // Conservation of momentum in 1D
                        float m1 = fEfficiency * (dpNorm1 * (b1.mass - b2.mass) + 2.0f * b2.mass * dpNorm2) / (b1.mass + b2.mass);
                        float m2 = fEfficiency * (dpNorm2 * (b2.mass - b1.mass) + 2.0f * b1.mass * dpNorm1) / (b1.mass + b2.mass);

                        // Update ball velocities
                        b1.vel.x = tx * dpTan1 + nx * m1;
                        b1.vel.y = ty * dpTan1 + ny * m1;
                        b2.vel.x = tx * dpTan2 + nx * m2;
                        b2.vel.y = ty * dpTan2 + ny * m2;

                        float mult1, mag1 = b1.vel.mag();
                        float mult2, mag2 = b2.vel.mag();
                        if (b1.charged && b2.charged) {
                            mult1 = (mag1 < tMag ? 2.0 : 1.6);
                            mult2 = (mag2 < tMag ? 2.0 : 1.6);
                            b1.vel.mult(mult1);
                            b2.vel.mult(mult2);
                            b1.charged = b2.charged = false;
                        }
                        else if (b1.charged) {
                            mult1 = (mag1 < tMag ? 1.6 : 1.3);
                            mult2 = (mag2 < tMag ? 1.1 : 1.05);
                            b1.vel.mult(mult1);
                            b2.vel.mult(mult2);
                            b1.charged = false;
                        }
                        else if (b2.charged) {
                            mult1 = (mag1 < tMag ? 1.1 : 1.05);
                            mult2 = (mag2 < tMag ? 1.6 : 1.3);
                            b1.vel.mult(mult1);
                            b2.vel.mult(mult2);
                            b2.charged = false;
                        }
                    }

                    // Remove all collisions
                    collidingPairs.clear();
                } //end j
            } //end i
        } //end update()

        boolean doBallsOverlap(Ball first, Ball second) { 
            return doCirclesOverlap(first.pos.x, first.pos.y, first.radius, second.pos.x, second.pos.y, second.radius); 
        }

        boolean doCirclesOverlap(float x1, float y1, float r1, float x2, float y2, float r2) {
            return ((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2)) <= ((r1 + r2) * (r1 + r2));
        }
    } //end Arena
} //end Ricochet


class Pair<X, Y> {
    final X one;
    final Y two;
    Pair(X one, Y two) {
        this.one = one;
        this.two = two;
    }
}
