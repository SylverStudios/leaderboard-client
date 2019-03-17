module Main exposing (main)

import Browser
import Debug
import Model exposing (Model, InitialValue,Msg(..), postSubmit, initFromValue)
import Html exposing (Html, button, div, input, text)
import Html.Events exposing (onClick, onInput)
import Http exposing (Body, Error)
import Json.Decode exposing (Decoder, Value)
import Json.Encode
import RemoteData
import Http



apiUrl : String
apiUrl =
    "http://localhost:3004/data"





update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Test str ->
            ( { model | name = str } , Cmd.none )

        Submit playerName total ->
          ( {model | submitData = RemoteData.Loading }
          , postSubmit model.gameId playerName total
          )

        SubmitCompleted result ->
          ( {model | submitData = result }, Cmd.none)


---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text (Debug.toString model.name) ]
        , input [ onInput Test ] []
        ]



---- PROGRAM ----


main : Program InitialValue Model Msg
main =
    Browser.element
        { view = view
        , init = initFromValue
        , update = update
        , subscriptions = \_ -> Sub.none
        }