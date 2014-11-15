package utils;

class GridPosition {
  static public function positionInGrid<T>(widthHeightRatio : Float, gridWidth : Float, gridHeight : Float, elements :Array<T>, apply : T -> Float -> Float -> Float -> Float -> Void, center = false) {
    // Set positions
    var numY = 1;
    var numX = 1;
    gridWidth *= widthHeightRatio;
    for (totalCount in 0...elements.length) {
      if (numX * numY <= totalCount) {
        // How much space would be there for every dice?
        var wouldSpaceX = gridWidth / (numX+1);
        var wouldSpaceY = gridHeight / (numY+1);
        if (wouldSpaceX < wouldSpaceY) {
          numY += 1;
        } else {
          numX += 1;
        }
      }
    }
    // Make array for the numX
    var numX_array = new Array<Int>();
    for (i in 0...numY) {
      numX_array[i] = numX;
    }
    // Reduct numX array until the size is correct
    var missingElements = numX * numY - elements.length;
    while (missingElements >= numY) {
      for (i in 0...numY) {
        numX_array[i] -= 1;
      }
      missingElements -= numY;
    }
    for (i in 0...missingElements) {
      numX_array[numY - i -1] -= 1;
    }

    // Find out the scale
    var spaceX = gridWidth / (numX+0.5);
    var spaceY = gridHeight / (numY+0.5);
    var dim = Math.min(spaceX,spaceY);

    var i = 0;
    for (y in 0...numY) {
      for (x in 0...numX_array[y]) {
        if (i >= elements.length) {
          break;
        }
        var xPos = 0.0;
        var yPos = 0.0;
        if (center) {
          xPos = (gridWidth - numX_array[y] * dim) / 2.0 + x * dim + dim/2.0;
          yPos = (gridHeight - numY * dim) / 2.0 + y * dim + dim/2.0;
        } else {
          xPos = gridWidth / (2* numX_array[y] ) * (2 * x + 1);
          yPos = gridHeight / (2* numY ) * (2 * y + 1);
        }
        apply(elements[i],
              xPos,
              yPos,
              dim,
              dim);

        ++i;
      }
    }
  }
}
