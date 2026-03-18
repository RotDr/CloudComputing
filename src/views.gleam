import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute.{class}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model.{
  type Message, type Model, CardCreation, CardDeleting, CardManager,
  CardModifying, DeckCreation, DeckDeleting, DeckManager, DeckModifying,
  ErrorState, Quiz, Start, UserCreatesACard, UserDeletesACard, UserGoesBack,
  UserModifiesACard, UserOpensCardManagement, UserOpensDeckManagement,
}
import objects.{type Card, type Deck, type DeckCards}

pub fn view(model: Model) -> Element(Message) {
  html.div([class("min-h-screen bg-gray-50")], [
    view_header(model),
    case model {
      Start -> view_start()
      CardManager(cards) -> view_card_management(cards)
      CardModifying(card_id) -> view_not_implemented("card creation")
      CardDeleting(card_id) -> view_not_implemented("card creation")
      CardCreation -> view_not_implemented("card creation")
      DeckManager(deck) -> view_not_implemented("card creation")
      DeckModifying(deck, cards) -> view_not_implemented("card creation")
      DeckDeleting(deck_id, deck_title) -> view_not_implemented("card creation")
      DeckCreation -> view_not_implemented("card creation")
      //view_create_card()
      //view_modify_card(id)
      //view_delete_card(id)
      //view_create_deck()
      //view_modify_deck(id)
      //view_deck_management()
      //view_delete_deck(id)
      Quiz -> view_not_implemented("quiz time")
      ErrorState(e, m) -> view_error(e, m)
    },
  ])
}

fn get_title(model: Model) -> String {
  case model {
    Start -> "FlashCard Manager"
    CardCreation -> "Create Card"
    CardModifying(_) -> "Modify Card"
    CardManager(_) -> "Cards List"
    CardDeleting(_) -> "Delete Card"
    DeckCreation -> "Create Deck"
    DeckModifying(_, _) -> "Deck"
    DeckManager(_) -> "Decks List"
    DeckDeleting(_, _) -> "Delete Deck"
    Quiz -> "Quiz Time"
    ErrorState(code, _) -> "Error " <> int.to_string(code)
  }
}

fn view_header(model: Model) -> Element(Message) {
  let title = get_title(model)
  html.header([class("p-4 bg-cyan-500 text-black")], [
    html.h1([class("text-4xl font-sans")], [html.text(title)]),
  ])
}

fn view_start() -> Element(Message) {
  html.div([class("flex flex-col items-center gap-6 mt-16")], [
    html.h2([class("text-2xl font-sans")], [
      html.text("Welcome to FlashCard Manager"),
    ]),
    html.div([class("flex gap-4")], [
      html.button(
        [
          class("px-6 py-3 bg-cyan-500 text-white rounded-lg hover:bg-cyan-600"),
          event.on_click(UserOpensCardManagement),
        ],
        [html.text("Manage Cards")],
      ),
      html.button(
        [
          class("px-6 py-3 bg-cyan-500 text-white rounded-lg hover:bg-cyan-600"),
          event.on_click(UserOpensDeckManagement),
        ],
        [html.text("Manage Decks")],
      ),
    ]),
  ])
}

fn view_not_implemented(feature: String) -> Element(Message) {
  html.div([class("flex flex-col items-center justify-center mt-32 gap-4")], [
    html.h1([class("text-6xl font-sans text-cyan-500")], [html.text("504")]),
    html.h2([class("text-2xl font-sans")], [html.text("Not implemented yet")]),
    html.p([class("text-gray-500")], [html.text(feature <> " is coming soon.")]),
    html.button(
      [
        class(
          "mt-4 px-6 py-2 bg-cyan-500 text-white rounded-lg hover:bg-cyan-600",
        ),
        event.on_click(UserGoesBack),
      ],
      [html.text("Go back")],
    ),
  ])
}

fn view_error(code: Int, message: String) -> Element(Message) {
  html.div([class("flex flex-col items-center justify-center mt-32 gap-4")], [
    html.h1([class("text-6xl font-sans text-cyan-500")], [
      html.text(int.to_string(code)),
    ]),
    html.h2([class("text-2xl font-sans")], [html.text("Not implemented yet")]),
    html.p([class("text-gray-500")], [
      html.text("an error has occured" <> message),
    ]),
    html.button(
      [
        class(
          "mt-4 px-6 py-2 bg-cyan-500 text-white rounded-lg hover:bg-cyan-600",
        ),
        event.on_click(UserGoesBack),
      ],
      [html.text("Go back")],
    ),
  ])
}

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
                  <> "  ✓ "
                  <> int.to_string(card.times_correct)
                  <> "  ✗ "
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
                  event.on_click(UserModifiesACard(Some(card.id))),
                ],
                [html.text("Modify")],
              ),
              html.button(
                [
                  class(
                    "px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600",
                  ),
                  event.on_click(UserDeletesACard(Some(card.id))),
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
