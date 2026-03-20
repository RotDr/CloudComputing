import gleam/option.{type Option}
import lustre_http
import objects.{type Card, type Deck}

pub type Model {
  CardManager(cards: List(Card))
  CardModifying(
    cards: List(Card),
    card_id: Int,
    question: Option(String),
    answer: Option(String),
    score: Option(Int),
  )
  CardDeleting(cards: List(Card), card_id: Int)
  CardCreation(
    cards: List(Card),
    question: String,
    answer: String,
    score: Option(Int),
  )
  DeckManager(decks: List(Deck))
  DeckModifying(decks: List(Deck), deck: Deck, cards: List(Card))
  DeckCardRemoval(
    decks: List(Deck),
    deck: Deck,
    cards: List(Card),
    card_id: Int,
  )
  NewDeckCardChoose(
    decks: List(Deck),
    deck: Deck,
    cards: List(Card),
    not_in_cards: List(Card),
  )
  DeckCardAddition(
    decks: List(Deck),
    deck: Deck,
    cards: List(Card),
    not_in_cards: List(Card),
    card_id: Int,
  )
  DeckDeleting(decks: List(Deck), deck_id: Int)
  DeckCreation(decks: List(Deck), title: String)
  ConfirmationPage(message: String)
  Start
  Quiz
  ErrorState(code: Int, err_msg: String)
}

pub type Message {
  UserOpensCardManagement
  UserCreatesACard
  UserModifiesACard(card_id: Int)
  UserDeletesACard(card_id: Int)
  UserConfirmsAction
  UserGoesBack
  UserOpensDeckManagement
  UserCreatesADeck
  UserModifiesADeck(deck: Deck, cards: List(Card))
  UserDeletesADeck(deck_id: Int)
  UserAddsACardToDeck(card_id: Int)
  UserTakesAQuiz(
    deck_id: Int,
    card_list: Option(List(Int)),
    card_no: Option(Int),
    score: Int,
  )
  DBGaveTheCards(cards: Result(List(Card), lustre_http.HttpError))
  DBGaveTheDecks(deck: Result(List(Deck), lustre_http.HttpError))
  DBGaveTheCard(card: Result(Card, lustre_http.HttpError))
  DBGaveTheDeck(Result(#(Deck, List(Card)), lustre_http.HttpError))
  AppError(code: Int, err: String)
  DBConfirmed(Result(String, lustre_http.HttpError))
  UserTypesCard(question: String, answer: String, score: Option(Int))
  UserTypesDeck(title: String)
  UserModifiesCard(
    question: Option(String),
    answer: Option(String),
    score: Option(Int),
  )
  UserWantsToAddACardToDeck
  UserWantsToRemoveACardFromDeck(card_id: Int)
}
