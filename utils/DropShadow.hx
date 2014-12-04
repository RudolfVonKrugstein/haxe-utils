package utils;

import tink.core.Pair;
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

  // Creates an array of the positions of the corners
  public function createCornerPositions() : Array<Pair<Float,Float>> {
    var result : Array<Pair<Float,Float>> = [];
    result.push(new Pair(x_start, y_start));
    for (side in sides) {
      var last = result[result.length-1];
      switch(side) {
      case UP(dist):
        result.push(new Pair(last.a, last.b - dist));
      case RIGHT(dist):
        result.push(new Pair(last.a + dist, last.b));
      case DOWN(dist):
        result.push(new Pair(last.a, last.b + dist));
      case LEFT(dist):
        result.push(new Pair(last.a - dist, last.b));
      }
    }
    // Since the last one should be the first as the first ...
    result.pop();
    return result;
  }

  // Creates it from the positions of the corners
  // This always assumes, that the smaller if the x and y distance
  // between 2 corners is 0.
  public static function createFromCornerPositions(pos : Array<Pair<Float, Float>>) {
    var result = new AAPolygon(pos[pos.length-1].a, pos[pos.length-1].b);
    var last = pos[pos.length-1];
    for (corner in pos) {
      if (Math.abs(corner.a - last.a) > Math.abs(corner.b - last.b)) {
        if (corner.a > last.a) {
          result.sides.push(RIGHT(corner.a-last.a));
        } else {
          result.sides.push(LEFT(last.a-corner.a));
        }
      } else {
        if (corner.b > last.b) {
          result.sides.push(DOWN(corner.b-last.b));
        } else {
          result.sides.push(UP(last.b-corner.b));
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
      var x = corners[i].a;
      var y = corners[i].b;
      var dir = sides[i];
      // Inset given by last dir ...
      switch(lastDir) {
      case UP(_):    x -= amount;
      case RIGHT(_): y += amount;
      case DOWN(_):  x += amount;
      case LEFT(_):  y -= amount;
      }
      // Do inset by current dir, only of it differs to the lastDir
      if (Type.enumIndex(lastDir) != Type.enumIndex(dir)) {
        switch(dir) {
        case UP(_):    x -= amount;
        case RIGHT(_): y += amount;
        case DOWN(_):  x += amount;
        case LEFT(_):  y -= amount;
        }
      }

      insetCorners.push(new Pair(x,y));
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
    // Calculate the hard shadow polygon
    //var innerPolygon = polygon.inset(softSize/2.0);
    /*innerPolygon.x_start += xOffset;
    innerPolygon.y_start += yOffset;*/
    var innerPolygon = polygon.copy();

    graphics.lineStyle();
    // Draw the soft shadow
    var alphas = [alpha,alpha,0.0];
    var colors = [color,color,color];
    var radius = softSize + corners;
    var fractions = [0.0,255.0 * corners / radius,255.0];

    /*if (innerShadow) {
      // The shadow is drawn around hardRect, for an inner shadow we shrink hardRect by the size of the shadow
      alphas.reverse();
      fractions = [0.0, 255 * softSize/radius, 255.0];
      hardRect.x += softSize;
      hardRect.y += softSize;
      hardRect.width -= 2 * softSize;
      hardRect.height -= 2 * softSize;
    }*/

    function drawCornerShadow(drawPos : Point, gradientCenter : Point) {
      var matrix = new flash.geom.Matrix();
      matrix.createGradientBox(radius * 2,radius * 2,0.0,gradientCenter.x-radius, gradientCenter.y-radius);
      graphics.beginGradientFill(flash.display.GradientType.RADIAL, colors, alphas, fractions, matrix);
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

    // Returns if 2 adjacent sides form an inner corner
    function innerCorner(side1 : AADirectionStep, side2 : AADirectionStep) {
      if (side1 == RIGHT(0.0) && side2 == DOWN(0.0)) {
        return true;
      }
      if (side1 == DOWN(0.0) && side2 == LEFT(0.0)) {
        return true;
      }
      if (side1 == LEFT(0.0) && side2 == UP(0.0)) {
        return true;
      }
      if (side1 == UP(0.0) && side2 == RIGHT(0.0)) {
        return true;
      }
      return false;
    }

    var curPos_x : Float = polygon.x_start;
    var curPos_y : Float = polygon.y_start;
    for (i in 0...innerPolygon.sides.length) {
      var lastSide = innerPolygon.sides[(i-1) % innerPolygon.sides.length];
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
      var drawPos_x = nextPos_x;
      var drawPos_y = nextPos_y;
      
      switch(curSide) {
      case UP(dist):
      case RIGHT(dist):
      case DOWN(dist): drawPos_x = nextPos_x - softSize;
      case LEFT(dist): drawPos_y = nextPos_y - softSize;
      }
      switch(nextSide) {
      case UP(dist):
      case RIGHT(dist):
      case DOWN(dist): drawPos_x = nextPos_x - softSize;
      case LEFT(dist): drawPos_y = nextPos_y - softSize;
      }
      drawCornerShadow(new Point(drawPos_x, drawPos_y), new Point(nextPos_x, nextPos_y));

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
