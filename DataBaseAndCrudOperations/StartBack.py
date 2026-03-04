import sqlite3

#from BasicGui.StartFront import entry
from DataBaseAndCrudOperations.CrudOperations import *

con = sqlite3.connect('../BasicGui/decks.db')
cursor = con.cursor()
def get_decks():
    print(get_all_decks(cursor))
# def add_deck():
#     text=entry.get()
#     if text:
#         create_deck(con,text)
