module Expr where

import Graphics.Element exposing (Element)
import Pic exposing (Pic, pic)
import Dim exposing (..)
import PicLike exposing (..)
import Text exposing (Text)
import App exposing (App)
import Reactive exposing (Reactive, Event(..), reactive)
import Color
import Expr.LitInt as LitInt

type Expr
  = Hole
  | OptionsList
  | Plus
  | Apply Expr (List Expr)
  | LitInt LitInt.Model

initApply : Expr
initApply = Apply Hole [Hole]

defaultText : String -> Pic
defaultText = scale pic 3 << Pic.text << Text.fromString

viewExpr : Expr -> Reactive Expr
viewExpr expr =
  case expr of
    Hole -> viewHole
    OptionsList -> viewOptionsList
    Plus -> Reactive.static (defaultText "add")
    Apply func args -> viewApply func args
    LitInt model -> Reactive.alwaysForwardMessage LitInt (LitInt.view model)

viewHole : Reactive Expr
viewHole =
  let
    radius = 20
    asPic = Pic.outlined (Pic.solid Color.darkGrey) <| Pic.rectFromDim <| Pic.squareDim radius
   in
    Reactive.onFingerDown (always <| Just OptionsList) <| Reactive.static asPic

viewOptionsList : Reactive Expr
viewOptionsList =
  let
    addApplication =
      Reactive.onFingerDown (always <| Just (Apply Hole [Hole]))
        (Reactive.static (defaultText "Application"))
    addInteger =
      Reactive.onFingerDown (always <| Just (LitInt (LitInt.fromInt 0)))
        (Reactive.static (defaultText "Integer"))
    addPlus =
      Reactive.onFingerDown (always <| Just Plus)
        (Reactive.static (defaultText "Plus"))
   in
    centered reactive
      (appendTo reactive Down
        (empty reactive)
        [ addApplication
        , addInteger
        , addPlus
        ])

viewApply : Expr -> List Expr -> Reactive Expr
viewApply func args =
  let
    reactFunc newFunc = Apply newFunc args
    replaceIndex index list replacement =
      List.indexedMap
        (\idx listElem -> if idx == index then replacement else listElem)
        list
    createArg index expr =
      Reactive.alwaysForwardMessage (Apply func << replaceIndex index args)
      <| Reactive.padded 4 <| viewExpr expr

    leftParens = Reactive.static (defaultText "(")
    rightParens = Reactive.static (defaultText ")")

    parens react =
      nextTo reactive Left (nextTo reactive Right react rightParens) leftParens

    plusButton =
      Reactive.onFingerDown (always <| Just <| Apply func (args ++ [Hole]))
        <| Reactive.static (atop pic (Pic.outlined (Pic.solid Color.green) (Pic.rectFromDim (Pic.squareDim 20))) (defaultText "+"))
   in
    centered reactive
      (parens
        (appendTo reactive Right
          (Reactive.padded 4 <| Reactive.alwaysForwardMessage reactFunc <| viewExpr func)
          ([Reactive.static (Pic.vgap 10)] ++ List.indexedMap createArg args ++ [plusButton])))


evaluate : Expr -> Pic
evaluate expr =
  case evaluateValue expr of
    Nothing -> defaultText "contains Error"
    Just value -> defaultText (toString value)

type ExprValue
  = IntValue Int
  | PlusFunc

evaluateValue : Expr -> Maybe ExprValue
evaluateValue expr =
  let
    getIntValue expr =
      case evaluateValue expr of
        Just (IntValue i) -> Just i
        otherwise -> Nothing
    allJust list =
      case list of
        [] -> Just []
        (Just x :: xs) ->
          case allJust xs of
            Just ls -> Just (x :: ls)
            Nothing -> Nothing
        otherwise -> Nothing
   in
    case expr of
      LitInt { intValue } -> Just (IntValue intValue)
      Apply func args ->
        case evaluateValue func of
          Just PlusFunc ->
            case allJust (List.map getIntValue args) of
              Just ints -> Just (IntValue (List.sum ints))
              otherwise -> Nothing
          otherwise -> Nothing
      Plus -> Just PlusFunc
      otherwise -> Nothing

view : Expr -> Reactive Expr
view expr =
  appendTo reactive Down (viewExpr expr)
    [ Reactive.static <| Pic.padded 10 <| Pic.filled Color.darkGrey <| Pic.rectFromDim (Dim -300 1 300 -1)
    , Reactive.static <| evaluate expr
    ]


main : Signal Element
main = App.run
  { init = Hole
  , update = always -- one does not simply "need update"
  , view = view
  }
