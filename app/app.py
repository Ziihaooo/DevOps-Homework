from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def index():
    return "Hello from Flask API!", 200

@app.route('/health')
def health():
    return jsonify(status="200 OK")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
