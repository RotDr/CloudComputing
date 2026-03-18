from APIHandler import app

def run_server(port=5000):
    print(f"Starting Flask API server on port {port}...")
    # Flask's built-in way to run the server
    app.run(host='127.0.0.1', port=port, debug=True)

if __name__ == "__main__":
    run_server()