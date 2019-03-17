module Model exposing (Model,InitialValue, Game, Msg(..), postSubmit, initFromValue)

import RemoteData exposing (WebData)
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder, Value)
import Http

type Msg
    = Submit String String
    | SubmitCompleted (WebData Game)
    | Test String


type alias Model =
    { name : String
    , gameId : String
    , submitData : WebData Game
    }

type alias Game =
  { name: String
  , player: String
  , score: Int
  }

type alias InitialValue =
    {
        gameId : String
    }


initFromValue : InitialValue -> ( Model, Cmd Msg )
initFromValue { gameId }  =
  ({gameId = gameId, name = "", submitData = RemoteData.NotAsked }, Cmd.none )

-- type alias InitialValue =
--     { gameId : String }

-- decodeFlags : Value -> InitialValue
-- decodeFlags value =
--     value
--         |> Json.Decode.decodeValue decoder
--         |> Result.withDefault { gameId = "FAILED" }

-- decoder : Decoder InitialValue
-- decoder =
--   Json.Decode.map InitialValue
--     (Json.Decode.field "gameId" Json.Decode.string)

-- encoder : String -> Body
-- encoder inputValue =
--     [ ( "content", Json.Encode.string inputValue ) ]
--         |> Json.Encode.object
--         |> Http.jsonBody
---- UPDATE ----





postSubmit : String -> String -> String -> Cmd Msg
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
        , ( "total", Encode.string total )
        ]

    body =
        Http.jsonBody <|
              Encode.object
                  [ ( "query", Encode.string mutation )
                  , ( "operationName", Encode.string "NewScore" )
                  , ( "variables", Encode.object variables )
                  ]

    gameDecoder =
        Decode.map3 Game
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