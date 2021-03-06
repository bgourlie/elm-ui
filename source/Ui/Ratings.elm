module Ui.Ratings exposing
  (Model, Msg, init, subscribe, update, view, render, setValue, valueAsStars)

{-| A simple star rating component.

# Model
@docs Model, Msg, init, subscribe, update

# View
@docs view, render

# Functions
@docs setValue, valueAsStars
-}

import Ext.Number exposing (roundTo)
import Array

import Html.Events exposing (onClick, onMouseEnter, onMouseLeave)
import Html.Attributes exposing (classList)
import Html.Events.Extra exposing (onKeys)
import Html exposing (node)
import Html.Lazy


import Ui.Helpers.Emitter as Emitter
import Ui.Native.Uid as Uid
import Ui


{-| Representation of a ratings component:
  - **hoverValue** - The transient value of the component
  - **clearable** - Whether or not the component is clearable
  - **disabled** - Whether or not the component is disabled
  - **readonly** - Whether or not the component is readonly
  - **value** - The current value of the component (0..1)
  - **uid** - The unique identifier of the input
  - **size** - The number of starts to display
-}
type alias Model =
  { hoverValue : Float
  , clearable : Bool
  , disabled : Bool
  , readonly : Bool
  , value : Float
  , uid : String
  , size : Int
  }


{-| Messages that a ratings component can receive.
-}
type Msg
  = MouseEnter Int
  | MouseLeave
  | Increment
  | Decrement
  | Click Int


{-| Initializes a ratings component with the given number of stars and initial
value.

    -- 1 out of 10 star rating
    ratings = Ui.Ratings.init 10 0.1
-}
init : Int -> Float -> Model
init size value =
  { hoverValue = value
  , uid = Uid.uid ()
  , clearable = False
  , disabled = False
  , readonly = False
  , value = value
  , size = size
  }


{-| Subscribe to the changes of a ratings components.

    ...
    subscriptions =
      \model -> Ui.Ratings.subscribe RatingsChanged model.ratings
    ...
-}
subscribe : (Float -> msg) -> Model -> Sub msg
subscribe msg model =
  Emitter.listenFloat model.uid msg


{-| Updates a ratings component.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    MouseEnter index ->
      ( { model | hoverValue = calculateValue index model }, Cmd.none )

    MouseLeave ->
      ( { model | hoverValue = model.value }, Cmd.none )

    Increment ->
      setAndSendValue (clamp 0 1 (model.value + (1 / (toFloat model.size)))) model

    Decrement ->
      let
        oneStarValue =
          1 / (toFloat model.size)

        min =
          if model.clearable then
            0
          else
            oneStarValue
      in
        setAndSendValue (clamp oneStarValue 1 (model.value - oneStarValue)) model

    Click index ->
      setAndSendValue (calculateValue index model) model


{-| Lazily renders a ratings component.

    Ui.Ratings.view ratings
-}
view : Model -> Html.Html Msg
view model =
  Html.Lazy.lazy render model


{-| Renders a ratings component.

    Ui.Ratings.render ratings
-}
render : Model -> Html.Html Msg
render model =
  let
    actions =
      Ui.enabledActions
        model
        [ onKeys
            [ ( 40, Decrement )
            , ( 38, Increment )
            , ( 37, Decrement )
            , ( 39, Increment )
            ]
        ]

    stars =
      Array.initialize model.size ((+) 1)
        |> Array.toList
  in
    node
      "ui-ratings"
      ([ classList
          [ ( "disabled", model.disabled )
          , ( "readonly", model.readonly )
          ]
       ]
        ++ (Ui.tabIndex model)
        ++ actions
      )
      (List.map (renderStar model) stars)


{-| Sets the value of a ratings component.

    Ui.Ratings.setValue 8 ratings
-}
setValue : Float -> Model -> Model
setValue value' model =
  let
    value =
      roundTo 2 value'
  in
    if
      model.value
        == value
        && model.hoverValue
        == value
    then
      model
    else
      { model
        | value = value
        , hoverValue = value
      }


{-| Returns the value of a ratings component as number of stars.

    Ui.NumberRange.valueAsStars 10 ratings
-}
valueAsStars : Float -> Model -> Int
valueAsStars value model =
  round (value * (toFloat model.size))



----------------------------------- PRIVATE ------------------------------------


{-| Sets the given value and sends it to the value address.
-}
setAndSendValue : Float -> Model -> ( Model, Cmd Msg )
setAndSendValue value model =
  let
    updatedModel =
      setValue value model
  in
    if model.value == updatedModel.value then
      ( model, Cmd.none )
    else
      ( updatedModel, sendValue updatedModel )


{-| Sends the value to the value address as an effect.
-}
sendValue : Model -> Cmd Msg
sendValue model =
  Emitter.sendFloat model.uid model.value


{-| Calculates the value for the given star (index).
-}
calculateValue : Int -> Model -> Float
calculateValue index model =
  let
    value =
      clamp 0 1 ((toFloat index) / (toFloat model.size))

    currentIndex =
      valueAsStars model.value model
  in
    if currentIndex == index && model.clearable then
      0
    else
      value


{-| Renders a individual star.
-}
renderStar : Model -> Int -> Html.Html Msg
renderStar model index =
  let
    actions =
      Ui.enabledActions
        model
        [ onClick (Click index)
        , onMouseEnter (MouseEnter index)
        , onMouseLeave MouseLeave
        ]

    class =
      if ((toFloat index) / (toFloat model.size)) <= model.hoverValue then
        "ui-ratings-full"
      else
        "ui-ratings-empty"
  in
    node
      "ui-ratings-star"
      ([ classList [ ( class, True ) ]
       ]
        ++ actions
      )
      []
