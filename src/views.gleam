import gleam/int
import gleam/option.{Some}
import lustre/attribute.{class}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model.{
  type Message, type Model, CardCreation, CardDeleting, CardManager,
  CardModifying, ConfirmationPage, DeckCardAddition, DeckCardRemoval,
  DeckCreation, DeckDeleting, DeckManager, DeckModifying, ErrorState,
  NewDeckCardChoose, Quiz, Start, UserGoesBack, UserOpensCardManagement,
  UserOpensDeckManagement,
}
import views_cards.{
  view_card_creation, view_card_deleting, view_card_management,
  view_card_modifying,
}
import views_decks.{
  view_deck_card_removal, view_deck_creation, view_deck_deleting,
  view_deck_management, view_deck_modifying, view_new_deck_card_choose,
}

pub fn view(model: Model) -> Element(Message) {
  html.div([class("min-h-screen bg-gray-50")], [
    view_header(model),
    case model {
      Start -> view_start()
      CardManager(cards) -> view_card_management(cards)
      CardModifying(_, _, question, answer, score) ->
        view_card_modifying(question, answer, score)
      CardDeleting(cards, card_id) -> view_card_deleting(cards, card_id)
      CardCreation(_, question, answer, score) ->
        view_card_creation(question, answer, score)
      DeckManager(decks) -> view_deck_management(decks)
      DeckModifying(_, deck, cards) -> view_deck_modifying(deck, cards)
      DeckDeleting(decks, deck_id) -> view_deck_deleting(decks, deck_id)
      DeckCardAddition(_, _, _, _, _) -> view_error(500, "jumpscare")
      DeckCardRemoval(_, deck, cards, card_id) ->
        view_deck_card_removal(deck, cards, card_id)
      NewDeckCardChoose(_, deck, _, not_in_cards) ->
        view_new_deck_card_choose(deck, not_in_cards)
      DeckCreation(_, title) -> view_deck_creation(title)
      ConfirmationPage(msg) -> view_confirmation(msg)

      Quiz -> view_not_implemented("quiz time")
      ErrorState(e, m) -> view_error(e, m)
    },
  ])
}

fn get_title(model: Model) -> String {
  case model {
    Start -> "FlashCard Manager"
    CardCreation(_, _, _, _) -> "Create Card"
    CardModifying(_, _, _, _, _) -> "Modify Card"
    CardManager(_) -> "Cards List"
    CardDeleting(_, _) -> "Delete Card"
    DeckCreation(_, _) -> "Create Deck"
    DeckModifying(_, _m, _) -> "Deck"
    DeckManager(_) -> "Decks List"
    DeckDeleting(_, _) -> "Delete Deck"
    Quiz -> "Quiz Time"
    ErrorState(code, _) -> "Error " <> int.to_string(code)
    DeckCardAddition(_, _, _, _, _) -> "Add a card to deck"
    DeckCardRemoval(_, _, _, _) -> "Remove Card From Deck"
    ConfirmationPage(_) -> "Confirm"
    NewDeckCardChoose(_, _, _, _) -> "Choose a card for the deck"
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
      html.button(
        [
          class("px-6 py-3 bg-cyan-500 text-white rounded-lg hover:bg-cyan-600"),
          event.on_click(model.UserTakesAQuiz(0, Some([]), Some(0), 0)),
        ],
        [html.text("Take a quiz")],
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

pub fn view_confirmation(message: String) -> Element(Message) {
  html.div([class("flex flex-col items-center justify-center mt-32 gap-4")], [
    html.div([class("text-6xl")], [html.text("Yipee")]),
    html.h2([class("text-2xl font-sans text-center")], [html.text(message)]),
    html.button(
      [
        class(
          "mt-4 px-6 py-3 bg-cyan-500 text-white rounded-lg hover:bg-cyan-600",
        ),
        event.on_click(UserGoesBack),
      ],
      [html.text("Go back")],
    ),
  ])
}
