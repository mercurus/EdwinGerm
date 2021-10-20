#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif
#define PROCESSING_TEXTURE_SHADER
#define PI 3.14159265358979323846
#define TWO_PI 6.28318530717958647692

uniform sampler2D texture; //PGraphics being worked on (screenSize dimensions) which isn't used except as a way to touch each pixel

varying vec4 vertPos; //screen space coord
// varying vec4 vertColor;
// varying vec4 vertTexCoord;

//Conway's Game of Life data encoded as pixels on a texture (not sure how to pass arrays yet...)
// uniform sampler2D asdf;
uniform int cgolData0[4800];
uniform int cgolData1[4800];
uniform int cgolData2[4800];
uniform int cgolData3[4800];
uniform int cgolData4[4800];

uniform int[] testData0;
// uniform int[] testData1;
// uniform int[] testData2;

uniform vec4 scaleColor0;
uniform vec4 scaleColor1;
uniform vec4 scaleColor2;
uniform vec4 scaleColor3;
uniform vec4 scaleColor4;
uniform vec3 emptyScaleColor;

uniform vec2 screenSize;
uniform vec2 gameSize; //dimensions of cgolData
uniform float outerRadius; //outer edge of donut
uniform float innerRadius; //inner edge of donut

void main() {
    vec2 screenCenter = vec2(screenSize.x * 0.5, screenSize.y * 0.5);
    float distanceFromCenter = length(screenCenter - vertPos.xy);
    
    // int i = cgolData0[2];

    // vec4 scaleColorx = vec4(0, 0, 0, 0);
    // int gameIndexx = int(floor(2) * gameSize.x + floor(2));
    // scaleColorx += scaleColor0 * cgolData0[gameIndexx];
    // scaleColorx += scaleColor1 * cgolData1[gameIndexx];
    // scaleColorx += scaleColor2 * cgolData2[gameIndexx];
    // scaleColorx += scaleColor3 * cgolData3[gameIndexx];
    // scaleColorx += scaleColor4 * cgolData4[gameIndexx];

    //if we're outside the donut, render nothing
    if (distanceFromCenter < innerRadius || distanceFromCenter > outerRadius) {
        gl_FragColor = vec4(0, 0, 0, 0); 
        return; //exit early
    }

    if (cgolData0[0] == 1) {
        gl_FragColor = vec4(1, 1, 0, 1); 
        return; //exit early
    }

    // if (testData0.length() == 4800) {
    //     gl_FragColor = vec4(1, 0, 1, 1); 
    //     return; //exit early
    // }
    // if (testData1[100] == 0) {
    //     gl_FragColor = vec4(1, 0, 1, 1); 
    //     return; //exit early
    // }
    // if (testData2[100] == 0) {
    //     gl_FragColor = vec4(1, 0, 1, 1); 
    //     return; //exit early
    // }

    //determine game pixel from screen coordinate
    vec2 cellSize = vec2(0, (outerRadius - innerRadius) / gameSize.y); //width is calculated using circumference
    vec2 adjustedPos = vertPos.xy - screenCenter;
    float adjustedY = length(adjustedPos) - innerRadius; //y position relative to inner radius
    float yIndex = adjustedY / cellSize.y;

    float circumference = TWO_PI * (innerRadius + yIndex * cellSize.y);
    cellSize.x = circumference / gameSize.x;

    float angleFromCenter = atan(adjustedPos.y, adjustedPos.x) + PI; //atan returns between -PI and PI
    float arcLength = (angleFromCenter / TWO_PI) * circumference;
    float xIndex = (arcLength / circumference) * gameSize.x;

    //extract pixel from game state(s)
    // vec2 textureUV = vec2(floor(xIndex) / gameSize.x, floor(yIndex) / gameSize.y);
    // vec2 textureUV = vec2(xIndex / gameSize.x, yIndex / gameSize.y);
    // vec4 gameState; //either white or black
    // float m = 0.05; //margin? helps keep the "live" color from spilling into neighbors because my calculations are imperfect?

    //if sampled cell is alive, add in color value
    // gameState = texture(cgolData0, textureUV); 
    // scaleColor += scaleColor0 * round(gameState.r - m);
    vec4 scaleColor = vec4(0, 0, 0, 0);
    int gameIndex = int(floor(yIndex) * gameSize.x + floor(xIndex));
    // int i0 = cgolData0[gameIndex];
    // int i1 = cgolData1[gameIndex];
    // int i2 = cgolData2[gameIndex];
    // int i3 = cgolData3[gameIndex];
    // int i4 = cgolData4[gameIndex];
    scaleColor += scaleColor0 * cgolData0[gameIndex];
    scaleColor += scaleColor1 * cgolData1[gameIndex];
    scaleColor += scaleColor2 * cgolData2[gameIndex];
    scaleColor += scaleColor3 * cgolData3[gameIndex];
    scaleColor += scaleColor4 * cgolData4[gameIndex];

    // gameState = texture(cgolData1, textureUV); 
    // scaleColor += scaleColor1 * round(gameState.r - m);

    // gameState = texture(cgolData2, textureUV); 
    // scaleColor += scaleColor2 * round(gameState.r - m);

    // gameState = texture(cgolData3, textureUV); 
    // scaleColor += scaleColor3 * round(gameState.r - m);

    // gameState = texture(cgolData4, textureUV); 
    // scaleColor += scaleColor4 * round(gameState.r - m); 

    //blend sampled colors
    scaleColor /= max(round(scaleColor.a), 1); //max 1 to guard against divide-by-zero?

    //identify center point of the cell
    float angleIncrement = TWO_PI / gameSize.x;
    float angleToCellCenter = (angleIncrement * floor(xIndex)) + (angleIncrement * 0.5) + PI;
    float radiusToCellCenter = innerRadius + (cellSize.y * floor(yIndex)) + (cellSize.y * 0.5);
    vec2 cellCenter = screenCenter + vec2(cos(angleToCellCenter), sin(angleToCellCenter)) * radiusToCellCenter;
    float offset = (yIndex * 0.32) + (gameSize.y - yIndex) * 0.16; //trial and error value related to cell size...

    //check to see if screen pixel is within cell/circle/scale bounds
    if (length(cellCenter - vertPos.xy) < cellSize.x - offset) { 
        if (scaleColor.a > 0.1) { //if sampled color shows cell is alive
            gl_FragColor = scaleColor;
        }
        else {
            gl_FragColor = vec4(emptyScaleColor, 1);
        }
    }
    else {
        // gl_FragColor = vec4(serpentBodyColor, 1); 
        gl_FragColor = vec4(0, 0, 0, 0); //transparent
    }

} //end main()
