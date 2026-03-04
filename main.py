import http.server

# IMPORTANT: Replace 'your_handler_file' with the actual name of the Python file
# where you saved the MyHandler class (without the .py extension).
# For example, if your file is named 'api.py', write: from api import MyHandler
from APIHandler import MyHandler


def run_server(port=8000):

    server_address = ('', port)
    httpd = http.server.HTTPServer(server_address, MyHandler)

    print(f"Starting RESTful API server on port {port}...")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down the server...")
        httpd.server_close()
        print("Server stopped.")


if __name__ == "__main__":
    run_server()