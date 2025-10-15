from flask import Flask, request, jsonify
import pymysql
import os

app = Flask(__name__)

# Database configuration from environment variables
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_USER = os.environ.get("DB_USER", "root")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")
DB_NAME = os.environ.get("DB_NAME", "inventory_db")

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route("/products", methods=["GET"])
def get_products():
    conn = get_db_connection()
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM products")
        results = cursor.fetchall()
    conn.close()
    return jsonify(results)

@app.route("/products", methods=["POST"])
def add_product():
    data = request.get_json()
    name = data.get("name")
    quantity = data.get("quantity")
    if not name or quantity is None:
        return {"error": "Invalid input"}, 400
    #connect the db
    conn = get_db_connection()
    #create something like typing window in the database
    with conn.cursor() as cursor:
        #find do we have this name inside our db already or not
        cursor.execute("SELECT quantity FROM products WHERE name =%s", (name,))
        #either return one row or no row 
        #need this line to read the result
        existing = cursor.fetchone()
        
        #if there is already such a product, update the quantity
        if existing:
            new_quantity = existing["quantity"] + quantity
            cursor.execute("UPDATE products SET quantity=%s WHERE name=%s", (new_quantity, name))
            message = f"Updated {name} quantity to {new_quantity}"
        #if there is no such product, insert a new row
        else:  
            cursor.execute("INSERT INTO products (name, quantity) VALUES (%s, %s)", (name, quantity))
            message = f"Added new product {name} with quantity {quantity}"
        
        conn.commit()
    conn.close()
    return {"message": message}, 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
