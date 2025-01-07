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
def init_db(reset=False):
    # Connect to database
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    if (reset):
        cursor.execute('drop table entries')
        cursor.execute('drop table records')
        cursor.execute('drop table habits')
    
    # Table to store habit data
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS habits (
            hid SERIAL PRIMARY KEY,
            uid TEXT NOT NULL,
            name TEXT NOT NULL,
            comments TEXT NOT NULL,
            preferredQuadrant INTEGER CHECK (preferredQuadrant BETWEEN 0 AND 4),
            since TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            active BOOLEAN DEFAULT TRUE
        )
    ''')

    # Table to store record data
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS records (
            rid SERIAL PRIMARY KEY,
            uid TEXT NOT NULL,
            date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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

@app.route('/habits/<user_id>/', methods=['GET'])
def get_habits_by_user_id(user_id):
    try:
        g.cursor.execute('''
            SELECT *
            FROM habits
            WHERE uid = %s
        ''', (user_id,))

        habits = g.cursor.fetchall()
        result = {'habits': 
                    [
                        {
                            'id': habit[0], 
                            'uid': habit[1],
                            'name': habit[2],
                            'comments': habit[3],
                            'preferredQuadrant': habit[4],
                            'since': habit[5],
                            'active': habit[6]
                        } 
                        for habit in habits
                    ]
                }
        return jsonify(result), 200
    
    except Exception as e:
            return jsonify({'error' : str(e)}), 500

@app.route('/records/<user_id>/<int:timestamp>/')
def get_records(user_id, timestamp):
    try:
        # sql
        return

    except Exception as e:
            return jsonify({'error': str(e)}), 500
        

@app.route('/', methods=['GET'])
def hello_world():
    return jsonify({'message': 'Hello world!'}), 200

def insert_test_data():
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()

    # Habits
    cursor.execute('''
        INSERT INTO habits (uid, name, comments, preferredQuadrant)
        VALUES ('a23', 'Habit 1', 'Example comment for 1', 0);
    ''')
    cursor.execute('''
        INSERT INTO habits (uid, name, comments, preferredQuadrant)
        VALUES ('a23', 'Habit 2', 'Example comment for 2', 4);
    ''')
    cursor.execute('''
        INSERT INTO habits (uid, name, comments, preferredQuadrant)
        VALUES ('a22', 'Habit 3', 'Example comment for 3', 3);
    ''')
    cursor.execute('''
        INSERT INTO habits (uid, name, comments, preferredQuadrant)
        VALUES ('a21', 'Habit 4', 'Example comment for 4', 2);
    ''')

    conn.commit()
    cursor.close()
    conn.close()


if __name__ == '__main__':
    init_db(True)
    insert_test_data()
    app.run(debug=True)
