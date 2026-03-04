import http.server
import json
import re
import sqlite3
import socketserver
from DataBaseAndCrudOperations.CrudOperations import *


class MyHandler(http.server.SimpleHTTPRequestHandler):
    con = sqlite3.connect('DataBaseAndCrudOperations/decks.db')
    def _set_response(self, status_code=200, content_type='application/json'):
        self.send_response(status_code)
        self.send_header('Content-type', content_type)
        self.end_headers()

    def _read_body(self):
        content_length = int(self.headers.get('Content-Length', 0))
        # verificam daca exista un body si cat de mare e
        if content_length == 0: # nu are body
            return {}
        post_data = self.rfile.read(content_length)
        # rfile este la fel ca open(http-body,r)
        return json.loads(post_data.decode('utf-8'))

    def do_GET(self):
        if self.path == '/cards':
            cursor = self.con.cursor()
            cards=get_all_cards(cursor)
            cursor.close()
            cards_list = []
            for card in cards:

                card_json = {
                    "id": card[0],
                    "question": card[1],
                    "answer": card[2],
                    "score": card[3],
                    "times_correct": card[4],
                    "times_wrong": card[5],
                }
                cards_list.append(card_json)
            if len(cards_list) > 0:
                self._set_response(200)
                self.wfile.write(json.dumps(cards_list).encode('utf-8'))
            else:
                self._set_response(204)
                self.wfile.write(json.dumps([]).encode('utf-8'))
    def do_POST(self):
        if self.path == '/cards':
            body = self._read_body()
            score=0
            if "score" in body.keys():
                score=body["score"]
                try:
                    score=int(score)
                except ValueError:
                    self._set_response(400)
                    self.wfile.write(json.dumps({"error": "Bad Request, wrong format for score"}).encode('utf-8'))
                    return
            question=""
            if "question" in body.keys():
                question=body["question"]
            else:
                self._set_response(400)
                self.wfile.write(json.dumps({"error": "Bad Request, question not found"}).encode('utf-8'))
                return
            answer=""
            if "answer" in body.keys():
                answer=body["answer"]
            else:
                self._set_response(400)
                self.wfile.write(json.dumps({"error": "Bad Request, answer not found"}).encode('utf-8'))
                return
            try:
                create_card(self.con, question, answer, score)
            except Exception as e:
                self._set_response(400)
                self.wfile.write(json.dumps({"error":"DataBase error "+ str(e)}).encode('utf-8'))
                return
            else:
                self._set_response(201)
                self.wfile.write(json.dumps({"message": "Card created successfully"}).encode('utf-8'))
                return
    def do_PUT(self):
        if self.path.startswith('/cards/'):
            id_string = self.path[len('/cards/'):]
            card_id=None
            if id_string.isdigit():
                card_id = int(id_string)
            else:
                self._set_response(400)
                self.wfile.write(json.dumps({"error": "wrong id format"}).encode('utf-8'))
            body = self._read_body()
            score=None
            if "score" in body.keys():
                score = body["score"]
            question = None
            if "question" in body.keys():
                question = body["question"]
            answer = None
            if "answer" in body.keys():
                answer = body["answer"]
            try:
                if score is not None:
                    score=str(score)
                if isinstance(question,str) and isinstance(answer,str):
                    modify_card(self.con, card_id, question, answer,score)
                else :
                    raise Exception("Error in body formatting")
            except Exception as e:
                self._set_response(400)
                self.wfile.write(json.dumps({"error":"DataBase error "+ str(e)}).encode('utf-8'))
                return
            else:
                self._set_response(200)
                self.wfile.write(json.dumps({"message": f"Card {card_id} modified successfully"}).encode('utf-8'))
                return
    def do_PATCH(self):
        if self.path.startswith('/cards/'):
            id_string = self.path[len('/cards/'):]
            card_id = None
            try:
                if id_string.isdigit():
                    card_id = int(id_string)
                else:
                    raise Exception("Error in id formatting")
                body = self._read_body()
                if "is_correct" in body.keys():
                    is_correct = body["is_correct"]
                    if isinstance(is_correct,bool):
                        register_answer(self.con, card_id, is_correct)
                    else:
                        raise Exception("Error in body formatting")
                else:
                    raise Exception("is_correct not found")
            except Exception as e:
                self._set_response(400)
                self.wfile.write(json.dumps({"error":str(e)}).encode('utf-8'))
                return
            else:
                self._set_response(200)
                self.wfile.write(json.dumps({"message": f"Answer registered for card {card_id}"}).encode('utf-8'))
                return
    def do_DELETE(self):
        if self.path.startswith('/cards/'):
            id_string = self.path[len('/cards/'):]
            card_id = None
            try:
                if id_string.isdigit():
                    card_id = int(id_string)
                else:
                    raise Exception("Error in id formatting")
                delete_a_card(self.con, card_id)
            except Exception as e:
                self._set_response(400)
                self.wfile.write(json.dumps({"error":str(e)}).encode('utf-8'))
                return







PORT=5000

handler = MyHandler

myServer = socketserver.TCPServer(("", PORT), handler)
