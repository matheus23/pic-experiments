module Pic where

import Graphics.Element as E
import Graphics.Collage as C
import Text as T
import Color exposing (Color)

type alias Dim =
  { toLeft : Float
  , toTop : Float
  , toRight : Float
  , toBottom : Float
  }

type alias Pic =
  { asForm : C.Form
  , picSize : Dim
  }

type alias Shape =
  { elmShape : C.Shape
  , shapeSize : Dim
  }

type Direction = Left | Right | Up | Down

-- ABSTRACT

opposite : Direction -> Direction
opposite dir =
  case dir of
    Left -> Right
    Right -> Left
    Up -> Down
    Down -> Up

toBorderInDir : Direction -> Dim -> (Float, Float)
toBorderInDir direction box =
  case direction of
    Left -> (box.toLeft, 0)
    Right -> (box.toRight, 0)
    Up -> (0, box.toTop)
    Down -> (0, box.toBottom)


appendTo : Direction -> Pic -> List Pic -> Pic
appendTo inDirection reference pics =
  case pics of
    [] -> reference
    (pic :: picsRest) -> nextTo inDirection reference (appendTo inDirection pic picsRest)

nextTo : Direction -> Pic -> Pic -> Pic
nextTo inDirection reference picture = atop (moveNextTo inDirection reference picture) reference

moveNextTo : Direction -> Pic -> Pic -> Pic
moveNextTo inDirection reference picture =
  move (offsetNextTo inDirection reference picture) picture

offsetNextTo : Direction -> Pic -> Pic -> (Float, Float)
offsetNextTo inDirection reference picture =
  let to (a, b) (u, v) = (u - a, v - b)
      touchingPointRef = toBorderInDir inDirection reference.picSize
      touchingPointPic = toBorderInDir (opposite inDirection) picture.picSize
   in touchingPointPic `to` touchingPointRef

atopAll : List Pic -> Pic
atopAll pics =
  case pics of
    [] ->
      { asForm = C.group [], picSize = Dim 0 0 0 0 }
    (elem :: rest) ->
      atop elem (atopAll rest)

atop : Pic -> Pic -> Pic
atop picAtop picBelow =
  { asForm = C.group [ picBelow.asForm, picAtop.asForm ]
  , picSize = atopDims picAtop.picSize picBelow.picSize
  }

atopDims : Dim -> Dim -> Dim
atopDims atop below =
  { toLeft = min atop.toLeft below.toLeft
  , toTop = max atop.toTop below.toTop
  , toRight = max atop.toRight below.toRight
  , toBottom = min atop.toBottom below.toBottom
  }

liftPic : (C.Form -> C.Form) -> (Dim -> Dim) -> Pic -> Pic
liftPic mapForm mapDim picture =
  { asForm = mapForm picture.asForm
  , picSize = mapDim picture.picSize
  }

move : (Float, Float) -> Pic -> Pic
move offset = liftPic (C.move offset) (moveDim offset)

moveDim : (Float, Float) -> Dim -> Dim
moveDim (offsetx, offsety) dims =
  { toLeft = dims.toLeft + offsetx
  , toTop = dims.toTop + offsety
  , toRight = dims.toRight + offsetx
  , toBottom = dims.toBottom + offsety
  }

padded : Float -> Pic -> Pic
padded padding = liftPic identity (paddedDim padding)

paddedDim : Float -> Dim -> Dim
paddedDim padding dim =
  { toLeft = dim.toLeft - padding
  , toTop = dim.toTop + padding
  , toRight = dim.toRight + padding
  , toBottom = dim.toBottom - padding
  }

scale : Float -> Pic -> Pic
scale factor = liftPic (C.scale factor) (scaleDim factor)

scaleDim : Float -> Dim -> Dim
scaleDim factor dim =
  { toLeft = factor * dim.toLeft
  , toTop = factor * dim.toTop
  , toRight = factor * dim.toRight
  , toBottom = factor * dim.toBottom
  }

alpha : Float -> Pic -> Pic
alpha a = liftPic (C.alpha (clamp 0 1 a)) identity

withDim : Dim -> Pic -> Pic
withDim dim { asForm } = { asForm = asForm, picSize = dim }

-- "1D Vector from left side to right side"
width : Pic -> Float
width pic = pic.picSize.toRight - pic.picSize.toLeft

-- "1D Vector from bottom to top"
height : Pic -> Float
height pic = pic.picSize.toTop - pic.picSize.toBottom

-- CONCRETE

-- origin at center by default
text : T.Text -> Pic
text content =
  let asElement = E.leftAligned content
      w = toFloat (E.widthOf asElement)
      h = toFloat (E.heightOf asElement)
      textSize =
        { toLeft = -w / 2
        --, toTop = h * (1/3)
        , toTop = h * (1/2)
        , toRight = w / 2
        --, toBottom = -h * (2/3)
        , toBottom = -h * (1/2)
        }
   in { asForm = C.text content
      , picSize = textSize
      }

-- origin at center
squareDim : Float -> Dim
squareDim radius =
  { toLeft = -radius
  , toTop = radius
  , toRight = radius
  , toBottom = -radius
  }

-- origin at center
circle : Float -> Shape
circle r =
  { elmShape = C.circle r
  , shapeSize = squareDim r
  }

rectFromDim : Dim -> Shape
rectFromDim dim =
  let vertices =
        [ (dim.toLeft, dim.toTop)
        , (dim.toRight, dim.toTop)
        , (dim.toRight, dim.toBottom)
        , (dim.toLeft, dim.toBottom)
        ]
   in { elmShape = C.polygon vertices
      , shapeSize = dim
      }

filled : Color -> Shape -> Pic
filled col shape =
  { asForm = C.filled col shape.elmShape
  , picSize = shape.shapeSize
  }

outlined : C.LineStyle -> Shape -> Pic
outlined lineStyle shape =
  { asForm = C.outlined lineStyle shape.elmShape
  , picSize = shape.shapeSize
  }

solid : Color -> C.LineStyle
solid = C.solid

debugEnvelope : Pic -> Pic
debugEnvelope picture =
  (outlined (C.solid Color.red) (rectFromDim picture.picSize)) `atop` picture

toElement : (Int, Int) -> Pic -> E.Element
toElement (w, h) picture = C.collage w h [ picture.asForm ]
