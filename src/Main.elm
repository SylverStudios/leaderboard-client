module Main exposing (main)

import Browser
import Debug
import Html exposing (Html, button, div, input, text)
import Html.Events exposing (onClick, onInput)
import Http exposing (Body, Error(..))
import Json.Decode exposing (Decoder, Value)
import Json.Encode
import Model exposing (InitialValue, Model, Msg(..), Score, initFromValue, postSubmit)
import RemoteData exposing (RemoteData(..), WebData)


apiUrl : String
apiUrl =
    "http://localhost:3004/data"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NameUpdated str ->
            ( { model | name = str }, Cmd.none )

        Submit ->
            ( { model | submitData = RemoteData.Loading }
            , postSubmit model.gameId model.name 4
            )

        SubmitCompleted result ->
            ( { model | submitData = result }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text (Debug.toString model.name) ]
        , input [ onInput NameUpdated ] []
        , button [ onClick Submit ] [ text "Submit!" ]
        , submitResults model.submitData
        ]


submitResults : WebData Score -> Html msg
submitResults data =
    case data of
        NotAsked ->
            text ""

        Loading ->
            text "Loading…"

        Failure err ->
            text ("Error: " ++ httpErrorString err)

        Success { gameName, playerName, score } ->
            div []
                [ text "OMG IT WORKED!"
                , text <| "Remember the name: " ++ playerName
                , text <| "because I just score a " ++ String.fromInt score ++ " in " ++ gameName
                ]


httpErrorString : Http.Error -> String
httpErrorString error =
    case error of
        BadUrl text ->
            "Bad Url: " ++ text

        Timeout ->
            "Http Timeout"

        NetworkError ->
            "Network Error"

        BadStatus code ->
            "Bad Http Status: " ++ String.fromInt code

        BadBody text ->
            "Bad body: " ++ text



---- PROGRAM ----


main : Program InitialValue Model Msg
main =
    Browser.element
        { view = view
        , init = initFromValue
        , update = update
        , subscriptions = \_ -> Sub.none
        }
