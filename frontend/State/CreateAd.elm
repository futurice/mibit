module State.CreateAd exposing (..)

import State.Util exposing (SendingStatus(..))

type alias Model =
  { heading : String
  , content : String
  , sending : SendingStatus
  }

init : Model
init =
  { heading = ""
  , content = ""
  , sending = NotSending
  }