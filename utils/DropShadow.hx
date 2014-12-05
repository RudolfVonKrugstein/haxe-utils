package utils;

import flash.geom.Rectangle;
import flash.geom.Point;

// A step in a direction
enum AADirectionStep {
  UP(dist : Float);
  RIGHT(dist : Float);
  DOWN(dist : Float);
  LEFT(dist : Float);
}

// An axis aligned polygon
// It is always assumued to be counter clockwise!
class AAPolygon {
  public function new(x : Float, y : Float) {
    x_start = x;
    y_start = y;
    sides = [];
  }
  public var x_start : Float;
  public var y_start : Float;
  public var sides : Array<AADirectionStep>;

  public function copy() : AAPolygon {
    var r = new AAPolygon(x_start, y_start);
    r.sides = sides.copy();
    return r;
  }

  public function reverse() {
    sides.reverse();
    for (i in 0...sides.length) {
      switch(sides[i]) {
      case UP(d):    sides[i] = DOWN(d);
      case RIGHT(d): sides[i] = LEFT(d);
      case DOWN(d):  sides[i] = UP(d);
      case LEFT(d):  sides[i] = RIGHT(d);
      }
    }
  }

  // Creates an array of the positions of the corners
  public function createCornerPositions() : Array<Point> {
    var result : Array<Point> = [];
    result.push(new Point(x_start, y_start));
    for (side in sides) {
      var last = result[result.length-1];
      switch(side) {
      case UP(dist):
        result.push(new Point(last.x, last.y - dist));
      case RIGHT(dist):
        result.push(new Point(last.x + dist, last.y));
      case DOWN(dist):
        result.push(new Point(last.x, last.y + dist));
      case LEFT(dist):
        result.push(new Point(last.x - dist, last.y));
      }
    }
    // Since the last one should be the first as the first ...
    result.pop();
    return result;
  }

  // Creates it from the positions of the corners
  // This always assumes, that the smaller if the x and y distance
  // between 2 corners is 0.
  public static function createFromCornerPositions(pos : Array<Point>) {
    var result = new AAPolygon(pos[0].x, pos[0].y);
    for (i in 0...pos.length) {
      var last = pos[i];
      var corner = pos[(i + 1) % pos.length];
      if (Math.abs(corner.x - last.x) > Math.abs(corner.y - last.y)) {
        if (corner.x > last.x) {
          result.sides.push(RIGHT(corner.x-last.x));
        } else {
          result.sides.push(LEFT(last.x-corner.x));
        }
      } else {
        if (corner.y > last.y) {
          result.sides.push(DOWN(corner.y-last.y));
        } else {
          result.sides.push(UP(last.y-corner.y));
        }
      }
      last = corner;
    }
    return result;
  }

  // Create a copy of it, that is inset by a given amount
  public function inset(amount : Float) : AAPolygon {
    // Create a corner version, that will be inset
    var corners = createCornerPositions();
    var insetCorners = [];
    var lastDir = sides[sides.length-1];
    for (i in 0...corners.length) {
      var x = corners[i].x;
      var y = corners[i].y;
      var dir = sides[i];
      // Inset given by last dir ...
      switch(lastDir) {
      case UP(_):    x -= amount;
      case RIGHT(_): y -= amount;
      case DOWN(_):  x += amount;
      case LEFT(_):  y += amount;
      }
      // Do inset by current dir, only of it differs to the lastDir
      if (Type.enumIndex(lastDir) != Type.enumIndex(dir)) {
        switch(dir) {
        case UP(_):    x -= amount;
        case RIGHT(_): y -= amount;
        case DOWN(_):  x += amount;
        case LEFT(_):  y += amount;
        }
      }

      insetCorners.push(new Point(x,y));
      lastDir = dir;
    }
    // Convert back to AAPolygon...
    return createFromCornerPositions(insetCorners);
  }
}


class DropShadow {
  public var polygon : AAPolygon;
  public var rect(null,set) : Rectangle;
  private function set_rect(r : Rectangle) : Rectangle {
    polygon = new AAPolygon(r.left, r.top);
    polygon.sides.push(DOWN(r.height));
    polygon.sides.push(RIGHT(r.width));
    polygon.sides.push(UP(r.height));
    polygon.sides.push(LEFT(r.width));
    return r;
  }
  public var xOffset : Float = 0.0;
  public var yOffset : Float = 0.0;
  public var softSize : Float = 0.0;
  public var alpha : Float = 0.2;
  public var corners : Float = 0.0;
  public var fill : Bool = false;
  public var innerShadow : Bool = false;
  public var color : UInt = 0;
  public function new() {
    polygon = new AAPolygon(0.0, 0.0);
  }

  public function draw(graphics : flash.display.Graphics) {

    graphics.lineStyle();
    // Draw the soft shadow
    var alphas = [alpha,alpha,0.0];
    var colors = [color,color,color];
    var radius = softSize + corners;
    var fractions = [0.0,255.0 * corners / radius,255.0];
    // Same for inner ...
    var innerAlphas = [0.0,alpha,alpha];
    var innerFractions = [0.0, 255 * softSize/radius, 255.0];

    var innerPolygon = null;
    if (innerShadow) {
      // Calculate the hard shadow polygon
      // Reverse the polygon and outset it
      innerPolygon = polygon.inset(-softSize / 2.0);
      trace("Before: " + innerPolygon.sides);
      innerPolygon.reverse();
      trace("After: " + innerPolygon.sides);
    } else {
      // Calculate the hard shadow polygon
      innerPolygon = polygon.inset(softSize / 2.0);
    }
    innerPolygon.x_start += xOffset;
    innerPolygon.y_start += yOffset;

    // Returns if 2 adjacent sides form an inner corner
    // It depends on wether this is an inner shaow ...
    function innerCorner(side1 : AADirectionStep, side2 : AADirectionStep) {
      var res : Bool = false;
      var side1i = Type.enumIndex(side1);
      var side2i = Type.enumIndex(side2);
      var righti = Type.enumIndex(RIGHT(0.0));
      var lefti = Type.enumIndex(LEFT(0.0));
      var upi = Type.enumIndex(UP(0.0));
      var downi = Type.enumIndex(DOWN(0.0));
      if (side1i == righti && side2i == downi) {
        res = true;
      }
      if (side1i == downi && side2i == lefti) {
        res = true;
      }
      if (side1i == lefti && side2i == upi) {
        res = true;
      }
      if (side1i == upi && side2i == righti) {
        res = true;
      }
      return res;
    }

    function drawCornerShadow(cornerPos : Point, curSide : AADirectionStep, nextSide : AADirectionStep) {
      var innerCorner = innerCorner(curSide, nextSide);

      // Adjust the drawPos, wich is the upper left corner of where the gradient is drawn
      var drawPos = new Point(cornerPos.x,cornerPos.y);
      switch(curSide) {
      case UP(dist):
      case RIGHT(dist):
      case DOWN(dist): drawPos.x = cornerPos.x - softSize;
      case LEFT(dist): drawPos.y = cornerPos.y - softSize;
      }
      switch(nextSide) {
      case UP(dist):
      case RIGHT(dist):
      case DOWN(dist): drawPos.x = cornerPos.x - softSize;
      case LEFT(dist): drawPos.y = cornerPos.y - softSize;
      }

      var centerPos = new Point(cornerPos.x,cornerPos.y);
      // Adjust the gradient center. If this is an not innerCorner -> it is already correct. Otherwise it must be at the opposite
      // side of the drawing rectangel.
      if (innerCorner) {
        switch(curSide) {
        case UP(dist):
          centerPos.x += softSize;
          centerPos.y += softSize;
        case RIGHT(dist):
          centerPos.x -= softSize;
          centerPos.y += softSize;
        case DOWN(dist):
          centerPos.x -= softSize;
          centerPos.y -= softSize;
        case LEFT(dist):
          centerPos.x += softSize;
          centerPos.y -= softSize;
        }
      }

      var matrix = new flash.geom.Matrix();
      var f = innerCorner?innerFractions:fractions;
      var a = innerCorner?innerAlphas:alphas;

      matrix.createGradientBox(radius * 2,radius * 2,0.0,centerPos.x-radius, centerPos.y-radius);
      graphics.beginGradientFill(flash.display.GradientType.RADIAL, colors, a, f, matrix);
      graphics.drawRect(drawPos.x, drawPos.y, radius, radius);
      graphics.endFill();
    }
    function drawSideShadow(drawRect : Rectangle, rotation : Float) {
      var matrix = new flash.geom.Matrix();
      matrix.createGradientBox(drawRect.width, drawRect.height, rotation, drawRect.left, drawRect.top);
      graphics.beginGradientFill(flash.display.GradientType.LINEAR, colors, alphas, fractions, matrix);
      graphics.drawRect(drawRect.left, drawRect.top, drawRect.width, drawRect.height);
      graphics.endFill();
    }

    var curPos_x : Float = polygon.x_start;
    var curPos_y : Float = polygon.y_start;
    for (i in 0...innerPolygon.sides.length) {
      var lastSide = innerPolygon.sides[(i-1 + innerPolygon.sides.length) % innerPolygon.sides.length];
      var curSide = innerPolygon.sides[(i) % innerPolygon.sides.length];
      var nextSide = innerPolygon.sides[(i+1) % innerPolygon.sides.length];

      // Calculate the next position
      var nextPos_x = curPos_x;
      var nextPos_y = curPos_y;
      switch(curSide) {
      case UP(dist): nextPos_y -= dist;
      case RIGHT(dist): nextPos_x += dist;
      case DOWN(dist): nextPos_y += dist;
      case LEFT(dist): nextPos_x -= dist;
      }
      // Get the reduction of the side shadow due to inner corners
      var startRed : Float = innerCorner(lastSide,curSide) ? softSize : 0.0;
      var endRed : Float = innerCorner(curSide,nextSide) ? softSize : 0.0;
      var totalRed = startRed + endRed;
      //Draw the side shadow
      trace("curSide: " + curSide);
      trace("x: " + curPos_x);
      trace("y: " + curPos_y);
      trace("startRed: " + startRed);
      trace("endRed: " + endRed);
      switch(curSide) {
      case UP(dist):
        // Draw it to the right!
        drawSideShadow(new Rectangle(curPos_x, nextPos_y + endRed, softSize, curPos_y - nextPos_y - totalRed),0.0);
      case RIGHT(dist):
        // Draw it down!
        drawSideShadow(new Rectangle(curPos_x + startRed, curPos_y, nextPos_x - curPos_x - totalRed, softSize),Math.PI/2.0);
      case DOWN(dist):
        // Draw it to the left!
        drawSideShadow(new Rectangle(curPos_x-softSize, curPos_y + startRed, softSize, nextPos_y - curPos_y - totalRed),Math.PI);
      case LEFT(dist):
        // Draw it up!
        drawSideShadow(new Rectangle(nextPos_x + endRed, nextPos_y-softSize, curPos_x - nextPos_x - totalRed, softSize),-Math.PI/2.0);
      }
      // Draw the next corner shadow
      drawCornerShadow(new Point(nextPos_x, nextPos_y), curSide, nextSide);

      // Update current pos
      curPos_x = nextPos_x;
      curPos_y = nextPos_y;
    }
    /*
    // Top, left gradient
    drawCornerShadow(new flash.geom.Point(hardRect.left-softSize,hardRect.top-softSize),
                     new flash.geom.Point(hardRect.left + corners, hardRect.top + corners)
    );
    // Top, right gradient
    drawCornerShadow(new flash.geom.Point(hardRect.right-corners,hardRect.top-softSize),
    new flash.geom.Point(hardRect.right - corners, hardRect.top + corners)
    );
    // Bottom, right gradient
    drawCornerShadow(new flash.geom.Point(hardRect.right-corners,hardRect.bottom-corners),
    new flash.geom.Point(hardRect.right-corners, hardRect.bottom - corners)
    );
    // Bottom, left gradient
    drawCornerShadow(new flash.geom.Point(hardRect.left-softSize,hardRect.bottom-corners),
    new flash.geom.Point(hardRect.left+ corners, hardRect.bottom - corners)
    );*/
  }
}
