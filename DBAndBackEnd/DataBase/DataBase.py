import sqlite3

def create_database_schema(con):
    con.executescript("""
    CREATE TABLE IF NOT EXISTS decks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT UNIQUE NOT NULL,
        cnt INTEGER DEFAULT 0,
        total INTEGER DEFAULT 0);
    
    CREATE TABLE IF NOT EXISTS cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        score INTEGER DEFAULT 0,
        times_correct DEFAULT 0,
        times_wrong DEFAULT 0);
        
    CREATE TABLE IF NOT EXISTS deck_cards(
    deck_id INTEGER NOT NULL,
    card_id INTEGER NOT NULL,
    FOREIGN KEY(deck_id) REFERENCES decks(id) ON DELETE CASCADE,
    FOREIGN KEY(card_id) REFERENCES cards(id) ON DELETE CASCADE
    );""")
def setup_database():
    con = sqlite3.connect('decks.db')
    create_database_schema(con)
    return con