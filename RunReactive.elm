module RunReactive where

import Graphics.Element exposing (Element)
import Reactive exposing (Reactive, Event(..))
import Pic exposing (Pic)
import Window
import Mouse

runReactive
  : model -- initial model
  -> (message -> model -> model) -- update function
  -> (model -> Reactive message) -- view function
  -> Signal Element
runReactive model update view =
  let
    -- updateState : model -> (model, Reactive message)
    updateState newModel =
      (newModel, view newModel)

    -- updateReactive : Event -> (model, Reactive message) -> (model, Reactive message)
    updateReactive event (model, reactive) =
      case reactive.reaction event of
        Just message ->
          updateState (update message model)

        Nothing ->
          (model, reactive)

    -- makeElement : (Int, Int) -> (model, Reactive message) -> Element
    makeElement size (_, { visual }) =
      Pic.toElement size visual
  in
    Signal.map2 makeElement Window.dimensions
    <| Signal.foldp updateReactive (model, view model) (mouseClicks Window.dimensions)


mouseClicks : Signal (Int, Int) -> Signal Event
mouseClicks size =
  let clickPos = Signal.sampleOn Mouse.clicks Mouse.position
      fixedClickPos = Signal.map2 fixMouse Window.dimensions clickPos
      mouseClicks = Signal.map MouseClick fixedClickPos
   in mouseClicks


fixMouse : (Int, Int) -> (Int, Int) -> (Float, Float)
fixMouse (w, h) (x, y) =
  (toFloat x - toFloat w / 2, toFloat -y + toFloat h / 2)
