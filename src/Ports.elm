port module Ports exposing (newScore)

import Json.Decode as Decode


port newScore : (Int -> msg) -> Sub msg
