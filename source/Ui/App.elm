module Ui.App
  (Model, Action(..), init, update, view) where

{-| Base frame for a web/mobile application:
  - Loads the stylesheet
  - Sets up a click handler
  - Sets the viewport to be mobile friendly

# Model
@docs Model, Action, update, init

# View
@docs view
-}
import Html.Attributes exposing (name, content, style)
import Html.Events exposing (onClick)
import Html.Extra exposing (onScroll)
import Html exposing (node, text)
import Html.Lazy

import Ui

{-| Representation of an application. -}
type alias Model =
  { loaded: Bool
  , title: String
  }

{-| Actions an application can make:
  - **Clicked** - Dispatched when a click is made
  - **Loaded** - Dispatched when the stylesheet is loaded
-}
type Action
  = Clicked
  | Loaded
  | Scrolled

{-| Initializes an application. -}
init : String -> Model
init title =
  { loaded = False
  , title = title
  }

{-| Updates an application. -}
update : Action -> Model -> Model
update action model =
  case action of
    Loaded ->
      { model | loaded = True }
    _ ->
      model

{-| Renders an application.

    view address []
      [text "Hello there!"]
-}
view: Signal.Address Action -> Model -> List Html.Html -> Html.Html
view address model children =
  Html.Lazy.lazy3 render address model children

-- Render (Internal)
render : Signal.Address Action -> Model -> List Html.Html -> Html.Html
render address model children =
  node "ui-app" [ onClick address Clicked
                , onScroll address Scrolled
                , style [("opacity", if model.loaded then "1" else "0")
                        ,("display", "block")]
                ]
    ([ Ui.stylesheetLink "main.css" address Loaded
     , node "title" [] [text model.title]
     , node "meta" [ name "viewport"
                   , content "initial-scale=1.0, user-scalable=no"] []
     ] ++ children)