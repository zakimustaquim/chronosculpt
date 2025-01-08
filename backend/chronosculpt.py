from flask import Flask, jsonify, g, request
from datetime import datetime, timezone
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
            since TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
            active BOOLEAN DEFAULT TRUE
        )
    ''')

    # Table to store record data
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS records (
            rid SERIAL PRIMARY KEY,
            uid TEXT NOT NULL,
            date TIMESTAMP DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
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
                            'hid': habit[0], 
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

@app.route('/records/<user_id>/', methods=['GET'])
def get_all_records(user_id):
    try:
        g.cursor.execute('''
            SELECT *
            FROM records
            WHERE uid = %s
        ''', (user_id,))
        records = g.cursor.fetchall()
        result = {'records': 
                    [
                        {
                            'rid': record[0],
                            'uid': record[1],
                            'date': record[2],
                            'q1notes': record[3],
                            'q2notes': record[4],
                            'q3notes': record[5],
                            'q4notes': record[6],
                            'entries': get_entries_by_rid(record[0])
                        } 
                        for record in records
                    ]
                }
        return jsonify(result), 200
    
    except Exception as e:
        return jsonify({'error' : str(e)}), 500

def get_entries_by_rid(rid):
    g.cursor.execute('''
            SELECT e.*, h.name as habit_name
            FROM entries e
            JOIN habits h ON e.hid = h.hid
            WHERE e.rid = %s
        ''', (rid,))
    entries = g.cursor.fetchall()
    result = [
                {
                    'eid': entry[0],
                    'rid': entry[1],
                    'hid': entry[2],
                    'comments': entry[3],
                    'done': entry[4],
                    'quadrant': entry[5],
                    'doneAt': entry[6],
                    'split': entry[7],
                    'habit_name': entry[8],
                } 
                for entry in entries
            ]
    return result

# This function expects a timestamp in UTC.
@app.route('/records/<user_id>/<int:timestamp>/', methods=['GET'])
def get_records_after_timestamp(user_id, timestamp):
    try:
        dt = datetime.fromtimestamp(timestamp / 1000.0, timezone.utc)

        g.cursor.execute('''
            SELECT *
            FROM records
            WHERE uid = %s AND date >= %s AT TIME ZONE 'UTC'
        ''', (user_id, dt,))
        
        records = g.cursor.fetchall()

        result = {'records': 
                    [
                        {
                            'rid': record[0],
                            'uid': record[1],
                            'date': record[2],
                            'q1notes': record[3],
                            'q2notes': record[4],
                            'q3notes': record[5],
                            'q4notes': record[6],
                            'entries': get_entries_by_rid(record[0])
                        } 
                        for record in records
                    ]
                }
        return jsonify(result), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/records/<int:record_id>/', methods=['PUT'])
def update_record(record_id):
    # TODO
    return

@app.route('/entries/<int:entry_id>/', methods=['PUT'])
def update_entry(entry_id):
    # TODO
    return

@app.route('/records/<user_id>/', methods=['POST'])
def create_record(user_id):
    try:
        habits_response, status_code = get_habits_by_user_id(user_id)
        habits = habits_response.get_json()['habits']

        # insert row into records table
        g.cursor.execute('''
            INSERT INTO records (uid, q1notes, q2notes, q3notes, q4notes)
            VALUES (%s, '', '', '', '')
            RETURNING rid;
        ''', (user_id,))
        record_id = g.cursor.fetchone()[0]
        
        for habit in habits:
            g.cursor.execute('''
                INSERT INTO entries (rid, hid, comments, quadrant)
                VALUES (%s, %s, %s, %s);
            ''', (record_id, habit['hid'], habit['comments'], habit['preferredQuadrant']))
        
        g.db.commit()
        return jsonify({'id': record_id})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Expects 3 parameters in JSON body - name, comments, and preferredQuadrant
@app.route('/habits/<user_id>/', methods=['POST'])
def add_habit(user_id):
    try:
        data = request.get_json()
        name = data.get('name')
        comments = data.get('comments')
        preferred_quadrant = data.get('preferredQuadrant')

        g.cursor.execute('''
            INSERT INTO habits (uid, name, comments, preferredQuadrant)
            VALUES (%s, %s, %s, %s)
            RETURNING *;
        ''', (user_id, name, comments, preferred_quadrant))
        habit = g.cursor.fetchone()

        result = {
                    'hid': habit[0], 
                    'uid': habit[1],
                    'name': habit[2],
                    'comments': habit[3],
                    'preferredQuadrant': habit[4],
                    'since': habit[5],
                    'active': habit[6]
                 } 
        g.db.commit()
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Expects 4 parameters in JSON body - name, comments, preferredQuadrant, and active
@app.route('/habits/<int:habit_id>/', methods=['PUT'])
def update_habit(habit_id):
    try:
        data = request.get_json()
        name = data.get('name')
        comments = data.get('comments')
        preferred_quadrant = data.get('preferredQuadrant')
        active = data.get('active')

        g.cursor.execute('''
            UPDATE habits
            SET name = %s, comments = %s, preferredquadrant = %s, active = %s
            WHERE hid = %s
            RETURNING *;
        ''', (name, comments, preferred_quadrant, active, habit_id))

        habit = g.cursor.fetchone()

        result = {
                    'hid': habit[0], 
                    'uid': habit[1],
                    'name': habit[2],
                    'comments': habit[3],
                    'preferredQuadrant': habit[4],
                    'since': habit[5],
                    'active': habit[6]
                 } 
        g.db.commit()
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/habits/<int:habit_id>/', methods=['DELETE'])
def delete_habit(habit_id):
    # TODO
    return

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
