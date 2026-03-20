import gleam/int
import gleam/list
import lustre/attribute.{class}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model.{
  type Message, UserAddsACardToDeck, UserConfirmsAction, UserCreatesADeck,
  UserDeletesADeck, UserGoesBack, UserModifiesADeck, UserTypesDeck,
  UserWantsToAddACardToDeck, UserWantsToRemoveACardFromDeck,
}
import objects.{type Card, type Deck}

pub fn view_deck_management(decks: List(Deck)) -> Element(Message) {
  html.div([class("p-8 flex flex-col gap-4")], [
    html.div([class("flex flex-col gap-2")], case decks {
      [] -> [
        html.p([class("text-gray-400 italic")], [
          html.text("No decks yet."),
        ]),
      ]
      _ ->
        list.map(decks, fn(deck) {
          html.div(
            [
              class(
                "flex items-center justify-between p-4 bg-white rounded-lg shadow",
              ),
            ],
            [
              html.div([class("flex flex-col gap-1")], [
                html.p([class("font-sans font-medium text-lg")], [
                  html.text(deck.title),
                ]),
                html.p([class("text-gray-400 text-xs")], [
                  html.text(
                    "Cards: "
                    <> int.to_string(deck.cnt)
                    <> "  Total score: "
                    <> int.to_string(deck.total),
                  ),
                ]),
              ]),
              html.div([class("flex gap-2")], [
                html.button(
                  [
                    class(
                      "px-4 py-2 bg-cyan-500 text-white rounded hover:bg-cyan-600",
                    ),
                    event.on_click(UserModifiesADeck(deck, [])),
                  ],
                  [html.text("Open")],
                ),
                html.button(
                  [
                    class(
                      "px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600",
                    ),
                    event.on_click(UserDeletesADeck(deck.id)),
                  ],
                  [html.text("Delete")],
                ),
              ]),
            ],
          )
        })
    }),
    html.button(
      [
        class(
          "mt-4 px-6 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600",
        ),
        event.on_click(UserCreatesADeck),
      ],
      [html.text("Create a deck")],
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

pub fn view_deck_creation(title: String) -> Element(Message) {
  html.div([class("p-8 flex flex-col gap-6 max-w-xl mx-auto")], [
    html.div([class("flex flex-col gap-2")], [
      html.label([class("text-gray-700 font-medium")], [html.text("Deck title")]),
      html.input([
        class("p-3 border border-gray-300 rounded-lg w-full"),
        attribute.type_("text"),
        attribute.value(title),
        attribute.placeholder("Write your deck title here..."),
        event.on_input(fn(t) { UserTypesDeck(t) }),
      ]),
    ]),
    html.div([class("flex gap-4 mt-4")], [
      html.button(
        [
          class(
            "px-6 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600 disabled:opacity-50",
          ),
          event.on_click(UserConfirmsAction),
          attribute.disabled(title == ""),
        ],
        [html.text("Create deck")],
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

pub fn view_deck_modifying(deck: Deck, cards: List(Card)) -> Element(Message) {
  html.div([class("p-8 flex flex-col gap-4")], [
    html.div([class("p-4 bg-white rounded-lg shadow")], [
      html.p([class("text-gray-400 text-xs")], [
        html.text(
          "Cards: "
          <> int.to_string(deck.cnt)
          <> "  Total score: "
          <> int.to_string(deck.total),
        ),
      ]),
    ]),
    html.div([class("flex flex-col gap-2")], case cards {
      [] -> [
        html.p([class("text-gray-400 italic")], [
          html.text("No cards in this deck yet."),
        ]),
      ]
      _ ->
        list.map(cards, fn(card) {
          html.div(
            [
              class(
                "flex items-center justify-between p-4 bg-white rounded-lg shadow",
              ),
            ],
            [
              html.div([class("flex flex-col gap-1")], [
                html.p([class("font-medium")], [html.text(card.question)]),
                html.p([class("text-gray-500 text-sm")], [
                  html.text(card.answer),
                ]),
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
              html.button(
                [
                  class(
                    "px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600",
                  ),
                  event.on_click(UserWantsToRemoveACardFromDeck(card.id)),
                ],
                [html.text("Remove")],
              ),
            ],
          )
        })
    }),
    html.button(
      [
        class(
          "mt-2 px-6 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600",
        ),
        event.on_click(UserWantsToAddACardToDeck),
      ],
      [html.text("Add a card")],
    ),
    html.button(
      [
        class("px-6 py-3 bg-gray-300 rounded-lg hover:bg-gray-400"),
        event.on_click(UserGoesBack),
      ],
      [html.text("Back to decks")],
    ),
  ])
}

pub fn view_deck_deleting(decks: List(Deck), deck_id: Int) -> Element(Message) {
  let deck = list.find(decks, fn(d) { d.id == deck_id })
  html.div([class("p-8 flex flex-col items-center gap-6 max-w-xl mx-auto")], [
    html.div([class("text-6xl")], [html.text("🗑️")]),
    html.h2([class("text-2xl font-sans text-center")], [
      html.text("Are you sure you want to delete this deck?"),
    ]),
    case deck {
      Ok(d) ->
        html.div(
          [class("p-4 bg-white rounded-lg shadow w-full flex flex-col gap-1")],
          [
            html.p([class("font-medium text-lg")], [html.text(d.title)]),
            html.p([class("text-gray-400 text-xs")], [
              html.text("Cards: " <> int.to_string(d.cnt)),
            ]),
          ],
        )
      Error(_) ->
        html.p([class("text-gray-400")], [
          html.text("Deck #" <> int.to_string(deck_id)),
        ])
    },
    html.p([class("text-red-500 text-sm text-center")], [
      html.text(
        "The cards in this deck will not be deleted, only the deck itself.",
      ),
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

pub fn view_deck_card_removal(
  deck: Deck,
  cards: List(Card),
  card_id: Int,
) -> Element(Message) {
  let card = list.find(cards, fn(c) { c.id == card_id })
  html.div([class("p-8 flex flex-col items-center gap-6 max-w-xl mx-auto")], [
    html.h2([class("text-2xl font-sans text-center")], [
      html.text("Remove this card from \"" <> deck.title <> "\"?"),
    ]),
    case card {
      Ok(c) ->
        html.div(
          [class("p-4 bg-white rounded-lg shadow w-full flex flex-col gap-1")],
          [
            html.p([class("font-medium")], [html.text(c.question)]),
            html.p([class("text-gray-500 text-sm")], [html.text(c.answer)]),
          ],
        )
      Error(_) ->
        html.p([class("text-gray-400")], [
          html.text("Card #" <> int.to_string(card_id)),
        ])
    },
    html.p([class("text-gray-500 text-sm text-center")], [
      html.text("The card itself will not be deleted."),
    ]),
    html.div([class("flex gap-4")], [
      html.button(
        [
          class("px-6 py-3 bg-red-500 text-white rounded-lg hover:bg-red-600"),
          event.on_click(UserConfirmsAction),
        ],
        [html.text("Yes, remove it")],
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

pub fn view_new_deck_card_choose(
  deck: Deck,
  not_in_cards: List(Card),
) -> Element(Message) {
  html.div([class("p-8 flex flex-col gap-4")], [
    html.p([class("text-gray-500")], [
      html.text("Choose a card to add to \"" <> deck.title <> "\":"),
    ]),
    html.div([class("flex flex-col gap-2")], case not_in_cards {
      [] -> [
        html.p([class("text-gray-400 italic")], [
          html.text("All cards are already in this deck."),
        ]),
      ]
      _ ->
        list.map(not_in_cards, fn(card) {
          html.div(
            [
              class(
                "flex items-center justify-between p-4 bg-white rounded-lg shadow",
              ),
            ],
            [
              html.div([class("flex flex-col gap-1")], [
                html.p([class("font-medium")], [html.text(card.question)]),
                html.p([class("text-gray-500 text-sm")], [
                  html.text(card.answer),
                ]),
                html.p([class("text-gray-400 text-xs")], [
                  html.text("Score: " <> int.to_string(card.score)),
                ]),
              ]),
              html.button(
                [
                  class(
                    "px-4 py-2 bg-cyan-500 text-white rounded hover:bg-cyan-600",
                  ),
                  event.on_click(UserAddsACardToDeck(card.id)),
                ],
                [html.text("Add")],
              ),
            ],
          )
        })
    }),
    html.button(
      [
        class("px-6 py-3 bg-gray-300 rounded-lg hover:bg-gray-400"),
        event.on_click(UserGoesBack),
      ],
      [html.text("Back")],
    ),
  ])
}
