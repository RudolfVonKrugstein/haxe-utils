package utils;
class DropShadow {
  public var rect : flash.geom.Rectangle;
  public var xOffset : Float = 0.0;
  public var yOffset : Float = 0.0;
  public var softSize : Float = 0.0;
  public var alpha : Float = 0.2;
  public var corners : Float = 0.0;
  public var fill : Bool = false;
  public var innerShadow : Bool = false;
  public var color : Int = 0;
  public function new() {
    rect = new flash.geom.Rectangle();
  }

  public function draw(graphics : flash.display.Graphics) {
    var hardRect = new flash.geom.Rectangle(rect.x + xOffset, rect.y + yOffset, rect.width, rect.height);
    graphics.lineStyle();
    // Draw the soft shadow
    var alphas = [alpha,alpha,0.0];
    var colors = [color,color,color];
    var radius = softSize + corners;
    var fractions = [0.0,255.0 * corners / radius,255.0];

    if (innerShadow) {
      // The shadow is drawn around hardRect, for an inner shadow we shrink hardRect by the size of the shadow
      alphas.reverse();
      fractions = [0.0, 255 * softSize/radius, 255.0];
      hardRect.x += softSize;
      hardRect.y += softSize;
      hardRect.width -= 2 * softSize;
      hardRect.height -= 2 * softSize;
    }


    function drawCornerShadow(drawPos : flash.geom.Point, gradientCenter : flash.geom.Point) {
      var matrix = new flash.geom.Matrix();
      matrix.createGradientBox(radius * 2,radius * 2,0.0,gradientCenter.x-radius, gradientCenter.y-radius);
      graphics.beginGradientFill(flash.display.GradientType.RADIAL, colors, alphas, fractions, matrix);
      graphics.drawRect(drawPos.x, drawPos.y, radius, radius);
      graphics.endFill();
    }

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
    );

    function drawSideShadow(drawRect : flash.geom.Rectangle, rotation : Float) {
      var matrix = new flash.geom.Matrix();
      matrix.createGradientBox(drawRect.width, drawRect.height, rotation, drawRect.left, drawRect.top);
      graphics.beginGradientFill(flash.display.GradientType.LINEAR, colors, alphas, fractions, matrix);
      graphics.drawRect(drawRect.left, drawRect.top, drawRect.width, drawRect.height);
      graphics.endFill();
    }
    // Top gradient
    drawSideShadow(new flash.geom.Rectangle(hardRect.left + corners, hardRect.top - softSize, hardRect.width-corners-corners, softSize + corners),-Math.PI/2.0);

    // Bottom gradient
    drawSideShadow(new flash.geom.Rectangle(hardRect.left + corners, hardRect.bottom-corners, hardRect.width-corners-corners, softSize + corners),Math.PI/2.0);

    // Left gradient
    drawSideShadow(new flash.geom.Rectangle(hardRect.left-softSize, hardRect.top+corners, softSize + corners, hardRect.height - corners -corners),Math.PI);

    // Right gradient
    drawSideShadow(new flash.geom.Rectangle(hardRect.right - corners, hardRect.top + corners, softSize + corners, hardRect.height - corners - corners),0.0);

    if (fill && !innerShadow) {
      graphics.beginFill(color, alpha);
      graphics.drawRect(hardRect.left, hardRect.top, hardRect.width, hardRect.height);
      graphics.endFill();
    }
  }
}
