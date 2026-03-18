pub type Card {
  Card(
    id: Int,
    question: String,
    answer: String,
    score: Int,
    times_correct: Int,
    times_wrong: Int,
  )
}

pub type Deck {
  Deck(id: Int, title: String, cnt: Int, total: Int)
}

pub type DeckCards {
  DeckCards(deck_id: Int, card_id: Int)
}
