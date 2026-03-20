import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute.{class}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model.{
  type Message, UserConfirmsAction, UserCreatesACard, UserDeletesACard,
  UserGoesBack, UserModifiesACard, UserModifiesCard, UserTypesCard,
}
import objects.{type Card}

pub fn view_card_management(cards: List(Card)) -> Element(Message) {
  html.div([class("p-8 flex flex-col gap-4")], [
    html.div(
      [class("flex flex-col gap-2")],
      list.map(cards, fn(card) {
        html.div(
          [
            class(
              "flex items-center justify-between p-4 bg-white rounded-lg shadow",
            ),
          ],
          [
            html.div([class("flex flex-col gap-1")], [
              html.p([class("font-sans font-medium")], [
                html.text(card.question),
              ]),
              html.p([class("text-gray-500 text-sm")], [html.text(card.answer)]),
              html.p([class("text-gray-400 text-xs")], [
                html.text(
                  "Score: "
                  <> int.to_string(card.score)
                  <> "  hit "
                  <> int.to_string(card.times_correct)
                  <> "  miss "
                  <> int.to_string(card.times_wrong),
                ),
              ]),
            ]),
            html.div([class("flex gap-2")], [
              html.button(
                [
                  class(
                    "px-4 py-2 bg-cyan-500 text-white rounded hover:bg-cyan-600",
                  ),
                  event.on_click(UserModifiesACard(card.id)),
                ],
                [html.text("Modify")],
              ),
              html.button(
                [
                  class(
                    "px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600",
                  ),
                  event.on_click(UserDeletesACard(card.id)),
                ],
                [html.text("Delete")],
              ),
            ]),
          ],
        )
      }),
    ),
    html.button(
      [
        class(
          "mt-4 px-6 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600",
        ),
        event.on_click(UserCreatesACard),
      ],
      [html.text("Create a card")],
    ),
    html.button(
      [
        class("px-6 py-3 bg-gray-300 rounded-lg hover:bg-gray-400"),
        event.on_click(UserGoesBack),
      ],
      [html.text("Go home")],
    ),
  ])
}

pub fn view_card_creation(
  question: String,
  answer: String,
  score: Option(Int),
) -> Element(Message) {
  html.div([class("p-8 flex flex-col gap-6 max-w-xl mx-auto")], [
    html.div([class("flex flex-col gap-2")], [
      html.label([class("text-gray-700 font-medium")], [html.text("Question")]),
      html.input([
        class("p-3 border border-gray-300 rounded-lg w-full"),
        attribute.type_("text"),
        attribute.value(question),
        attribute.placeholder("Write your question here..."),
        event.on_input(fn(q) { UserTypesCard(q, answer, score) }),
      ]),
    ]),
    html.div([class("flex flex-col gap-2")], [
      html.label([class("text-gray-700 font-medium")], [html.text("Answer")]),
      html.input([
        class("p-3 border border-gray-300 rounded-lg w-full"),
        attribute.type_("text"),
        attribute.value(answer),
        attribute.placeholder("Write your answer here..."),
        event.on_input(fn(a) { UserTypesCard(question, a, score) }),
      ]),
    ]),
    html.div([class("flex flex-col gap-2")], [
      html.label([class("text-gray-700 font-medium")], [
        html.text("Score (optional)"),
      ]),
      html.input([
        class("p-3 border border-gray-300 rounded-lg w-full"),
        attribute.type_("number"),
        attribute.value(case score {
          Some(s) -> int.to_string(s)
          None -> ""
        }),
        attribute.placeholder("0"),
        event.on_input(fn(s) {
          case int.parse(s) {
            Ok(n) -> UserTypesCard(question, answer, Some(n))
            Error(_) -> UserTypesCard(question, answer, None)
          }
        }),
      ]),
    ]),
    html.div([class("flex gap-4 mt-4")], [
      html.button(
        [
          class(
            "px-6 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600 disabled:opacity-50",
          ),
          event.on_click(UserConfirmsAction),
          attribute.disabled(question == "" || answer == ""),
        ],
        [html.text("Create card")],
      ),
      html.button(
        [
          class("px-6 py-3 bg-gray-300 rounded-lg hover:bg-gray-400"),
          event.on_click(UserGoesBack),
        ],
        [html.text("Cancel")],
      ),
    ]),
  ])
}

pub fn view_card_modifying(
  question: Option(String),
  answer: Option(String),
  score: Option(Int),
) -> Element(Message) {
  html.div([class("p-8 flex flex-col gap-6 max-w-xl mx-auto")], [
    html.p([class("text-gray-400 text-sm")], [
      html.text("Leave a field empty to keep the current value."),
    ]),
    html.div([class("flex flex-col gap-2")], [
      html.label([class("text-gray-700 font-medium")], [
        html.text("New question"),
      ]),
      html.input([
        class("p-3 border border-gray-300 rounded-lg w-full"),
        attribute.type_("text"),
        attribute.value(option.unwrap(question, "")),
        attribute.placeholder("Leave empty to keep current..."),
        event.on_input(fn(q) {
          UserModifiesCard(
            case q {
              "" -> None
              _ -> Some(q)
            },
            answer,
            score,
          )
        }),
      ]),
    ]),
    html.div([class("flex flex-col gap-2")], [
      html.label([class("text-gray-700 font-medium")], [html.text("New answer")]),
      html.input([
        class("p-3 border border-gray-300 rounded-lg w-full"),
        attribute.type_("text"),
        attribute.value(option.unwrap(answer, "")),
        attribute.placeholder("Leave empty to keep current..."),
        event.on_input(fn(a) {
          UserModifiesCard(
            question,
            case a {
              "" -> None
              _ -> Some(a)
            },
            score,
          )
        }),
      ]),
    ]),
    html.div([class("flex flex-col gap-2")], [
      html.label([class("text-gray-700 font-medium")], [html.text("New score")]),
      html.input([
        class("p-3 border border-gray-300 rounded-lg w-full"),
        attribute.type_("number"),
        attribute.value(case score {
          Some(s) -> int.to_string(s)
          None -> ""
        }),
        attribute.placeholder("Leave empty to keep current..."),
        event.on_input(fn(s) {
          UserModifiesCard(question, answer, case int.parse(s) {
            Ok(n) -> Some(n)
            Error(_) -> None
          })
        }),
      ]),
    ]),
    html.div([class("flex gap-4 mt-4")], [
      html.button(
        [
          class("px-6 py-3 bg-cyan-500 text-white rounded-lg hover:bg-cyan-600"),
          event.on_click(UserConfirmsAction),
        ],
        [html.text("Save changes")],
      ),
      html.button(
        [
          class("px-6 py-3 bg-gray-300 rounded-lg hover:bg-gray-400"),
          event.on_click(UserGoesBack),
        ],
        [html.text("Cancel")],
      ),
    ]),
  ])
}

pub fn view_card_deleting(cards: List(Card), card_id: Int) -> Element(Message) {
  let card = list.find(cards, fn(c) { c.id == card_id })
  html.div([class("p-8 flex flex-col items-center gap-6 max-w-xl mx-auto")], [
    html.div([class("text-6xl")], [html.text("Deleting")]),
    html.h2([class("text-2xl font-sans text-center")], [
      html.text("Are you sure you want to delete this card?"),
    ]),
    case card {
      Ok(c) ->
        html.div(
          [class("p-4 bg-white rounded-lg shadow w-full flex flex-col gap-1")],
          [
            html.p([class("font-medium")], [html.text(c.question)]),
            html.p([class("text-gray-500 text-sm")], [html.text(c.answer)]),
            html.p([class("text-gray-400 text-xs")], [
              html.text("Score: " <> int.to_string(c.score)),
            ]),
          ],
        )
      Error(_) ->
        html.p([class("text-gray-400")], [
          html.text("Card #" <> int.to_string(card_id)),
        ])
    },
    html.p([class("text-red-500 text-sm text-center")], [
      html.text("This will also remove the card from all decks it belongs to."),
    ]),
    html.div([class("flex gap-4")], [
      html.button(
        [
          class("px-6 py-3 bg-red-500 text-white rounded-lg hover:bg-red-600"),
          event.on_click(UserConfirmsAction),
        ],
        [html.text("Yes, delete it")],
      ),
      html.button(
        [
          class("px-6 py-3 bg-gray-300 rounded-lg hover:bg-gray-400"),
          event.on_click(UserGoesBack),
        ],
        [html.text("Cancel")],
      ),
    ]),
  ])
}
