from flask import Flask, render_template, request, redirect
import psycopg2

app = Flask(__name__)

def get_db_connection():
    return psycopg2.connect(
        dbname="catsstats",
        user="postgres",
        password="Maddie2013",
        host="localhost",
        port="5432"
    )

def get_members():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT m.full_name, m.email, m.class_year,
               string_agg(p.position_title, ', ') AS positions
        FROM public.member m
        LEFT JOIN member_position mp ON mp.fk_member_id = m.pk_member_id
        LEFT JOIN public.positions p ON p.pk_position_id = mp.fk_position_id
        GROUP BY m.full_name, m.email, m.class_year
        ORDER BY m.full_name;
    """)
    members = cur.fetchall()
    cur.close()
    conn.close()
    return members

def get_positions():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT pk_position_id, position_title
        FROM public.positions
        ORDER BY 
            CASE WHEN position_title = 'Member' THEN 0 ELSE 1 END,
            position_title;
    """)
    positions = cur.fetchall()
    cur.close()
    conn.close()
    return positions

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        full_name = request.form['full_name'].strip()
        email = request.form['email'].strip()
        class_year = request.form['class_year'].strip()
        selected_position_id = request.form.get('position_id')
        new_position = request.form.get('new_position', '').strip()

        conn = get_db_connection()
        cur = conn.cursor()

        # Insert new member
        cur.execute("""
            INSERT INTO public.member (full_name, email, class_year)
            VALUES (%s, %s, %s)
            RETURNING pk_member_id;
        """, (full_name, email, class_year))
        member_id = cur.fetchone()[0]

        # Determine position_id
        if new_position:
            cur.execute("""
                INSERT INTO public.positions (position_title)
                VALUES (%s)
                ON CONFLICT (position_title) DO NOTHING
                RETURNING pk_position_id;
            """, (new_position,))
            inserted = cur.fetchone()
            position_id = inserted[0] if inserted else None

            if not position_id:
                cur.execute("SELECT pk_position_id FROM public.positions WHERE position_title = %s;", (new_position,))
                position_id = cur.fetchone()[0]
        else:
            position_id = selected_position_id

        # Link member to position
        if member_id and position_id:
            cur.execute("""
                INSERT INTO member_position (fk_member_id, fk_position_id)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING;
            """, (member_id, position_id))

        conn.commit()
        cur.close()
        conn.close()
        return redirect('/')

    members = get_members()
    positions = get_positions()
    return render_template('index.html', members=members, positions=positions)

if __name__ == '__main__':
    app.run(debug=True)



