import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import lustre_http
import model.{
  type Message, DBConfirmed, DBGaveTheCard, DBGaveTheCards, DBGaveTheDeck,
  DBGaveTheDecks,
}
import objects.{Card, Deck}

fn card_decoder() {
  use id <- decode.field("id", decode.int)
  use question <- decode.field("question", decode.string)
  use answer <- decode.field("answer", decode.string)
  use score <- decode.field("score", decode.int)
  use times_correct <- decode.field("times_correct", decode.int)
  use times_wrong <- decode.field("times_wrong", decode.int)
  decode.success(Card(id, question, answer, score, times_correct, times_wrong))
}

fn deck_decoder() {
  use id <- decode.field("id", decode.int)
  use title <- decode.field("title", decode.string)
  use cnt <- decode.field("cnt", decode.int)
  use total <- decode.field("total", decode.int)
  decode.success(Deck(id, title, cnt, total))
}

fn message_decoder() {
  use message <- decode.field("message", decode.string)
  decode.success(message)
}

fn send_json(method, url, body, expect) {
  let assert Ok(req) = request.to(url)
  let req =
    req
    |> request.set_method(method)
    |> request.set_body(body)
    |> request.set_header("content-type", "application/json")
  lustre_http.send(req, expect)
}

pub fn get_cards() -> Effect(Message) {
  lustre_http.get(
    "http://localhost:5000/cards",
    lustre_http.expect_json(decode.list(card_decoder()), DBGaveTheCards),
  )
}

pub fn get_card(card_id: Int) -> Effect(Message) {
  lustre_http.get(
    "http://localhost:5000/cards/" <> int.to_string(card_id),
    lustre_http.expect_json(card_decoder(), DBGaveTheCard),
  )
}

pub fn create_card(
  question: String,
  answer: String,
  score: Int,
) -> Effect(Message) {
  json.object([
    #("question", json.string(question)),
    #("answer", json.string(answer)),
    #("score", json.int(score)),
  ])
  |> json.to_string
  lustre_http.post(
    "http://localhost:5000/cards",
    json.object([
      #("question", json.string(question)),
      #("answer", json.string(answer)),
      #("score", json.int(score)),
    ]),
    lustre_http.expect_json(message_decoder(), DBConfirmed),
  )
}

pub fn modify_card(
  card_id: Int,
  question: Option(String),
  answer: Option(String),
  score: Option(Int),
) -> Effect(Message) {
  let body =
    case question {
      Some(q) -> {
        case answer {
          Some(a) -> {
            case score {
              Some(s) ->
                json.object([
                  #("question", json.string(q)),
                  #("answer", json.string(a)),
                  #("score", json.int(s)),
                ])
              None ->
                json.object([
                  #("question", json.string(q)),
                  #("answer", json.string(a)),
                ])
            }
          }
          None -> {
            case score {
              Some(s) ->
                json.object([
                  #("question", json.string(q)),
                  #("score", json.int(s)),
                ])
              None ->
                json.object([
                  #("question", json.string(q)),
                ])
            }
          }
        }
      }
      None -> {
        case answer {
          Some(a) -> {
            case score {
              Some(s) ->
                json.object([
                  #("answer", json.string(a)),
                  #("score", json.int(s)),
                ])
              None ->
                json.object([
                  #("answer", json.string(a)),
                ])
            }
          }
          None -> {
            case score {
              Some(s) ->
                json.object([
                  #("score", json.int(s)),
                ])
              None -> json.object([])
            }
          }
        }
      }
    }
    |> json.to_string
  send_json(
    http.Put,
    "http://localhost:5000/cards/" <> int.to_string(card_id),
    body,
    lustre_http.expect_json(message_decoder(), DBConfirmed),
  )
}

pub fn delete_card(card_id: Int) -> Effect(Message) {
  send_json(
    http.Delete,
    "http://localhost:5000/cards/" <> int.to_string(card_id),
    "",
    lustre_http.expect_json(message_decoder(), DBConfirmed),
  )
}

pub fn register_answer(card_id: Int, is_correct: Bool) -> Effect(Message) {
  let body =
    json.object([#("is_correct", json.bool(is_correct))])
    |> json.to_string
  send_json(
    http.Patch,
    "http://localhost:5000/cards/" <> int.to_string(card_id),
    body,
    lustre_http.expect_json(message_decoder(), DBConfirmed),
  )
}

pub fn get_decks() -> Effect(Message) {
  lustre_http.get(
    "http://localhost:5000/decks",
    lustre_http.expect_json(decode.list(deck_decoder()), DBGaveTheDecks),
  )
}

pub fn get_deck(deck_id: Int) -> Effect(Message) {
  let decoder = {
    use deck <- decode.field("deck", deck_decoder())
    use cards <- decode.field("cards", decode.list(card_decoder()))
    decode.success(#(deck, cards))
  }
  lustre_http.get(
    "http://localhost:5000/decks/" <> int.to_string(deck_id),
    lustre_http.expect_json(decoder, DBGaveTheDeck),
  )
}

pub fn get_cards_not_from_deck(deck_id: Int) -> Effect(Message) {
  lustre_http.get(
    "http://localhost:5000/decks/" <> int.to_string(deck_id) <> "/add",
    lustre_http.expect_json(decode.list(card_decoder()), DBGaveTheCards),
  )
}

pub fn create_deck(title: String) -> Effect(Message) {
  lustre_http.post(
    "http://localhost:5000/decks",
    json.object([#("title", json.string(title))]),
    lustre_http.expect_json(message_decoder(), DBConfirmed),
  )
}

pub fn delete_deck(deck_id: Int) -> Effect(Message) {
  send_json(
    http.Delete,
    "http://localhost:5000/decks/" <> int.to_string(deck_id),
    "",
    lustre_http.expect_json(message_decoder(), DBConfirmed),
  )
}

pub fn add_card_to_deck(deck_id: Int, card_id: Int) -> Effect(Message) {
  lustre_http.post(
    "http://localhost:5000/decks/"
      <> int.to_string(deck_id)
      <> "/add/"
      <> int.to_string(card_id),
    json.object([]),
    lustre_http.expect_json(message_decoder(), DBConfirmed),
  )
}

pub fn remove_card_from_deck(deck_id: Int, card_id: Int) -> Effect(Message) {
  send_json(
    http.Delete,
    "http://localhost:5000/decks/"
      <> int.to_string(deck_id)
      <> "/"
      <> int.to_string(card_id),
    "",
    lustre_http.expect_json(message_decoder(), DBConfirmed),
  )
}
