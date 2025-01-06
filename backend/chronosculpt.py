from flask import Flask, jsonify, g
import psycopg2
from psycopg2.extras import DictCursor
from psycopg2.pool import SimpleConnectionPool
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Flask
app = Flask(__name__)

# Configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST'),
    'port': os.getenv('DB_PORT'),
    'user': os.getenv('DB_USER'),
    'password': os.getenv('DB_PASSWORD'),
    'dbname': os.getenv('DB_NAME')
}

# Create connection pool
db_pool = SimpleConnectionPool(
    minconn=5,
    maxconn=20,
    **DB_CONFIG
)

# Get connection from pool
@app.before_request
def get_db():
    try:
        if 'db' not in g:
            g.db = db_pool.getconn()
            g.cursor = g.db.cursor(cursor_factory=DictCursor)
    except psycopg2.pool.PoolError:
        return jsonify({'error': 'Server overloaded'}), 503

# Return connection to pool
@app.teardown_appcontext
def close_db(error):
    db = g.pop('db', None)
    cursor = g.pop('cursor', None)
    if cursor is not None:
        cursor.close()
    if db is not None:
        db_pool.putconn(db)


# Initialize the database and create necessary tables
def init_db():
    # Connect to database
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    # Table to store habit data
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS habits (
            hid SERIAL PRIMARY KEY,
            uid TEXT NOT NULL,
            name TEXT NOT NULL,
            comments TEXT NOT NULL,
            preferredQuadrant INTEGER CHECK (preferredQuadrant BETWEEN 1 AND 4),
            since TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            active BOOLEAN DEFAULT TRUE
        )
    ''')

    # Table to store record data
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS records (
            rid SERIAL PRIMARY KEY,
            uid TEXT NOT NULL,
            date TIMESTAMP NOT NULL,
            q1notes TEXT NOT NULL,
            q2notes TEXT NOT NULL,
            q3notes TEXT NOT NULL,
            q4notes TEXT NOT NULL
        )
    ''')

    # Table to store entries for individual records
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS entries (
            eid SERIAL PRIMARY KEY,
            rid INTEGER NOT NULL REFERENCES records(rid) ON DELETE CASCADE,
            hid INTEGER NOT NULL REFERENCES habits(hid) ON DELETE CASCADE,
            comments TEXT NOT NULL,
            done BOOLEAN NOT NULL DEFAULT FALSE,
            quadrant INTEGER NOT NULL,
            doneAt TIMESTAMP,
            split INTEGER
        )
    ''')
    
    conn.commit()
    cursor.close()
    conn.close()

@app.route('/', methods=['GET'])
def hello_world():
    return jsonify({'message': 'Hello world!'}), 200

if __name__ == '__main__':
    init_db()
    app.run(debug=True)
