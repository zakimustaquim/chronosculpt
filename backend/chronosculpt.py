from flask import Flask, jsonify, g, request
from flask_cors import CORS
from datetime import datetime, timezone, timedelta
import psycopg2
from psycopg2.extras import DictCursor
from psycopg2.pool import SimpleConnectionPool
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Flask
app = Flask(__name__)
CORS(app)

# Load connection string
connection_string = os.getenv('NEON_STRING')

# Create connection pool
db_pool = SimpleConnectionPool(
    1,
    10,
    connection_string,
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
    conn = psycopg2.connect(connection_string)
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
            date BIGINT,
            q1notes TEXT NOT NULL DEFAULT '',
            q2notes TEXT NOT NULL DEFAULT '',
            q3notes TEXT NOT NULL DEFAULT '',
            q4notes TEXT NOT NULL DEFAULT ''
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
            doneAt BIGINT,
            split INTEGER
        )
    ''')
    
    conn.commit()
    cursor.close()
    conn.close()

# Route that returns all the habits for a given user ID
@app.route('/habits/<user_id>/', methods=['GET'])
def get_habits_by_user_id(user_id):
    try:
        g.cursor.execute('''
            SELECT *
            FROM habits
            WHERE uid = %s AND active = true
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

# Route that returns all the records for a given user ID
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

# Gets all the entries associated with a given record ID
# and returns as a list
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

# Route that returns all the records for a given user ID after
# the given timestamp. This function expects a timestamp in UTC
# as milliseconds since epoch.
@app.route('/records/<user_id>/<timestamp>/', methods=['GET'])
def get_records_after_timestamp(user_id, timestamp):
    try:
        g.cursor.execute('''
            SELECT *
            FROM records
            WHERE uid = %s AND date >= %s
        ''', (user_id, timestamp,))
        
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

# Route that updates data on a given record.
# Expects 4 parameters in JSON body - q1notes, q2notes, q3notes, q4notes
@app.route('/records/<int:record_id>/', methods=['PUT'])
def update_record(record_id):
    try:
        data = request.get_json()
        q1 = data.get('q1notes')
        q2 = data.get('q2notes')
        q3 = data.get('q3notes')
        q4 = data.get('q4notes')

        g.cursor.execute('''
            UPDATE records
            SET q1notes = %s, q2notes = %s, q3notes = %s, q4notes = %s
            WHERE rid = %s
            RETURNING *;
        ''', (q1, q2, q3, q4, record_id))

        record = g.cursor.fetchone()

        result = {
                    'rid': record[0],
                    'uid': record[1],
                    'date': record[2],
                    'q1notes': record[3],
                    'q2notes': record[4],
                    'q3notes': record[5],
                    'q4notes': record[6],
                    'entries': get_entries_by_rid(record[0])
                 } 
        g.db.commit()
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Route that updates data on a given entry.
# Expects 5 parameters in JSON body - comments, done, quadrant, doneAt, and split
@app.route('/entries/<int:entry_id>/', methods=['PUT'])
def update_entry(entry_id):
    try:
        data = request.get_json()
        comments = data.get('comments')
        done = data.get('done')
        quadrant = data.get('quadrant')
        done_at = data.get('doneAt')
        split = data.get('split')

        g.cursor.execute('''
            SET TIME ZONE 'UTC';
            UPDATE entries e
            SET comments = %s, done = %s, quadrant = %s, doneAt = %s, split = %s
            FROM habits h
            WHERE e.eid = %s AND h.hid = e.hid
            RETURNING e.*, h.name AS habit_name;
        ''', (comments, done, quadrant, done_at, split, entry_id))

        entry = g.cursor.fetchone()

        result = {
                    'eid': entry[0],
                    'rid': entry[1],
                    'hid': entry[2],
                    'comments': entry[3],
                    'done': entry[4],
                    'quadrant': entry[5],
                    'doneAt': entry[6],
                    'split': entry[7],
                    'habit_name': entry[8]
                 } 
        g.db.commit()
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Creates a new record using the user's habits.
@app.route('/records/<user_id>/<timestamp>/', methods=['POST'])
def create_record(user_id, timestamp):
    try:
        habits_response, status_code = get_habits_by_user_id(user_id)
        habits = habits_response.get_json()['habits']

        # If the user has no habits, avoid making an empty record
        if len(habits) == 0:
            return jsonify({'error' : 'The user does not have any habits.'}), 406
        
        # Check if a record already exists for today (should only be 1 per day)
        g.cursor.execute('''
            SELECT rid
            FROM records
            WHERE uid = %s AND date >= %s
        ''', (user_id, timestamp,))
        current_records = g.cursor.fetchall()
        if len(current_records) != 0:
            return jsonify({'error' : 'The user already has a record for today.'}), 400

        # insert row into records table
        g.cursor.execute('''
            INSERT INTO records (uid, date)
            VALUES (%s, %s)
            RETURNING *;
        ''', (user_id, timestamp,))
        record = g.cursor.fetchone()
        record_id = record[0]
        
        for habit in habits:
            g.cursor.execute('''
                INSERT INTO entries (rid, hid, comments, quadrant)
                VALUES (%s, %s, %s, %s);
            ''', (record_id, habit['hid'], habit['comments'], habit['preferredQuadrant']))

        result = {
                    'rid': record[0],
                    'uid': record[1],
                    'date': record[2],
                    'q1notes': record[3],
                    'q2notes': record[4],
                    'q3notes': record[5],
                    'q4notes': record[6],
                    'entries': get_entries_by_rid(record[0])
                 } 
        
        g.db.commit()
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Route that creates a new row in the habits table.
# Expects 3 parameters in JSON body - name, comments, and preferredQuadrant
@app.route('/habits/<user_id>/add/', methods=['POST'])
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

# Route that updates information for a given habit.
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

# Route that "deletes" a given habit.
@app.route('/habits/<int:habit_id>/', methods=['DELETE'])
def delete_habit(habit_id):
    try:
        g.cursor.execute('''
            UPDATE habits
            SET active = false
            WHERE hid = %s
            returning hid;
        ''', [habit_id])
        hid = g.cursor.fetchone()[0]

        g.db.commit()
        return jsonify({'deleted_id': hid}), 200
    except TypeError as te:
        return jsonify({'error': 'No habits were found matching the criteria'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Route to wake up the server
@app.route('/wakeup', methods=['GET'])
def wakeup():
    try:
        g.cursor.execute('''
            SELECT rid
            FROM records
            LIMIT 1;
        ''')
        return jsonify({'message': 'server is awake!'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    init_db()
    app.run(debug=True)
