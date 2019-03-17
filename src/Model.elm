module Model exposing (InitialValue, Model, Msg(..), Score, initFromValue, postSubmit)

import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import RemoteData exposing (WebData)


type Msg
    = Submit
    | SubmitCompleted (WebData Score)
    | NameUpdated String


type alias Model =
    { name : String
    , gameId : String
    , submitData : WebData Score
    }


type alias Score =
    { gameName : String
    , playerName : String
    , score : Int
    }


type alias InitialValue =
    { gameId : String
    }


initFromValue : InitialValue -> ( Model, Cmd Msg )
initFromValue { gameId } =
    ( { gameId = gameId, name = "", submitData = RemoteData.NotAsked }, Cmd.none )


postSubmit : String -> String -> Int -> Cmd Msg
postSubmit gameId playerName total =
    let
        mutation =
            """
      mutation NewScore($gameId: ID!, $name: String!, $total: Int!) {
        submit(game_id: $gameId, name: $name, total: $total) {
          game { name }
          player { name }
          total
        }
      }
      """

        variables =
            [ ( "gameId", Encode.string gameId )
            , ( "name", Encode.string playerName )
            , ( "total", Encode.int total )
            ]

        body =
            Http.jsonBody <|
                Encode.object
                    [ ( "query", Encode.string mutation )
                    , ( "operationName", Encode.string "NewScore" )
                    , ( "variables", Encode.object variables )
                    ]

        gameDecoder =
            Decode.map3 Score
                (Decode.at [ "submit", "game", "name" ] Decode.string)
                (Decode.at [ "submit", "player", "name" ] Decode.string)
                (Decode.at [ "submit", "total" ] Decode.int)

        decoder =
            Decode.oneOf
                [ Decode.at [ "data" ] gameDecoder
                , Decode.fail "expecting data"
                ]
    in
    Http.post
        { url = "http://localhost:4000/api"
        , body = body
        , expect = Http.expectJson (RemoteData.fromResult >> SubmitCompleted) decoder
        }
