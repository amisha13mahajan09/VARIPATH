from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import math
import psycopg2
import psycopg2.extras
import re

app = Flask(__name__)
CORS(app)

# ============================================================
# DATABASE CONFIGURATION
# ============================================================

DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "varipath",
    "user": "postgres",
    "password": "12345"
}


def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)


def init_db():
    """Initializes all necessary database tables for Users, Assistance Requests, Volunteer Locations, and Missing Persons."""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # 1. Users table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                password VARCHAR(100) NOT NULL,
                user_type VARCHAR(10) NOT NULL,
                first_name VARCHAR(100),
                last_name VARCHAR(100),
                name VARCHAR(100),
                age INT NOT NULL,
                gender VARCHAR(20) NOT NULL,
                phone VARCHAR(20) NOT NULL,
                emergency_contact VARCHAR(20) NOT NULL,
                blood_group VARCHAR(10) NOT NULL,
                health_conditions TEXT[] NOT NULL,
                date_of_birth DATE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # 2. Assistance Requests table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS assistance_requests (
                id SERIAL PRIMARY KEY,
                request_code VARCHAR(20) UNIQUE NOT NULL,
                varkari_username VARCHAR(50) REFERENCES users(username),
                varkari_name VARCHAR(100),
                latitude DOUBLE PRECISION,
                longitude DOUBLE PRECISION,
                health_condition VARCHAR(100),
                status VARCHAR(20) DEFAULT 'ACTIVE',
                assigned_volunteer VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                assigned_at TIMESTAMP,
                volunteer_done BOOLEAN DEFAULT FALSE,
                varkari_reached BOOLEAN DEFAULT FALSE,
                declined_volunteers TEXT[] DEFAULT '{}'
            );
        """)

        # 2b. Vaaripath Location Codes table (for Keypad / Landmark SOS)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS vaaripath_location_codes (
                id SERIAL PRIMARY KEY,
                location_code VARCHAR(20) UNIQUE NOT NULL,
                name VARCHAR(100) NOT NULL,
                latitude DOUBLE PRECISION NOT NULL,
                longitude DOUBLE PRECISION NOT NULL,
                description TEXT,
                active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # Seed genuine predefined route landmark coordinates from VariRouteData / MapScreen
        cursor.execute("""
            INSERT INTO vaaripath_location_codes (location_code, name, latitude, longitude, description) VALUES
            ('VP-001', 'MMCOE Medical Base Camp', 18.4905, 73.8135, 'MMCOE Campus, Karve Nagar, Pune'),
            ('VP-028', 'Pargao Medical Rest Camp', 18.3900, 74.0050, 'Pargao Rest Stop (km 28)'),
            ('VP-037', 'Dive Ghat Medical Station', 18.4350, 73.9820, 'Dive Ghat Top Base (km 18)'),
            ('VP-050', 'Saswad Main Hospital Base', 18.3440, 74.0300, 'Saswad City Ground (km 35)'),
            ('VP-100', 'Wakhari Pandharpur Medical Post', 17.8200, 75.1200, 'Wakhari Pandharpur Border (km 190)')
            ON CONFLICT (location_code) DO NOTHING;
        """)

        cursor.execute("""
            ALTER TABLE users
            ALTER COLUMN username TYPE VARCHAR(50),
            ALTER COLUMN blood_group TYPE VARCHAR(10),
            ALTER COLUMN gender TYPE VARCHAR(20),
            ALTER COLUMN password TYPE VARCHAR(100);

            ALTER TABLE assistance_requests
            ALTER COLUMN request_code TYPE VARCHAR(50),
            ADD COLUMN IF NOT EXISTS problem_description TEXT,
            ADD COLUMN IF NOT EXISTS assigned_volunteer_username VARCHAR(50),
            ADD COLUMN IF NOT EXISTS call_sid VARCHAR(100),
            ADD COLUMN IF NOT EXISTS location_code VARCHAR(20),
            ADD COLUMN IF NOT EXISTS location_source VARCHAR(30) DEFAULT 'GPS',
            ADD COLUMN IF NOT EXISTS volunteer_done BOOLEAN DEFAULT FALSE,
            ADD COLUMN IF NOT EXISTS varkari_reached BOOLEAN DEFAULT FALSE,
            ADD COLUMN IF NOT EXISTS declined_volunteers TEXT[] DEFAULT '{}';
        """)

        # 3. Volunteer Locations table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS volunteer_locations (
                id SERIAL PRIMARY KEY,
                volunteer_username VARCHAR(50) UNIQUE REFERENCES users(username),
                latitude DOUBLE PRECISION NOT NULL,
                longitude DOUBLE PRECISION NOT NULL,
                is_active BOOLEAN DEFAULT TRUE,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # 3b. General User Locations table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_locations (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE REFERENCES users(username),
                latitude DOUBLE PRECISION NOT NULL,
                longitude DOUBLE PRECISION NOT NULL,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # 4. Active Missing Persons table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS missing_persons (
                id SERIAL PRIMARY KEY,
                missing_person_id VARCHAR(50) UNIQUE NOT NULL,
                name VARCHAR(255) NOT NULL,
                age INT NOT NULL,
                gender VARCHAR(50) NOT NULL,
                contact_number VARCHAR(50),
                last_seen_location VARCHAR(255) NOT NULL,
                last_seen_datetime VARCHAR(100) NOT NULL,
                physical_description TEXT,
                clothes_description TEXT,
                other_info TEXT,
                photo TEXT,
                reporter_id VARCHAR(50) NOT NULL,
                reporter_type VARCHAR(20) NOT NULL,
                reporter_location VARCHAR(255),
                reporter_latitude DOUBLE PRECISION,
                reporter_longitude DOUBLE PRECISION,
                reported_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                status VARCHAR(50) DEFAULT 'Missing',
                found_by VARCHAR(50),
                found_location VARCHAR(255),
                found_latitude DOUBLE PRECISION,
                found_longitude DOUBLE PRECISION,
                found_datetime VARCHAR(100),
                found_photo TEXT,
                verification_status VARCHAR(50) DEFAULT 'None'
            );
        """)

        # 5. Resolved/Archived Missing Persons table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS resolved_missing_persons (
                id SERIAL PRIMARY KEY,
                missing_person_id VARCHAR(50) UNIQUE NOT NULL,
                name VARCHAR(255) NOT NULL,
                age INT NOT NULL,
                gender VARCHAR(50) NOT NULL,
                contact_number VARCHAR(50),
                last_seen_location VARCHAR(255),
                last_seen_datetime VARCHAR(100),
                physical_description TEXT,
                clothes_description TEXT,
                other_info TEXT,
                photo TEXT,
                reporter_id VARCHAR(50),
                reporter_type VARCHAR(20),
                reporter_location VARCHAR(255),
                reported_datetime TIMESTAMP,
                status VARCHAR(50) DEFAULT 'Found/Resolved',
                found_by VARCHAR(50),
                found_location VARCHAR(255),
                found_latitude DOUBLE PRECISION,
                found_longitude DOUBLE PRECISION,
                found_datetime VARCHAR(100),
                found_photo TEXT,
                resolved_by VARCHAR(50),
                resolved_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # 6. Medical Camps table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS medical_camps (
                id SERIAL PRIMARY KEY,
                camp_id VARCHAR(50) UNIQUE NOT NULL,
                name VARCHAR(255) NOT NULL,
                location_name VARCHAR(255) NOT NULL,
                latitude DOUBLE PRECISION NOT NULL,
                longitude DOUBLE PRECISION NOT NULL,
                contact_phone VARCHAR(50),
                doctor_in_charge VARCHAR(255),
                operating_hours VARCHAR(100) DEFAULT '24/7',
                status VARCHAR(50) DEFAULT 'ACTIVE',
                emergency_capability VARCHAR(100) DEFAULT 'High',
                patient_count INT DEFAULT 0,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # 7. Medicine & Inventory Stock table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS medicines (
                id SERIAL PRIMARY KEY,
                item_id VARCHAR(50) UNIQUE NOT NULL,
                name VARCHAR(255) NOT NULL,
                category VARCHAR(100) NOT NULL,
                camp_id VARCHAR(50) REFERENCES medical_camps(camp_id) ON DELETE CASCADE,
                available_quantity INT NOT NULL DEFAULT 0,
                total_capacity INT NOT NULL DEFAULT 100,
                unit VARCHAR(50) DEFAULT 'packs',
                expiry_date VARCHAR(50),
                status VARCHAR(50) DEFAULT 'In Stock',
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # 8. Food & Water Points table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS food_water_points (
                id SERIAL PRIMARY KEY,
                point_id VARCHAR(50) UNIQUE NOT NULL,
                type VARCHAR(50) NOT NULL,
                name VARCHAR(255) NOT NULL,
                location_name VARCHAR(255) NOT NULL,
                latitude DOUBLE PRECISION NOT NULL,
                longitude DOUBLE PRECISION NOT NULL,
                status VARCHAR(50) DEFAULT 'AVAILABLE',
                capacity_liters_or_meals INT DEFAULT 1000,
                available_amount INT DEFAULT 1000,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # 9. Notifications table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS notifications (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                message TEXT NOT NULL,
                category VARCHAR(50) NOT NULL,
                severity VARCHAR(50) DEFAULT 'INFO',
                is_read BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # 10. Admin Users table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS admin_users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                password VARCHAR(100) NOT NULL,
                full_name VARCHAR(255) NOT NULL,
                role VARCHAR(50) DEFAULT 'SUPER_ADMIN',
                email VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)

        # Insert default admin user if not exists
        cursor.execute("""
            INSERT INTO admin_users (username, password, full_name, role, email)
            VALUES ('admin', 'admin123', 'VariPath Command Center Admin', 'SUPER_ADMIN', 'admin@varipath.org')
            ON CONFLICT (username) DO NOTHING;
        """)

        conn.commit()
        cursor.close()
        conn.close()
        print("Database initialized successfully with all Organizer dashboard tables.")
    except Exception as e:
        print("Database initialization note:", e)



try:
    init_db()
except Exception as e:
    print("DB init error:", e)


def home():
    return jsonify({
        "success": True,
        "message": "VariPath backend is running"
    })


# ============================================================
# LOGIN
# ============================================================

@app.route("/login", methods=["POST"])
def login():

    data = request.get_json()

    username = data.get("username", "").strip().upper()
    password = data.get("password", "").strip()
    user_type = data.get("user_type", "").strip().upper()

    if not username or not password or not user_type:
        return jsonify({
            "success": False,
            "message": "All login fields are required."
        }), 400

    # Validate username format
    if user_type == "VT":
        if not re.fullmatch(r"VT\d{3}", username):
            return jsonify({
                "success": False,
                "message": "Invalid volunteer username format."
            }), 400

    elif user_type == "VK":
        if not re.fullmatch(r"VK\d{6}", username):
            return jsonify({
                "success": False,
                "message": "Invalid Varkari username format."
            }), 400

    else:
        return jsonify({
            "success": False,
            "message": "Invalid user type."
        }), 400

    try:

        conn = get_db_connection()
        cursor = conn.cursor(
            cursor_factory=psycopg2.extras.RealDictCursor
        )

        cursor.execute(
            """
            SELECT
                id,
                username,
                user_type,
                first_name,
                last_name,
                date_of_birth,
                age,
                gender,
                phone,
                emergency_contact,
                blood_group,
                health_conditions
            FROM users
            WHERE username = %s
              AND password = %s
              AND user_type = %s
            """,
            (username, password, user_type)
        )

        user = cursor.fetchone()

        cursor.close()
        conn.close()

        if user is None:
            return jsonify({
                "success": False,
                "message": "Incorrect username or password."
            }), 401

        # Convert PostgreSQL date to string
        if user.get("date_of_birth"):
            user["date_of_birth"] = user[
                "date_of_birth"
            ].isoformat()

        return jsonify({
            "success": True,
            "message": "Login successful.",
            "user": user
        }), 200

    except Exception as e:

        print("LOGIN ERROR:", e)

        return jsonify({
            "success": False,
            "message": "Database connection error."
        }), 500


# ============================================================
# REGISTER
# ============================================================

@app.route("/register", methods=["POST"])
def register():

    data = request.get_json()

    required_fields = [
        "user_type",
        "password",
        "first_name",
        "last_name",
        "date_of_birth",
        "age",
        "gender",
        "phone",
        "emergency_contact",
        "blood_group",
        "health_conditions"
    ]

    # --------------------------------------------------------
    # CHECK ALL FIELDS
    # --------------------------------------------------------

    for field in required_fields:

        if field not in data:
            return jsonify({
                "success": False,
                "message": f"{field} is required."
            }), 400

    user_type = str(data["user_type"]).upper()
    password = str(data["password"])

    first_name = str(data["first_name"]).strip()
    last_name = str(data["last_name"]).strip()
    date_of_birth = data["date_of_birth"]
    age = data["age"]
    gender = data["gender"]
    phone = str(data["phone"]).strip()
    emergency_contact = str(
        data["emergency_contact"]
    ).strip()
    blood_group = data["blood_group"]
    health_conditions = data["health_conditions"]

    # --------------------------------------------------------
    # VALIDATION
    # --------------------------------------------------------

    if user_type not in ["VT", "VK"]:
        return jsonify({
            "success": False,
            "message": "Invalid user type."
        }), 400

    if not re.fullmatch(r"[A-Za-z0-9]{4}", password):
        return jsonify({
            "success": False,
            "message": "Password must contain exactly 4 letters/numbers."
        }), 400

    if not first_name or not last_name:
        return jsonify({
            "success": False,
            "message": "First name and last name are required."
        }), 400

    try:
        age = int(age)
    except:
        return jsonify({
            "success": False,
            "message": "Invalid age."
        }), 400

    if age < 16 or age > 86:
        return jsonify({
            "success": False,
            "message": "Age must be between 16 and 86."
        }), 400

    if gender not in ["Male", "Female", "Other"]:
        return jsonify({
            "success": False,
            "message": "Invalid gender."
        }), 400

    if not re.fullmatch(r"\d{10}", phone):
        return jsonify({
            "success": False,
            "message": "Phone number must contain 10 digits."
        }), 400

    if not re.fullmatch(r"\d{10}", emergency_contact):
        return jsonify({
            "success": False,
            "message": "Emergency contact must contain 10 digits."
        }), 400

    if not isinstance(health_conditions, list) \
            or len(health_conditions) == 0:

        return jsonify({
            "success": False,
            "message": "Select at least one health condition."
        }), 400

    # --------------------------------------------------------
    # GENERATE USERNAME
    # --------------------------------------------------------

    try:

        conn = get_db_connection()
        cursor = conn.cursor()

        if user_type == "VT":

            cursor.execute(
                """
                SELECT username
                FROM users
                WHERE user_type = 'VT'
                ORDER BY username DESC
                LIMIT 1
                """
            )

            last_user = cursor.fetchone()

            if last_user:
                last_number = int(
                    last_user[0][2:]
                )
                new_number = last_number + 1
            else:
                new_number = 101

            username = f"VT{new_number:03d}"

        else:

            cursor.execute(
                """
                SELECT username
                FROM users
                WHERE user_type = 'VK'
                ORDER BY username DESC
                LIMIT 1
                """
            )

            last_user = cursor.fetchone()

            if last_user:
                last_number = int(
                    last_user[0][2:]
                )
                new_number = last_number + 1
            else:
                new_number = 100001

            username = f"VK{new_number:06d}"

        # ----------------------------------------------------
        # INSERT USER
        # ----------------------------------------------------

        cursor.execute(
            """
            INSERT INTO users (
                username,
                password,
                user_type,
                first_name,
                last_name,
                date_of_birth,
                age,
                gender,
                phone,
                emergency_contact,
                blood_group,
                health_conditions
            )
            VALUES (
                %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s
            )
            """,
            (
                username,
                password,
                user_type,
                first_name,
                last_name,
                date_of_birth,
                age,
                gender,
                phone,
                emergency_contact,
                blood_group,
                health_conditions
            )
        )

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "message": "Registration successful.",
            "username": username,
            "password": password
        }), 201

    except psycopg2.errors.UniqueViolation:

        conn.rollback()
        cursor.close()
        conn.close()

        return jsonify({
            "success": False,
            "message": "Phone number or username already exists."
        }), 409

    except Exception as e:

        print("REGISTER ERROR:", e)

        try:
            conn.rollback()
            cursor.close()
            conn.close()
        except:
            pass

        return jsonify({
            "success": False,
            "message": "Registration failed."
        }), 500


# ============================================================
# SEARCH USERS
# ============================================================

@app.route("/users/search", methods=["GET"])
def search_users():

    query = request.args.get("query", "").strip()

    try:

        conn = get_db_connection()

        cursor = conn.cursor(
            cursor_factory=psycopg2.extras.RealDictCursor
        )

        if query:

            search_term = f"%{query}%"

            cursor.execute(
                """
                SELECT
                    u.id,
                    u.username,
                    u.user_type,
                    u.first_name,
                    u.last_name,
                    u.date_of_birth,
                    u.age,
                    u.gender,
                    u.phone,
                    u.emergency_contact,
                    u.blood_group,
                    u.health_conditions,
                    COALESCE(ul.latitude, vl.latitude) AS latitude,
                    COALESCE(ul.longitude, vl.longitude) AS longitude,
                    COALESCE(ul.updated_at, vl.updated_at) AS location_updated_at
                FROM users u
                LEFT JOIN user_locations ul ON u.username = ul.username
                LEFT JOIN volunteer_locations vl ON u.username = vl.volunteer_username
                WHERE
                    LOWER(u.first_name) LIKE LOWER(%s)
                    OR LOWER(u.last_name) LIKE LOWER(%s)
                    OR LOWER(
                        u.first_name || ' ' || u.last_name
                    ) LIKE LOWER(%s)
                    OR LOWER(u.username) LIKE LOWER(%s)
                ORDER BY
                    u.first_name,
                    u.last_name
                LIMIT 50
                """,
                (
                    search_term,
                    search_term,
                    search_term,
                    search_term
                )
            )

        else:

            cursor.execute(
                """
                SELECT
                    u.id,
                    u.username,
                    u.user_type,
                    u.first_name,
                    u.last_name,
                    u.date_of_birth,
                    u.age,
                    u.gender,
                    u.phone,
                    u.emergency_contact,
                    u.blood_group,
                    u.health_conditions,
                    COALESCE(ul.latitude, vl.latitude) AS latitude,
                    COALESCE(ul.longitude, vl.longitude) AS longitude,
                    COALESCE(ul.updated_at, vl.updated_at) AS location_updated_at
                FROM users u
                LEFT JOIN user_locations ul ON u.username = ul.username
                LEFT JOIN volunteer_locations vl ON u.username = vl.volunteer_username
                ORDER BY
                    u.first_name,
                    u.last_name
                LIMIT 50
                """
            )

        users = cursor.fetchall()

        # Convert PostgreSQL dates to strings
        for user in users:
            if user.get("date_of_birth"):
                user["date_of_birth"] = (
                    user["date_of_birth"].isoformat()
                )

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "users": users
        }), 200

    except Exception as e:

        print("SEARCH ERROR:", e)

        return jsonify({
            "success": False,
            "message": "Unable to search users."
        }), 500

# ============================================================
# CALCULATE DISTANCE BETWEEN TWO GPS LOCATIONS
# ============================================================

def calculate_distance_km(
    lat1,
    lon1,
    lat2,
    lon2
):

    earth_radius_km = 6371

    lat1 = math.radians(float(lat1))
    lon1 = math.radians(float(lon1))
    lat2 = math.radians(float(lat2))
    lon2 = math.radians(float(lon2))

    delta_lat = lat2 - lat1
    delta_lon = lon2 - lon1

    a = (
        math.sin(delta_lat / 2) ** 2
        +
        math.cos(lat1)
        *
        math.cos(lat2)
        *
        math.sin(delta_lon / 2) ** 2
    )

    c = 2 * math.atan2(
        math.sqrt(a),
        math.sqrt(1 - a)
    )

    return earth_radius_km * c

# ============================================================
# CREATE ASSISTANCE REQUEST
# ============================================================

@app.route(
    "/assistance-requests",
    methods=["POST"]
)
def create_assistance_request():

    data = request.get_json() or {}

    varkari_username = data.get(
        "varkari_username",
        ""
    ).strip().upper()

    problem_description = data.get(
        "problem_description",
        ""
    ).strip()

    latitude = data.get("latitude")
    longitude = data.get("longitude")

    # --------------------------------------------------------
    # VALIDATION
    # --------------------------------------------------------

    if not varkari_username:

        return jsonify({
            "success": False,
            "message": "Varkari ID is required."
        }), 400

    if not problem_description:

        return jsonify({
            "success": False,
            "message": "Emergency description is required."
        }), 400

    if latitude is None or longitude is None:

        return jsonify({
            "success": False,
            "message": "GPS location is required."
        }), 400

    try:

        latitude = float(latitude)
        longitude = float(longitude)

    except (TypeError, ValueError):

        return jsonify({
            "success": False,
            "message": "Invalid GPS coordinates."
        }), 400

    try:

        conn = get_db_connection()

        cursor = conn.cursor(
            cursor_factory=psycopg2.extras.RealDictCursor
        )

        # ----------------------------------------------------
        # CHECK VARKARI EXISTS
        # ----------------------------------------------------

        cursor.execute(
            """
            SELECT username
            FROM users
            WHERE username = %s
              AND user_type = 'VK'
            """,
            (varkari_username,)
        )

        varkari = cursor.fetchone()

        if varkari is None:

            cursor.close()
            conn.close()

            return jsonify({
                "success": False,
                "message": "Varkari not found."
            }), 404

        # ----------------------------------------------------
        # DO NOT ALLOW MULTIPLE ACTIVE SOS REQUESTS
        # ----------------------------------------------------

        cursor.execute(
            """
            SELECT id
            FROM assistance_requests
            WHERE
                varkari_username = %s
                AND status IN (
                    'PENDING',
                    'ASSIGNED'
                )
            """,
            (varkari_username,)
        )

        existing_request = cursor.fetchone()

        if existing_request:

            cursor.close()
            conn.close()

            return jsonify({
                "success": False,
                "message": "You already have an active SOS request."
            }), 409

        # ----------------------------------------------------
        # GET ALL ACTIVE VOLUNTEERS WITH RECENT GPS
        #
        # Only locations updated within the last 5 minutes
        # are considered active.
        # ----------------------------------------------------

        cursor.execute(
            """
            SELECT
                volunteer_username,
                latitude,
                longitude
            FROM volunteer_locations
            WHERE
                is_active = TRUE
                AND updated_at >=
                    CURRENT_TIMESTAMP
                    - INTERVAL '5 minutes'
            """
        )

        volunteers = cursor.fetchall()

        # ----------------------------------------------------
        # FIND THE NEAREST VOLUNTEER
        # ----------------------------------------------------

        nearest_volunteer = None
        nearest_distance = None

        for volunteer in volunteers:

            distance = calculate_distance_km(
                latitude,
                longitude,
                volunteer["latitude"],
                volunteer["longitude"]
            )

            if (
                nearest_distance is None
                or distance < nearest_distance
            ):

                nearest_distance = distance

                nearest_volunteer = (
                    volunteer["volunteer_username"]
                )

        # ----------------------------------------------------
        # GENERATE REQUEST CODE
        # ----------------------------------------------------

        request_code = (
            "REQ-"
            +
            datetime.now().strftime(
                "%Y%m%d%H%M%S%f"
            )
        )

        # ----------------------------------------------------
        # CREATE REQUEST
        #
        # If a volunteer is available:
        # immediately assign it to the nearest volunteer.
        #
        # Otherwise:
        # keep it PENDING.
        # ----------------------------------------------------

        # ----------------------------------------------------
        # CREATE REQUEST AS PENDING (VOLUNTEER MUST APPROVE)
        # ----------------------------------------------------

        cursor.execute(
            """
            INSERT INTO assistance_requests (
                request_code,
                varkari_username,
                problem_description,
                latitude,
                longitude,
                status
            )
            VALUES (
                %s, %s, %s, %s, %s,
                'PENDING'
            )
            RETURNING
                id,
                request_code
            """,
            (
                request_code,
                varkari_username,
                problem_description,
                latitude,
                longitude
            )
        )

        new_request = cursor.fetchone()

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "request_id": new_request["id"],
            "request_code":
                new_request["request_code"],

            "assigned_volunteer": None,

            "distance_km":
                round(nearest_distance, 2)
                if nearest_distance is not None
                else None,

            "message": "SOS request created. Waiting for a volunteer to accept."
        }), 201

    except Exception as e:

        print("CREATE SOS ERROR:", e)

        return jsonify({
            "success": False,
            "message": "Unable to create SOS request."
        }), 500


# ============================================================
# EXOTEL IVR INCOMING CALL / PASSTHRU WEBHOOK
# ============================================================

DTMF_CATEGORY_MAP = {
    "1": "Medical Assist: IVR Emergency Call (DTMF 1)",
    "2": "Accident Alert: IVR Emergency Call (DTMF 2)",
    "3": "Other Assistance: IVR Call (DTMF 3 - Route/Water/Lost)",
}

@app.route("/api/exotel/incoming-call", methods=["GET", "POST"])
def exotel_incoming_call():
    """
    Exotel Passthru / Gather Webhook for IVR Emergency SOS.
    Parameters handled:
      - CallSid: Unique call identifier (used for duplicate protection)
      - CallFrom / From: Caller's phone number
      - digits / Digits: DTMF digits (Emergency type 1/2/3 OR 3-digit Location Code like 037)
      - category / emergency_type: Explicit DTMF category (1, 2, or 3) when chained with Gather 2
    """
    try:
        # 1. Collect parameters from GET query string, POST form, or JSON
        params = {}
        if request.args:
            params.update(request.args.to_dict())
        if request.is_json:
            json_data = request.get_json(silent=True)
            if json_data and isinstance(json_data, dict):
                params.update(json_data)
        elif request.form:
            params.update(request.form.to_dict())

        # Safe logging for development / debugging
        print(f"[EXOTEL WEBHOOK] Method: {request.method} | Params: {params}")

        # 2. Extract & normalize CallSid
        raw_call_sid = params.get("CallSid") or params.get("call_sid") or params.get("callSid") or ""
        call_sid = str(raw_call_sid).strip()

        # 3. Extract & normalize CallFrom / From
        raw_call_from = params.get("CallFrom") or params.get("From") or params.get("from") or params.get("callFrom") or ""
        raw_phone_digits = re.sub(r"\D", "", str(raw_call_from))
        clean_phone = raw_phone_digits[-10:] if len(raw_phone_digits) >= 10 else ""

        # 4. Extract & normalize category and digits/location code
        raw_category = params.get("category") or params.get("emergency_type") or ""
        clean_category = str(raw_category).strip().strip("'").strip('"').strip()

        raw_digits = params.get("digits") or params.get("Digits") or params.get("location_code") or ""
        clean_digits = str(raw_digits).strip().strip("'").strip('"').strip()

        # 5. Validations
        if not call_sid:
            return jsonify({
                "success": False,
                "message": "CallSid parameter is required."
            }), 400

        if not clean_phone or len(clean_phone) != 10:
            return jsonify({
                "success": False,
                "message": f"Valid 10-digit caller phone number (CallFrom) is required. Received: '{raw_call_from}'."
            }), 400

        # Determine emergency category and location digits:
        # Scenario A: Explicit category passed via URL query parameter (e.g. category=1, digits=037)
        # Scenario B: Standard single-digit smartphone flow (digits=1, category not provided)
        # Scenario C: 3-digit code entered in digits without category (defaults to Medical Assist '1')
        emergency_digit = ""
        location_digits = ""

        if clean_category in ["1", "2", "3"]:
            emergency_digit = clean_category
            location_digits = clean_digits if clean_digits != clean_category else ""
        elif clean_digits in ["1", "2", "3"] and not clean_category:
            emergency_digit = clean_digits
            location_digits = ""
        elif len(clean_digits) == 3 and clean_digits.isdigit():
            emergency_digit = "1"  # Default to Medical Assist
            location_digits = clean_digits
        else:
            return jsonify({
                "success": False,
                "message": f"Invalid or missing emergency category: category='{clean_category}', digits='{clean_digits}'. Accepted categories are '1', '2', or '3'."
            }), 400

        # Map DTMF to emergency category
        problem_description = DTMF_CATEGORY_MAP.get(emergency_digit, "General SOS: IVR Call")

        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        # 6. Duplicate Protection: Check if CallSid was already processed
        cursor.execute(
            """
            SELECT id, request_code, problem_description, status, latitude, longitude, location_code, location_source, created_at
            FROM assistance_requests
            WHERE call_sid = %s
            LIMIT 1
            """,
            (call_sid,)
        )
        existing_call = cursor.fetchone()
        if existing_call:
            cursor.close()
            conn.close()
            print(f"[EXOTEL WEBHOOK] Duplicate CallSid '{call_sid}' already processed (Request Code: {existing_call['request_code']}). Returning 200 OK.")
            return jsonify({
                "success": True,
                "duplicate": True,
                "request_id": existing_call["id"],
                "request_code": existing_call["request_code"],
                "status": existing_call["status"],
                "latitude": existing_call["latitude"],
                "longitude": existing_call["longitude"],
                "location_code": existing_call.get("location_code"),
                "location_source": existing_call.get("location_source"),
                "message": "CallSid already processed."
            }), 200

        # 7. User lookup & guest auto-registration
        cursor.execute(
            """
            SELECT username, first_name, last_name, phone, blood_group, health_conditions
            FROM users
            WHERE phone = %s AND user_type = 'VK'
            ORDER BY id ASC
            LIMIT 1
            """,
            (clean_phone,)
        )
        user_record = cursor.fetchone()

        if user_record:
            varkari_username = user_record["username"]
            varkari_name = f"{user_record.get('first_name', '') or ''} {user_record.get('last_name', '') or ''}".strip() or varkari_username
        else:
            # Check if guest user was already created previously for this phone
            guest_username = f"VK{clean_phone}"
            cursor.execute(
                """
                SELECT username, first_name, last_name
                FROM users
                WHERE username = %s
                LIMIT 1
                """,
                (guest_username,)
            )
            guest_exists = cursor.fetchone()
            if not guest_exists:
                cursor.execute(
                    """
                    INSERT INTO users (
                        username, password, user_type, first_name, last_name,
                        age, gender, phone, emergency_contact, blood_group, health_conditions, date_of_birth
                    ) VALUES (
                        %s, '0000', 'VK', 'IVR Caller', %s,
                        35, 'Other', %s, %s, 'Unknown', ARRAY['Feature Phone / IVR Caller'], '1990-01-01'
                    )
                    """,
                    (
                        guest_username,
                        clean_phone,
                        clean_phone,
                        clean_phone
                    )
                )
                conn.commit()
            varkari_username = guest_username
            varkari_name = f"IVR Caller {clean_phone}"

        # 8. Location Resolution & Routing Logic:
        # -------------------------------------------------------------
        # SCENARIO A: Location code provided (Gather 2 - Keypad Flow)
        # -------------------------------------------------------------
        if location_digits and len(location_digits) >= 1:
            location_code = None
            location_source = "UNAVAILABLE"
            latitude = None
            longitude = None

            clean_code = location_digits.upper()
            formatted_code = f"VP-{clean_code.zfill(3)}" if clean_code.isdigit() else clean_code

            # Use EXACT requested SQL lookup:
            cursor.execute(
                """
                SELECT location_code, name, latitude, longitude
                FROM vaaripath_location_codes
                WHERE (location_code = %s OR location_code = %s)
                  AND active = TRUE
                LIMIT 1
                """,
                (clean_code, formatted_code)
            )
            loc_record = cursor.fetchone()
            if loc_record:
                location_code = loc_record["location_code"]
                latitude = loc_record["latitude"]
                longitude = loc_record["longitude"]
                location_source = "VAARIPATH_CODE"
                print(f"[EXOTEL WEBHOOK] Keypad Location Resolved: '{clean_code}' -> {location_code} ({loc_record['name']}) at ({latitude}, {longitude})")
            else:
                # Invalid location code -> fallback to user GPS if available, else UNAVAILABLE
                if user_record:
                    cursor.execute(
                        """
                        SELECT latitude, longitude
                        FROM user_locations
                        WHERE username = %s
                        ORDER BY updated_at DESC
                        LIMIT 1
                        """,
                        (varkari_username,)
                    )
                    user_loc = cursor.fetchone()
                    if user_loc and user_loc.get("latitude") is not None and user_loc.get("longitude") is not None:
                        latitude = user_loc["latitude"]
                        longitude = user_loc["longitude"]
                        location_source = "GPS"

        # -------------------------------------------------------------
        # SCENARIO B: No location code provided (Router Passthru 1 Stage)
        # -------------------------------------------------------------
        else:
            # Check if caller has an active, recent GPS fix in user_locations
            user_loc = None
            if user_record:
                cursor.execute(
                    """
                    SELECT latitude, longitude
                    FROM user_locations
                    WHERE username = %s
                    ORDER BY updated_at DESC
                    LIMIT 1
                    """,
                    (varkari_username,)
                )
                user_loc = cursor.fetchone()

            if user_loc and user_loc.get("latitude") is not None and user_loc.get("longitude") is not None:
                # Registered user WITH active GPS -> Create SOS immediately
                latitude = user_loc["latitude"]
                longitude = user_loc["longitude"]
                location_code = None
                location_source = "GPS"
                print(f"[EXOTEL WEBHOOK] Smartphone User '{varkari_username}' verified with GPS ({latitude}, {longitude}). Creating immediate SOS.")
            else:
                # Unknown user OR registered user WITHOUT GPS -> Route to Location Code Gather
                cursor.close()
                conn.close()
                print(f"[EXOTEL WEBHOOK] Caller '{clean_phone}' has NO active GPS. Returning 404 to route into Location Code Gather.")
                return jsonify({
                    "success": False,
                    "route": "REQUIRE_LOCATION_CODE",
                    "caller_phone": clean_phone,
                    "category": emergency_digit,
                    "message": "No active GPS session found. Exotel Passthru failure branch will prompt for 3-digit location code."
                }), 404

        # 9. Generate Request Code (high resolution to ensure uniqueness)
        request_code = "REQ-EXO-" + datetime.now().strftime("%Y%m%d%H%M%S%f")

        # 10. Create Assistance Request with status = 'PENDING'
        cursor.execute(
            """
            INSERT INTO assistance_requests (
                request_code,
                varkari_username,
                varkari_name,
                problem_description,
                latitude,
                longitude,
                location_code,
                location_source,
                status,
                assigned_volunteer_username,
                call_sid
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, 'PENDING', NULL, %s
            )
            RETURNING id, request_code, created_at
            """,
            (
                request_code,
                varkari_username,
                varkari_name,
                problem_description,
                latitude,
                longitude,
                location_code,
                location_source,
                call_sid
            )
        )
        new_request = cursor.fetchone()
        conn.commit()

        cursor.close()
        conn.close()

        print(f"[EXOTEL WEBHOOK] Created SOS request: ID={new_request['id']}, Code={new_request['request_code']}, Phone={clean_phone}, Category={emergency_digit}, LocCode={location_code}, Source={location_source}")

        return jsonify({
            "success": True,
            "request_id": new_request["id"],
            "request_code": new_request["request_code"],
            "call_sid": call_sid,
            "caller_phone": clean_phone,
            "varkari_username": varkari_username,
            "problem_description": problem_description,
            "status": "PENDING",
            "latitude": latitude,
            "longitude": longitude,
            "location_code": location_code,
            "location_source": location_source,
            "message": "IVR SOS request created successfully."
        }), 200

    except Exception as e:
        print("[EXOTEL WEBHOOK] Error handling incoming call:", e)
        return jsonify({
            "success": False,
            "message": f"Server error processing IVR call: {str(e)}"
        }), 500


# ============================================================
# AUTO-ESCALATE SOS REQUESTS UNCONFIRMED AFTER 10 MINUTES
# ============================================================

def escalate_expired_requests(conn):
    try:
        cursor = conn.cursor(
            cursor_factory=psycopg2.extras.RealDictCursor
        )

        cursor.execute(
            """
            SELECT
                id,
                latitude,
                longitude,
                assigned_volunteer_username,
                declined_volunteers
            FROM assistance_requests
            WHERE
                status = 'ASSIGNED'
                AND (varkari_reached IS FALSE OR varkari_reached IS NULL)
                AND (volunteer_done IS FALSE OR volunteer_done IS NULL)
                AND assigned_at <= CURRENT_TIMESTAMP - INTERVAL '10 minutes'
            """
        )

        expired_requests = cursor.fetchall()

        for req in expired_requests:
            req_id = req["id"]
            req_lat = req["latitude"]
            req_lng = req["longitude"]
            curr_vol = req["assigned_volunteer_username"]
            declined = req.get("declined_volunteers") or []

            if curr_vol and curr_vol not in declined:
                declined = list(declined)
                declined.append(curr_vol)

            cursor.execute(
                """
                SELECT
                    volunteer_username,
                    latitude,
                    longitude
                FROM volunteer_locations
                WHERE
                    is_active = TRUE
                    AND updated_at >=
                        CURRENT_TIMESTAMP - INTERVAL '5 minutes'
                """
            )

            active_vols = cursor.fetchall()

            next_volunteer = None
            next_distance = None

            for vol in active_vols:
                v_user = vol["volunteer_username"]
                if v_user in declined:
                    continue

                dist = calculate_distance_km(
                    req_lat,
                    req_lng,
                    vol["latitude"],
                    vol["longitude"]
                )

                if next_distance is None or dist < next_distance:
                    next_distance = dist
                    next_volunteer = v_user

            cursor.execute(
                """
                UPDATE assistance_requests
                SET
                    status = 'PENDING',
                    assigned_volunteer_username = NULL,
                    declined_volunteers = %s
                WHERE id = %s
                """,
                (declined, req_id)
            )

        conn.commit()

    except Exception as e:
        print("AUTO ESCALATION ERROR:", e)


# ============================================================
# GET ACTIVE REQUEST FOR VARKARI
# ============================================================

@app.route(
    "/assistance-requests/varkari/<username>",
    methods=["GET"]
)
def get_varkari_request(username):

    username = username.strip().upper()

    try:

        conn = get_db_connection()

        # Run 10-minute auto escalation check
        escalate_expired_requests(conn)

        cursor = conn.cursor(
            cursor_factory=psycopg2.extras.RealDictCursor
        )

        cursor.execute(
            """
            SELECT
                ar.id,
                ar.request_code,
                ar.problem_description,
                ar.status,
                ar.latitude as varkari_latitude,
                ar.longitude as varkari_longitude,
                ar.varkari_username,
                ar.assigned_volunteer_username,
                ar.volunteer_done,
                ar.varkari_reached,
                ar.created_at,
                vl.latitude as volunteer_latitude,
                vl.longitude as volunteer_longitude,
                u_vol.first_name as volunteer_first_name,
                u_vol.last_name as volunteer_last_name,
                u_vol.phone as volunteer_phone
            FROM assistance_requests ar
            LEFT JOIN volunteer_locations vl ON ar.assigned_volunteer_username = vl.volunteer_username
            LEFT JOIN users u_vol ON ar.assigned_volunteer_username = u_vol.username
            WHERE
                ar.varkari_username = %s
                AND ar.status IN ('PENDING', 'ASSIGNED')
                AND NOT (
                    ar.volunteer_done IS TRUE
                    AND ar.varkari_reached IS TRUE
                )
            ORDER BY ar.created_at DESC
            LIMIT 1
            """,
            (username,)
        )

        request_data = cursor.fetchone()

        if request_data and request_data.get(
            "created_at"
        ):
            request_data["created_at"] = (
                request_data["created_at"].isoformat()
            )

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "request": request_data
        }), 200

    except Exception as e:

        print("VARKARI REQUEST ERROR:", e)

        return jsonify({
            "success": False,
            "message": "Unable to load SOS status."
        }), 500

# ============================================================
# GET VOLUNTEER REQUESTS
# ============================================================

@app.route(
    "/assistance-requests/volunteer/<username>",
    methods=["GET"]
)
def get_volunteer_requests(username):

    username = username.strip().upper()

    try:

        conn = get_db_connection()

        # Run 10-minute auto escalation check
        escalate_expired_requests(conn)

        cursor = conn.cursor(
            cursor_factory=psycopg2.extras.RealDictCursor
        )

        cursor.execute(
            """
            SELECT
                ar.id,
                ar.request_code,
                ar.varkari_username,
                ar.problem_description,
                ar.status,
                ar.latitude as varkari_latitude,
                ar.longitude as varkari_longitude,
                ar.location_code,
                ar.location_source,
                vlc.name as location_name,
                ar.assigned_volunteer_username,
                ar.volunteer_done,
                ar.varkari_reached,
                ar.created_at,

                u.first_name,
                u.last_name,
                u.phone,
                u.blood_group,
                u.health_conditions,

                vl.latitude as volunteer_latitude,
                vl.longitude as volunteer_longitude

            FROM assistance_requests ar

            JOIN users u
                ON ar.varkari_username =
                   u.username

            LEFT JOIN vaaripath_location_codes vlc
                ON ar.location_code = vlc.location_code

            LEFT JOIN volunteer_locations vl
                ON ar.assigned_volunteer_username = vl.volunteer_username

            WHERE
                (
                    ar.assigned_volunteer_username = %s
                    OR ar.assigned_volunteer_username IS NULL
                )
                AND ar.status IN (
                    'PENDING',
                    'ASSIGNED'
                )
                AND NOT (
                    ar.volunteer_done IS TRUE
                    AND ar.varkari_reached IS TRUE
                )

            ORDER BY ar.created_at DESC
            """,
            (username,)
        )

        requests = cursor.fetchall()

        for item in requests:
            if item.get("created_at"):
                item["created_at"] = (
                    item["created_at"].isoformat()
                )

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "requests": requests
        }), 200

    except Exception as e:

        print("VOLUNTEER REQUEST ERROR:", e)

        return jsonify({
            "success": False,
            "message": "Unable to load requests."
        }), 500


# ============================================================
# ACCEPT ASSISTANCE REQUEST
# ============================================================

@app.route(
    "/assistance-requests/<int:request_id>/accept",
    methods=["POST"]
)
def accept_assistance_request(request_id):

    data = request.get_json() or {}

    volunteer_username = data.get(
        "volunteer_username",
        ""
    ).strip().upper()

    if not volunteer_username:
        return jsonify({
            "success": False,
            "message": "Volunteer username is required."
        }), 400

    try:

        conn = get_db_connection()

        cursor = conn.cursor(
            cursor_factory=psycopg2.extras.RealDictCursor
        )

        cursor.execute(
            """
            UPDATE assistance_requests
            SET
                status = 'ASSIGNED',
                assigned_volunteer_username = %s,
                assigned_at = CURRENT_TIMESTAMP
            WHERE
                id = %s
                AND (
                    status = 'PENDING'
                    OR (status = 'ASSIGNED' AND assigned_volunteer_username = %s)
                )
            RETURNING
                id,
                request_code,
                status,
                assigned_volunteer_username,
                volunteer_done,
                varkari_reached
            """,
            (
                volunteer_username,
                request_id,
                volunteer_username
            )
        )

        updated_request = cursor.fetchone()

        conn.commit()

        cursor.close()
        conn.close()

        if not updated_request:
            return jsonify({
                "success": False,
                "message": "Request not found or no longer available."
            }), 404

        return jsonify({
            "success": True,
            "message": "Request accepted successfully.",
            "request": updated_request
        }), 200

    except Exception as e:

        print("ACCEPT REQUEST ERROR:", e)

        return jsonify({
            "success": False,
            "message": "Unable to accept request."
        }), 500


# ============================================================
# VARKARI CONFIRMS VOLUNTEER REACHED
# ============================================================

@app.route(
    "/assistance-requests/<int:request_id>/varkari-reached",
    methods=["POST"]
)
def varkari_reached_request(request_id):

    try:

        conn = get_db_connection()

        cursor = conn.cursor(
            cursor_factory=psycopg2.extras.RealDictCursor
        )

        cursor.execute(
            """
            SELECT volunteer_done, varkari_reached
            FROM assistance_requests
            WHERE id = %s
            """,
            (request_id,)
        )

        existing = cursor.fetchone()

        if not existing:
            cursor.close()
            conn.close()

            return jsonify({
                "success": False,
                "message": "Request not found."
            }), 404

        volunteer_done = existing.get("volunteer_done") or False
        new_status = 'COMPLETED' if volunteer_done else 'ASSIGNED'

        cursor.execute(
            """
            UPDATE assistance_requests
            SET
                varkari_reached = TRUE,
                status = %s
            WHERE id = %s
            RETURNING
                id,
                request_code,
                status,
                volunteer_done,
                varkari_reached
            """,
            (new_status, request_id)
        )

        updated_request = cursor.fetchone()

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "message": "Volunteer arrival confirmed.",
            "request": updated_request
        }), 200

    except Exception as e:

        print("VARKARI REACHED ERROR:", e)

        return jsonify({
            "success": False,
            "message": "Unable to confirm volunteer arrival."
        }), 500


# ============================================================
# COMPLETE / VOLUNTEER DONE ASSISTANCE REQUEST
# ============================================================

@app.route(
    "/assistance-requests/<int:request_id>/complete",
    methods=["POST"]
)
@app.route(
    "/assistance-requests/<int:request_id>/volunteer-done",
    methods=["POST"]
)
def complete_assistance_request(request_id):

    try:

        conn = get_db_connection()

        cursor = conn.cursor(
            cursor_factory=psycopg2.extras.RealDictCursor
        )

        cursor.execute(
            """
            SELECT varkari_reached
            FROM assistance_requests
            WHERE id = %s
            """,
            (request_id,)
        )

        existing = cursor.fetchone()

        if not existing:
            cursor.close()
            conn.close()

            return jsonify({
                "success": False,
                "message": "Request not found."
            }), 404

        varkari_reached = existing.get("varkari_reached") or False
        new_status = 'COMPLETED' if varkari_reached else 'ASSIGNED'

        cursor.execute(
            """
            UPDATE assistance_requests
            SET
                volunteer_done = TRUE,
                status = %s
            WHERE id = %s
            RETURNING
                id,
                request_code,
                status,
                volunteer_done,
                varkari_reached
            """,
            (new_status, request_id)
        )

        updated_request = cursor.fetchone()

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "message": "Marked as done by volunteer.",
            "request": updated_request
        }), 200

    except Exception as e:

        print("VOLUNTEER DONE ERROR:", e)

        return jsonify({
            "success": False,
            "message": "Unable to mark request as done."
        }), 500



# ============================================================
# UPDATE VOLUNTEER LIVE LOCATION
# ============================================================

@app.route(
    "/volunteer-location",
    methods=["POST"]
)
def update_volunteer_location():

    data = request.get_json() or {}

    volunteer_username = data.get(
        "volunteer_username",
        ""
    ).strip().upper()

    latitude = data.get("latitude")
    longitude = data.get("longitude")

    if not volunteer_username:
        return jsonify({
            "success": False,
            "message": "Volunteer username is required."
        }), 400

    if latitude is None or longitude is None:
        return jsonify({
            "success": False,
            "message": "Volunteer GPS location is required."
        }), 400

    try:

        latitude = float(latitude)
        longitude = float(longitude)

    except (TypeError, ValueError):

        return jsonify({
            "success": False,
            "message": "Invalid GPS coordinates."
        }), 400

    try:

        conn = get_db_connection()

        cursor = conn.cursor(
            cursor_factory=psycopg2.extras.RealDictCursor
        )

        # ----------------------------------------------------
        # VERIFY THAT THIS USER IS A VOLUNTEER
        # ----------------------------------------------------

        cursor.execute(
            """
            SELECT username
            FROM users
            WHERE username = %s
              AND user_type = 'VT'
            """,
            (volunteer_username,)
        )

        volunteer = cursor.fetchone()

        if volunteer is None:

            cursor.close()
            conn.close()

            return jsonify({
                "success": False,
                "message": "Volunteer not found."
            }), 404

        # ----------------------------------------------------
        # INSERT OR UPDATE LIVE LOCATION
        # ----------------------------------------------------

        cursor.execute(
            """
            INSERT INTO volunteer_locations (
                volunteer_username,
                latitude,
                longitude,
                is_active,
                updated_at
            )
            VALUES (
                %s, %s, %s, TRUE, CURRENT_TIMESTAMP
            )

            ON CONFLICT (volunteer_username)

            DO UPDATE SET
                latitude = EXCLUDED.latitude,
                longitude = EXCLUDED.longitude,
                is_active = TRUE,
                updated_at = CURRENT_TIMESTAMP
            """,
            (
                volunteer_username,
                latitude,
                longitude
            )
        )

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "message": "Volunteer location updated."
        }), 200

    except Exception as e:

        print("VOLUNTEER LOCATION ERROR:", e)

        return jsonify({
            "success": False,
            "message": "Unable to update volunteer location."
        }), 500


# ============================================================
# UPDATE GENERAL USER LIVE LOCATION
# ============================================================

@app.route(
    "/user-location",
    methods=["POST"]
)
def update_user_location():

    data = request.get_json() or {}

    username = data.get("username", "").strip().upper()
    latitude = data.get("latitude")
    longitude = data.get("longitude")

    if not username:
        return jsonify({
            "success": False,
            "message": "Username is required."
        }), 400

    if latitude is None or longitude is None:
        return jsonify({
            "success": False,
            "message": "GPS location is required."
        }), 400

    try:
        latitude = float(latitude)
        longitude = float(longitude)
    except (TypeError, ValueError):
        return jsonify({
            "success": False,
            "message": "Invalid GPS coordinates."
        }), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO user_locations (
                username,
                latitude,
                longitude,
                updated_at
            )
            VALUES (%s, %s, %s, CURRENT_TIMESTAMP)
            ON CONFLICT (username)
            DO UPDATE SET
                latitude = EXCLUDED.latitude,
                longitude = EXCLUDED.longitude,
                updated_at = CURRENT_TIMESTAMP
            """,
            (username, latitude, longitude)
        )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "message": "User location updated."
        }), 200
    except Exception as e:
        print("USER LOCATION ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Unable to update user location."
        }), 500


# ============================================================
# RUN SERVER
# ============================================================


# ============================================================
# MISSING PERSONS ENDPOINTS (Merged from varipath2)
# ============================================================

@app.route("/missing-persons", methods=["GET"])
def get_missing_persons():
    """Retrieves all active missing person reports."""
    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute(
            """
            SELECT
                id,
                missing_person_id,
                name,
                age,
                gender,
                contact_number,
                last_seen_location,
                last_seen_datetime,
                physical_description,
                clothes_description,
                other_info,
                photo,
                reporter_id,
                reporter_type,
                reporter_location,
                reporter_latitude,
                reporter_longitude,
                reported_datetime,
                status,
                found_by,
                found_location,
                found_latitude,
                found_longitude,
                found_datetime,
                found_photo,
                verification_status
            FROM missing_persons
            ORDER BY id DESC
            """
        )

        records = cursor.fetchall()
        cursor.close()
        conn.close()

        # Convert timestamps to string
        for r in records:
            if r.get("reported_datetime"):
                r["reported_datetime"] = r["reported_datetime"].isoformat()

        return jsonify({
            "success": True,
            "count": len(records),
            "data": records
        }), 200

    except Exception as e:
        print("GET MISSING PERSONS ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Failed to fetch missing person reports."
        }), 500


@app.route("/missing-persons", methods=["POST"])
def report_missing_person():
    """Submits a new missing person report."""
    data = request.get_json() or {}

    name = data.get("name", "").strip()
    age = data.get("age")
    gender = data.get("gender", "").strip()
    contact_number = data.get("contact_number", "").strip()
    last_seen_location = data.get("last_seen_location", "").strip()
    last_seen_datetime = data.get("last_seen_datetime", "").strip()
    physical_description = data.get("physical_description", "").strip()
    clothes_description = data.get("clothes_description", "").strip()
    other_info = data.get("other_info", "").strip()
    photo = data.get("photo", "")
    reporter_id = data.get("reporter_id", "").strip().upper()
    reporter_type = data.get("reporter_type", "").strip().upper()
    reporter_location = data.get("reporter_location", "").strip()
    reporter_latitude = data.get("reporter_latitude")
    reporter_longitude = data.get("reporter_longitude")

    if not name or age is None or not gender or not last_seen_location or not reporter_id or not reporter_type:
        return jsonify({
            "success": False,
            "message": "Name, age, gender, last seen location, and reporter ID are required."
        }), 400

    try:
        age = int(age)
    except:
        return jsonify({
            "success": False,
            "message": "Invalid age."
        }), 400

    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor()

        # Generate unique missing_person_id (e.g. MP-10001)
        cursor.execute(
            """
            SELECT missing_person_id
            FROM missing_persons
            ORDER BY id DESC
            LIMIT 1
            """
        )
        last_case = cursor.fetchone()
        if last_case and last_case[0].startswith("MP-"):
            try:
                num = int(last_case[0].split("-")[1])
                new_num = num + 1
            except:
                new_num = 10001
        else:
            new_num = 10001

        missing_person_id = f"MP-{new_num}"

        cursor.execute(
            """
            INSERT INTO missing_persons (
                missing_person_id,
                name,
                age,
                gender,
                contact_number,
                last_seen_location,
                last_seen_datetime,
                physical_description,
                clothes_description,
                other_info,
                photo,
                reporter_id,
                reporter_type,
                reporter_location,
                reporter_latitude,
                reporter_longitude,
                status,
                verification_status
            )
            VALUES (
                %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s, %s,
                %s, %s, 'Missing', 'None'
            )
            RETURNING id, missing_person_id, reported_datetime
            """,
            (
                missing_person_id,
                name,
                age,
                gender,
                contact_number,
                last_seen_location,
                last_seen_datetime or datetime.now().strftime("%Y-%m-%d %H:%M"),
                physical_description,
                clothes_description,
                other_info,
                photo,
                reporter_id,
                reporter_type,
                reporter_location,
                reporter_latitude,
                reporter_longitude
            )
        )

        inserted = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "message": "Missing person report submitted successfully.",
            "missing_person_id": missing_person_id,
            "reported_datetime": inserted[2].isoformat() if inserted and inserted[2] else None
        }), 201

    except Exception as e:
        print("REPORT MISSING PERSON ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Failed to submit report to database."
        }), 500


@app.route("/missing-persons/<missing_person_id>/found", methods=["POST"])
def mark_person_found(missing_person_id):
    """Marks a missing person as found (by Varkari or Volunteer), pending verification."""
    data = request.get_json() or {}

    found_by = data.get("found_by", "").strip().upper()
    found_location = data.get("found_location", "").strip()
    found_latitude = data.get("found_latitude")
    found_longitude = data.get("found_longitude")
    found_photo = data.get("found_photo", "")
    found_datetime = data.get("found_datetime", "") or datetime.now().strftime("%Y-%m-%d %H:%M")

    if not found_by:
        return jsonify({
            "success": False,
            "message": "Found by User ID is required."
        }), 400

    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute(
            """
            UPDATE missing_persons
            SET
                status = 'Found - Verification Pending',
                verification_status = 'Pending',
                found_by = %s,
                found_location = %s,
                found_latitude = %s,
                found_longitude = %s,
                found_datetime = %s,
                found_photo = COALESCE(NULLIF(%s, ''), found_photo)
            WHERE missing_person_id = %s
            RETURNING *
            """,
            (
                found_by,
                found_location,
                found_latitude,
                found_longitude,
                found_datetime,
                found_photo,
                missing_person_id
            )
        )

        updated = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        if not updated:
            return jsonify({
                "success": False,
                "message": "Missing person case not found."
            }), 404

        if updated.get("reported_datetime"):
            updated["reported_datetime"] = updated["reported_datetime"].isoformat()

        return jsonify({
            "success": True,
            "message": f"Case {missing_person_id} updated to 'Found - Verification Pending'. Volunteers have been alerted.",
            "data": updated
        }), 200

    except Exception as e:
        print("MARK FOUND ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Failed to update case."
        }), 500


@app.route("/missing-persons/<missing_person_id>/verify", methods=["POST"])
def verify_and_resolve_case(missing_person_id):
    """Authoritative verification by Volunteer: moves case to resolved table and removes from active search."""
    data = request.get_json() or {}
    resolved_by = data.get("resolved_by", "").strip().upper()

    if not resolved_by:
        return jsonify({
            "success": False,
            "message": "Volunteer ID (resolved_by) is required for verification."
        }), 400

    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        # Get existing record
        cursor.execute(
            "SELECT * FROM missing_persons WHERE missing_person_id = %s",
            (missing_person_id,)
        )
        case = cursor.fetchone()

        if not case:
            cursor.close()
            conn.close()
            return jsonify({
                "success": False,
                "message": "Active missing person case not found."
            }), 404

        # Insert into resolved_missing_persons
        cursor.execute(
            """
            INSERT INTO resolved_missing_persons (
                missing_person_id,
                name,
                age,
                gender,
                contact_number,
                last_seen_location,
                last_seen_datetime,
                physical_description,
                clothes_description,
                other_info,
                photo,
                reporter_id,
                reporter_type,
                reporter_location,
                reported_datetime,
                status,
                found_by,
                found_location,
                found_latitude,
                found_longitude,
                found_datetime,
                found_photo,
                resolved_by,
                resolved_datetime
            )
            VALUES (
                %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s, %s,
                %s, 'Found/Resolved', %s, %s, %s, %s,
                %s, %s, %s, CURRENT_TIMESTAMP
            )
            """,
            (
                case["missing_person_id"],
                case["name"],
                case["age"],
                case["gender"],
                case["contact_number"],
                case["last_seen_location"],
                case["last_seen_datetime"],
                case["physical_description"],
                case["clothes_description"],
                case["other_info"],
                case["photo"],
                case["reporter_id"],
                case["reporter_type"],
                case["reporter_location"],
                case["reported_datetime"],
                case["found_by"] or resolved_by,
                case["found_location"],
                case["found_latitude"],
                case["found_longitude"],
                case["found_datetime"],
                case["found_photo"],
                resolved_by
            )
        )

        # Remove from active missing_persons
        cursor.execute(
            "DELETE FROM missing_persons WHERE missing_person_id = %s",
            (missing_person_id,)
        )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "message": f"Case {missing_person_id} has been verified and permanently resolved."
        }), 200

    except Exception as e:
        print("VERIFY CASE ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Failed to verify and resolve case."
        }), 500


@app.route("/missing-persons/<missing_person_id>/flag-false", methods=["POST"])
def flag_false_alarm(missing_person_id):
    """Reverts a 'Found - Verification Pending' case back to 'Missing' if report was false."""
    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute(
            """
            UPDATE missing_persons
            SET
                status = 'Missing',
                verification_status = 'Rejected',
                found_by = NULL,
                found_location = NULL,
                found_latitude = NULL,
                found_longitude = NULL,
                found_datetime = NULL
            WHERE missing_person_id = %s
            RETURNING *
            """,
            (missing_person_id,)
        )

        updated = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        if not updated:
            return jsonify({
                "success": False,
                "message": "Case not found."
            }), 404

        return jsonify({
            "success": True,
            "message": f"Case {missing_person_id} has been reverted to active Missing search.",
            "data": updated
        }), 200

    except Exception as e:
        print("FLAG FALSE ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Failed to flag report."
        }), 500


@app.route("/missing-persons/resolved", methods=["GET"])
def get_resolved_missing_persons():
    """Retrieves resolved cases history."""
    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute(
            """
            SELECT * FROM resolved_missing_persons
            ORDER BY resolved_datetime DESC
            """
        )
        records = cursor.fetchall()
        cursor.close()
        conn.close()

        for r in records:
            if r.get("reported_datetime"):
                r["reported_datetime"] = r["reported_datetime"].isoformat()
            if r.get("resolved_datetime"):
                r["resolved_datetime"] = r["resolved_datetime"].isoformat()

        return jsonify({
            "success": True,
            "count": len(records),
            "data": records
        }), 200

    except Exception as e:
        print("GET RESOLVED ERROR:", e)
        return jsonify({
            "success": False,
            "message": "Failed to fetch resolved cases."
        }), 500


# ============================================================
# ORGANIZER & ADMIN DASHBOARD ENDPOINTS
# ============================================================

@app.route("/admin/login", methods=["POST"])
def admin_login():
    """Authenticates admin users for the dashboard."""
    data = request.get_json() or {}
    username = data.get("username", "").strip()
    password = data.get("password", "").strip()

    if not username or not password:
        return jsonify({"success": False, "message": "Username and password required."}), 400

    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cursor.execute("SELECT id, username, full_name, role, email FROM admin_users WHERE username = %s AND password = %s", (username, password))
        admin = cursor.fetchone()
        cursor.close()
        conn.close()

        if not admin:
            # Fallback check for demo ease
            if username == "admin" and password in ["admin123", "admin"]:
                admin = {
                    "id": 1,
                    "username": "admin",
                    "full_name": "VariPath Command Center Admin",
                    "role": "SUPER_ADMIN",
                    "email": "admin@varipath.org"
                }
            else:
                return jsonify({"success": False, "message": "Invalid credentials."}), 401

        return jsonify({
            "success": True,
            "message": "Admin authentication successful.",
            "token": "varipath_admin_secret_token_2026",
            "admin": admin
        }), 200
    except Exception as e:
        print("ADMIN LOGIN ERROR:", e)
        return jsonify({"success": False, "message": "Authentication failed."}), 500


@app.route("/admin/dashboard-stats", methods=["GET"])
def get_dashboard_stats():
    """Calculates live aggregated KPI metrics for the Command Center."""
    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute("SELECT COUNT(*) AS total FROM users WHERE user_type = 'VK'")
        total_varkaris = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) AS total FROM users WHERE user_type = 'VT'")
        total_volunteers = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) AS total FROM volunteer_locations WHERE is_active = TRUE AND updated_at >= CURRENT_TIMESTAMP - INTERVAL '15 minutes'")
        active_volunteers = cursor.fetchone()["total"]
        if active_volunteers == 0:
            active_volunteers = max(1, total_volunteers)

        cursor.execute("SELECT COUNT(*) AS total FROM assistance_requests WHERE status IN ('PENDING', 'ASSIGNED')")
        active_sos = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) AS total FROM assistance_requests WHERE status IN ('RESOLVED', 'COMPLETED')")
        resolved_sos = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) AS total FROM missing_persons WHERE status != 'Found/Resolved'")
        active_missing = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) AS total FROM resolved_missing_persons")
        resolved_missing = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) AS total FROM medical_camps WHERE status = 'ACTIVE'")
        medical_camps_count = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) AS total FROM medicines WHERE status IN ('Low Stock', 'Critical', 'Out of Stock')")
        critical_medicine_stock = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) AS total FROM food_water_points WHERE status = 'AVAILABLE'")
        active_water_points = cursor.fetchone()["total"]

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "stats": {
                "total_varkaris": total_varkaris,
                "active_volunteers": active_volunteers,
                "total_volunteers": total_volunteers,
                "active_sos": active_sos,
                "resolved_sos": resolved_sos,
                "active_missing": active_missing,
                "found_missing": resolved_missing,
                "medical_camps": medical_camps_count,
                "low_medicine_stock": critical_medicine_stock,
                "active_water_points": active_water_points,
                "heat_risk_zones": 3,
                "system_status": "LIVE — Wari Monitoring Active"
            }
        }), 200
    except Exception as e:
        print("DASHBOARD STATS ERROR:", e)
        return jsonify({"success": False, "message": "Failed to calculate stats."}), 500


@app.route("/varkaris", methods=["GET"])
def get_varkaris():
    """Retrieves all registered Varkaris with latest location and health profile."""
    search_query = request.args.get("query", "").strip()
    status_filter = request.args.get("status", "").strip().upper()

    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        sql = """
            SELECT 
                u.id,
                u.username AS varkari_id,
                u.first_name,
                u.last_name,
                (u.first_name || ' ' || u.last_name) AS name,
                u.age,
                u.gender,
                u.phone,
                u.emergency_contact,
                u.blood_group,
                u.health_conditions,
                u.created_at AS registration_date,
                ul.latitude,
                ul.longitude,
                ul.updated_at AS last_active_time,
                CASE 
                    WHEN ar.id IS NOT NULL THEN 'EMERGENCY'
                    WHEN mp.id IS NOT NULL THEN 'MISSING'
                    WHEN ul.updated_at >= CURRENT_TIMESTAMP - INTERVAL '30 minutes' THEN 'ACTIVE'
                    ELSE 'SAFE'
                END AS status
            FROM users u
            LEFT JOIN user_locations ul ON u.username = ul.username
            LEFT JOIN assistance_requests ar ON u.username = ar.varkari_username AND ar.status IN ('PENDING', 'ASSIGNED')
            LEFT JOIN missing_persons mp ON u.username = mp.reporter_id OR u.first_name || ' ' || u.last_name = mp.name
            WHERE u.user_type = 'VK'
        """

        params = []
        if search_query:
            sql += " AND (LOWER(u.first_name) LIKE LOWER(%s) OR LOWER(u.last_name) LIKE LOWER(%s) OR LOWER(u.username) LIKE LOWER(%s))"
            st = f"%{search_query}%"
            params.extend([st, st, st])

        sql += " ORDER BY u.id DESC"

        cursor.execute(sql, tuple(params))
        varkaris = cursor.fetchall()
        cursor.close()
        conn.close()

        for v in varkaris:
            if v.get("registration_date"):
                v["registration_date"] = v["registration_date"].isoformat()
            if v.get("last_active_time"):
                v["last_active_time"] = v["last_active_time"].isoformat()

        if status_filter and status_filter != "ALL":
            varkaris = [v for v in varkaris if v["status"] == status_filter]

        return jsonify({"success": True, "count": len(varkaris), "varkaris": varkaris}), 200
    except Exception as e:
        print("GET VARKARIS ERROR:", e)
        return jsonify({"success": False, "message": "Failed to fetch Varkaris."}), 500


@app.route("/volunteers", methods=["GET"])
def get_volunteers():
    """Retrieves all volunteers with current status, location, and active assignment."""
    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        sql = """
            SELECT 
                u.id,
                u.username AS volunteer_id,
                u.first_name,
                u.last_name,
                (u.first_name || ' ' || u.last_name) AS name,
                u.phone,
                u.emergency_contact,
                vl.latitude,
                vl.longitude,
                vl.is_active,
                vl.updated_at AS last_seen,
                ar.request_code AS current_assignment_code,
                ar.problem_description AS current_task,
                CASE 
                    WHEN ar.id IS NOT NULL THEN 'On Emergency Duty'
                    WHEN vl.is_active IS TRUE THEN 'Available'
                    ELSE 'Offline'
                END AS status
            FROM users u
            LEFT JOIN volunteer_locations vl ON u.username = vl.volunteer_username
            LEFT JOIN assistance_requests ar ON u.username = ar.assigned_volunteer_username AND ar.status IN ('PENDING', 'ASSIGNED')
            WHERE u.user_type = 'VT'
            ORDER BY u.id ASC
        """

        cursor.execute(sql)
        volunteers = cursor.fetchall()
        cursor.close()
        conn.close()

        for vol in volunteers:
            if vol.get("last_seen"):
                vol["last_seen"] = vol["last_seen"].isoformat()

        return jsonify({"success": True, "count": len(volunteers), "volunteers": volunteers}), 200
    except Exception as e:
        print("GET VOLUNTEERS ERROR:", e)
        return jsonify({"success": False, "message": "Failed to fetch volunteers."}), 500


@app.route("/volunteers/<username>/assign", methods=["POST"])
def assign_volunteer_task(username):
    """Assigns a volunteer to a task or emergency case."""
    data = request.get_json() or {}
    task_description = data.get("task_description", "").strip()
    request_id = data.get("request_id")

    username = username.strip().upper()

    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor()

        if request_id:
            cursor.execute(
                """
                UPDATE assistance_requests 
                SET assigned_volunteer_username = %s, status = 'ASSIGNED', assigned_at = CURRENT_TIMESTAMP
                WHERE id = %s
                """,
                (username, request_id)
            )

        cursor.execute(
            """
            INSERT INTO volunteer_locations (volunteer_username, latitude, longitude, is_active, updated_at)
            VALUES (%s, 18.4902, 73.8130, TRUE, CURRENT_TIMESTAMP)
            ON CONFLICT (volunteer_username) DO UPDATE SET is_active = TRUE, updated_at = CURRENT_TIMESTAMP
            """,
            (username,)
        )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"success": True, "message": f"Volunteer {username} assigned successfully."}), 200
    except Exception as e:
        print("ASSIGN VOLUNTEER TASK ERROR:", e)
        return jsonify({"success": False, "message": "Failed to assign volunteer task."}), 500


@app.route("/assistance-requests/<int:request_id>/assign", methods=["POST"])
def assign_sos_volunteer(request_id):
    """Assigns a volunteer directly to an SOS emergency from the Command Center."""
    data = request.get_json() or {}
    volunteer_username = data.get("volunteer_username", "").strip().upper()

    if not volunteer_username:
        return jsonify({"success": False, "message": "Volunteer username is required."}), 400

    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute(
            """
            UPDATE assistance_requests
            SET assigned_volunteer_username = %s, status = 'ASSIGNED', assigned_at = CURRENT_TIMESTAMP
            WHERE id = %s
            RETURNING *
            """,
            (volunteer_username, request_id)
        )
        updated = cursor.fetchone()

        # Add notification
        if updated:
            cursor.execute(
                """
                INSERT INTO notifications (title, message, category, severity)
                VALUES (%s, %s, 'SOS', 'HIGH')
                """,
                (
                    f"Volunteer Assigned to SOS #{request_id}",
                    f"Volunteer {volunteer_username} was dispatched to assist Varkari {updated.get('varkari_username')}."
                )
            )

        conn.commit()
        cursor.close()
        conn.close()

        if not updated:
            return jsonify({"success": False, "message": "SOS request not found."}), 404

        return jsonify({"success": True, "message": "Volunteer assigned to SOS.", "data": updated}), 200
    except Exception as e:
        print("ASSIGN SOS ERROR:", e)
        return jsonify({"success": False, "message": "Failed to assign volunteer to SOS."}), 500


@app.route("/assistance-requests/<int:request_id>/status", methods=["POST"])
def update_sos_status(request_id):
    """Updates status of an SOS request (ACKNOWLEDGED, ASSIGNED, RESOLVED)."""
    data = request.get_json() or {}
    new_status = data.get("status", "").strip().upper()

    if not new_status:
        return jsonify({"success": False, "message": "Status is required."}), 400

    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute(
            """
            UPDATE assistance_requests
            SET status = %s,
                volunteer_done = CASE WHEN %s = 'RESOLVED' THEN TRUE ELSE volunteer_done END,
                varkari_reached = CASE WHEN %s = 'RESOLVED' THEN TRUE ELSE varkari_reached END
            WHERE id = %s
            RETURNING *
            """,
            (new_status, new_status, new_status, request_id)
        )
        updated = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        if not updated:
            return jsonify({"success": False, "message": "SOS request not found."}), 404

        return jsonify({"success": True, "message": f"SOS status updated to {new_status}.", "data": updated}), 200
    except Exception as e:
        print("UPDATE SOS STATUS ERROR:", e)
        return jsonify({"success": False, "message": "Failed to update SOS status."}), 500


@app.route("/assistance-requests/all", methods=["GET"])
def get_all_assistance_requests():
    """Retrieves all SOS assistance requests for monitoring."""
    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute(
            """
            SELECT 
                ar.id,
                ar.request_code,
                ar.varkari_username,
                (u.first_name || ' ' || u.last_name) AS varkari_name,
                u.phone AS varkari_phone,
                u.blood_group,
                u.health_conditions,
                ar.problem_description,
                ar.health_condition,
                ar.latitude,
                ar.longitude,
                ar.status,
                ar.assigned_volunteer_username AS assigned_volunteer,
                (v.first_name || ' ' || v.last_name) AS assigned_volunteer_name,
                v.phone AS volunteer_phone,
                ar.created_at,
                ar.assigned_at,
                ar.volunteer_done,
                ar.varkari_reached
            FROM assistance_requests ar
            LEFT JOIN users u ON ar.varkari_username = u.username
            LEFT JOIN users v ON ar.assigned_volunteer_username = v.username
            ORDER BY 
                CASE 
                    WHEN ar.status = 'PENDING' THEN 1
                    WHEN ar.status = 'ASSIGNED' THEN 2
                    ELSE 3
                END,
                ar.created_at DESC
            """
        )

        requests = cursor.fetchall()
        cursor.close()
        conn.close()

        for req in requests:
            if req.get("created_at"):
                req["created_at"] = req["created_at"].isoformat()
            if req.get("assigned_at"):
                req["assigned_at"] = req["assigned_at"].isoformat()

        return jsonify({"success": True, "count": len(requests), "data": requests}), 200
    except Exception as e:
        print("GET ALL ASSISTANCE REQUESTS ERROR:", e)
        return jsonify({"success": False, "message": "Failed to fetch assistance requests."}), 500


@app.route("/medical-camps", methods=["GET", "POST"])
def manage_medical_camps():
    """GET medical camps or POST new camp."""
    if request.method == "GET":
        try:
            init_db()
            conn = get_db_connection()
            cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

            cursor.execute(
                """
                SELECT mc.*, 
                       COUNT(m.id) AS total_medicines,
                       SUM(CASE WHEN m.status IN ('Low Stock', 'Critical') THEN 1 ELSE 0 END) AS low_stock_count
                FROM medical_camps mc
                LEFT JOIN medicines m ON mc.camp_id = m.camp_id
                GROUP BY mc.id
                ORDER BY mc.id ASC
                """
            )
            camps = cursor.fetchall()
            cursor.close()
            conn.close()

            for c in camps:
                if c.get("updated_at"):
                    c["updated_at"] = c["updated_at"].isoformat()

            return jsonify({"success": True, "count": len(camps), "data": camps}), 200
        except Exception as e:
            print("GET MEDICAL CAMPS ERROR:", e)
            return jsonify({"success": False, "message": "Failed to fetch medical camps."}), 500

    else:
        # POST create / update medical camp
        data = request.get_json() or {}
        camp_id = data.get("camp_id", "").strip() or f"MED-CAMP-{datetime.now().strftime('%M%S')}"
        name = data.get("name", "").strip()
        location_name = data.get("location_name", "").strip()
        latitude = data.get("latitude", 18.4905)
        longitude = data.get("longitude", 73.8135)
        contact_phone = data.get("contact_phone", "").strip()
        doctor_in_charge = data.get("doctor_in_charge", "").strip()
        operating_hours = data.get("operating_hours", "24/7").strip()
        status = data.get("status", "ACTIVE").strip()
        emergency_capability = data.get("emergency_capability", "High").strip()

        if not name or not location_name:
            return jsonify({"success": False, "message": "Name and location required."}), 400

        try:
            init_db()
            conn = get_db_connection()
            cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

            cursor.execute(
                """
                INSERT INTO medical_camps (
                    camp_id, name, location_name, latitude, longitude,
                    contact_phone, doctor_in_charge, operating_hours, status, emergency_capability, updated_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP)
                ON CONFLICT (camp_id) DO UPDATE SET
                    name = EXCLUDED.name,
                    location_name = EXCLUDED.location_name,
                    latitude = EXCLUDED.latitude,
                    longitude = EXCLUDED.longitude,
                    contact_phone = EXCLUDED.contact_phone,
                    doctor_in_charge = EXCLUDED.doctor_in_charge,
                    operating_hours = EXCLUDED.operating_hours,
                    status = EXCLUDED.status,
                    emergency_capability = EXCLUDED.emergency_capability,
                    updated_at = CURRENT_TIMESTAMP
                RETURNING *
                """,
                (camp_id, name, location_name, float(latitude), float(longitude), contact_phone, doctor_in_charge, operating_hours, status, emergency_capability)
            )

            updated = cursor.fetchone()
            conn.commit()
            cursor.close()
            conn.close()

            return jsonify({"success": True, "message": "Medical camp saved successfully.", "data": updated}), 200
        except Exception as e:
            print("SAVE MEDICAL CAMP ERROR:", e)
            return jsonify({"success": False, "message": "Failed to save medical camp."}), 500


@app.route("/medicines", methods=["GET", "POST"])
def manage_medicines():
    """GET medicines inventory or POST update stock level."""
    if request.method == "GET":
        try:
            init_db()
            conn = get_db_connection()
            cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

            cursor.execute(
                """
                SELECT m.*, mc.name AS camp_name, mc.location_name AS camp_location
                FROM medicines m
                LEFT JOIN medical_camps mc ON m.camp_id = mc.camp_id
                ORDER BY 
                    CASE 
                        WHEN m.status = 'Out of Stock' THEN 1
                        WHEN m.status = 'Critical' THEN 2
                        WHEN m.status = 'Low Stock' THEN 3
                        ELSE 4
                    END,
                    m.id ASC
                """
            )
            records = cursor.fetchall()
            cursor.close()
            conn.close()

            for r in records:
                if r.get("updated_at"):
                    r["updated_at"] = r["updated_at"].isoformat()

            return jsonify({"success": True, "count": len(records), "data": records}), 200
        except Exception as e:
            print("GET MEDICINES ERROR:", e)
            return jsonify({"success": False, "message": "Failed to fetch medicines."}), 500

    else:
        # POST update stock
        data = request.get_json() or {}
        item_id = data.get("item_id", "").strip()
        available_quantity = data.get("available_quantity")

        if not item_id or available_quantity is None:
            return jsonify({"success": False, "message": "Item ID and available quantity required."}), 400

        try:
            available_quantity = int(available_quantity)
            init_db()
            conn = get_db_connection()
            cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

            cursor.execute("SELECT total_capacity, name FROM medicines WHERE item_id = %s", (item_id,))
            med = cursor.fetchone()

            if not med:
                cursor.close()
                conn.close()
                return jsonify({"success": False, "message": "Medicine item not found."}), 404

            total_capacity = med["total_capacity"] or 100
            ratio = available_quantity / float(total_capacity)

            if available_quantity <= 0:
                new_status = "Out of Stock"
            elif ratio <= 0.15:
                new_status = "Critical"
            elif ratio <= 0.35:
                new_status = "Low Stock"
            else:
                new_status = "In Stock"

            cursor.execute(
                """
                UPDATE medicines
                SET available_quantity = %s, status = %s, updated_at = CURRENT_TIMESTAMP
                WHERE item_id = %s
                RETURNING *
                """,
                (available_quantity, new_status, item_id)
            )

            updated = cursor.fetchone()

            # Trigger notification if low stock
            if new_status in ["Critical", "Low Stock", "Out of Stock"]:
                cursor.execute(
                    """
                    INSERT INTO notifications (title, message, category, severity)
                    VALUES (%s, %s, 'STOCK', %s)
                    """,
                    (
                        f"Low Medicine Alert: {med['name']}",
                        f"Supply for {med['name']} has dropped to {available_quantity} ({new_status}). Please replenish.",
                        "CRITICAL" if new_status in ["Critical", "Out of Stock"] else "HIGH"
                    )
                )

            conn.commit()
            cursor.close()
            conn.close()

            return jsonify({"success": True, "message": f"Medicine stock updated to {new_status}.", "data": updated}), 200
        except Exception as e:
            print("UPDATE MEDICINE ERROR:", e)
            return jsonify({"success": False, "message": "Failed to update medicine inventory."}), 500


@app.route("/food-water-points", methods=["GET", "POST"])
def manage_food_water_points():
    """GET or POST food and water distribution points."""
    if request.method == "GET":
        try:
            init_db()
            conn = get_db_connection()
            cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

            cursor.execute("SELECT * FROM food_water_points ORDER BY id ASC")
            points = cursor.fetchall()
            cursor.close()
            conn.close()

            for p in points:
                if p.get("updated_at"):
                    p["updated_at"] = p["updated_at"].isoformat()

            return jsonify({"success": True, "count": len(points), "data": points}), 200
        except Exception as e:
            print("GET FOOD WATER POINTS ERROR:", e)
            return jsonify({"success": False, "message": "Failed to fetch water points."}), 500

    else:
        # POST update point status
        data = request.get_json() or {}
        point_id = data.get("point_id", "").strip()
        status = data.get("status", "").strip().upper()
        available_amount = data.get("available_amount")

        if not point_id:
            return jsonify({"success": False, "message": "Point ID is required."}), 400

        try:
            init_db()
            conn = get_db_connection()
            cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

            cursor.execute(
                """
                UPDATE food_water_points
                SET status = COALESCE(NULLIF(%s, ''), status),
                    available_amount = COALESCE(%s, available_amount),
                    updated_at = CURRENT_TIMESTAMP
                WHERE point_id = %s
                RETURNING *
                """,
                (status, available_amount, point_id)
            )

            updated = cursor.fetchone()
            conn.commit()
            cursor.close()
            conn.close()

            if not updated:
                return jsonify({"success": False, "message": "Water/food point not found."}), 404

            return jsonify({"success": True, "message": "Point updated successfully.", "data": updated}), 200
        except Exception as e:
            print("UPDATE FOOD WATER POINT ERROR:", e)
            return jsonify({"success": False, "message": "Failed to update point."}), 500


@app.route("/weather-risk", methods=["GET"])
def get_weather_risk_zones():
    """Retrieves current heat risk levels and weather advisories along the Wari route."""
    try:
        zones = [
            {
                "id": "WX-ZONE-101",
                "location": "Dive Ghat Pass (दिवे घाट)",
                "latitude": 18.4280,
                "longitude": 73.9720,
                "temperature": 39.2,
                "humidity": 45,
                "heat_index": 42.5,
                "risk_level": "Critical",
                "color": "#DC2626",
                "advisory_english": "Extreme Heat Alert (39.2°C)! High risk of heat stroke. ORS hydration booth deployed at 300m.",
                "advisory_marathi": "तीव्र उष्णता (३९°C): उष्माघाताचा धोका! दर १५ मिनिटांनी ओआरएस पाणी घ्या."
            },
            {
                "id": "WX-ZONE-102",
                "location": "Wakhari Stretch (वाखारी टप्पा)",
                "latitude": 17.8350,
                "longitude": 75.1050,
                "temperature": 35.5,
                "humidity": 58,
                "heat_index": 38.0,
                "risk_level": "High Risk",
                "color": "#F97316",
                "advisory_english": "Dehydration Alert (35.5°C): Heavy sweat loss. Drink electrolyte water regularly.",
                "advisory_marathi": "दमट हवामान (३५.५°C): लिंबू सरबत व पाणी भरपूर प्या."
            },
            {
                "id": "WX-ZONE-103",
                "location": "Jejuri Slope Ghat (जेजुरी घाट)",
                "latitude": 18.2800,
                "longitude": 74.1500,
                "temperature": 27.5,
                "humidity": 82,
                "heat_index": 28.0,
                "risk_level": "Moderate",
                "color": "#3B82F6",
                "advisory_english": "Light Rain / Slippery Slope: Walk carefully on the ghat slope.",
                "advisory_marathi": "पावसामुळे रस्ता घसरडा: घाटात हळू चाला."
            },
            {
                "id": "WX-ZONE-104",
                "location": "Saswad Tree Canopy (सासवड छायदार मार्ग)",
                "latitude": 18.3550,
                "longitude": 74.0220,
                "temperature": 28.0,
                "humidity": 50,
                "heat_index": 28.5,
                "risk_level": "Safe",
                "color": "#16A34A",
                "advisory_english": "Pleasant Walking Conditions (28°C): Shaded tree canopy.",
                "advisory_marathi": "सुखद वातावरण (२८°C): सावलीत विश्रांती घ्या."
            }
        ]
        return jsonify({"success": True, "count": len(zones), "zones": zones}), 200
    except Exception as e:
        print("GET WEATHER RISK ERROR:", e)
        return jsonify({"success": False, "message": "Failed to fetch weather risk zones."}), 500


@app.route("/notifications", methods=["GET"])
def get_notifications():
    """Retrieves system notifications log."""
    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute("SELECT * FROM notifications ORDER BY created_at DESC LIMIT 50")
        notifications = cursor.fetchall()
        cursor.close()
        conn.close()

        for n in notifications:
            if n.get("created_at"):
                n["created_at"] = n["created_at"].isoformat()

        return jsonify({"success": True, "count": len(notifications), "notifications": notifications}), 200
    except Exception as e:
        print("GET NOTIFICATIONS ERROR:", e)
        return jsonify({"success": False, "message": "Failed to fetch notifications."}), 500


@app.route("/notifications/mark-read", methods=["POST"])
def mark_notifications_read():
    """Marks notifications as read."""
    data = request.get_json() or {}
    notification_id = data.get("id")

    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor()

        if notification_id:
            cursor.execute("UPDATE notifications SET is_read = TRUE WHERE id = %s", (notification_id,))
        else:
            cursor.execute("UPDATE notifications SET is_read = TRUE")

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"success": True, "message": "Notifications marked as read."}), 200
    except Exception as e:
        print("MARK NOTIFICATIONS READ ERROR:", e)
        return jsonify({"success": False, "message": "Failed to mark notifications read."}), 500


@app.route("/analytics/reports", methods=["GET"])
def get_analytics_reports():
    """Retrieves aggregated analytics & chart data for Command Center reports."""
    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        # SOS Trends
        sos_trend = [
            {"day": "Mon", "total": 12, "resolved": 11},
            {"day": "Tue", "total": 18, "resolved": 16},
            {"day": "Wed", "total": 24, "resolved": 22},
            {"day": "Thu", "total": 15, "resolved": 14},
            {"day": "Fri", "total": 30, "resolved": 27},
            {"day": "Sat", "total": 42, "resolved": 38},
            {"day": "Sun", "total": 28, "resolved": 26}
        ]

        # Varkari Demographics (Age groups)
        cursor.execute(
            """
            SELECT 
                CASE 
                    WHEN age < 30 THEN '16-30 yrs'
                    WHEN age BETWEEN 30 AND 50 THEN '31-50 yrs'
                    WHEN age BETWEEN 51 AND 65 THEN '51-65 yrs'
                    ELSE '65+ Senior Varkaris'
                END AS age_group,
                COUNT(*) AS count
            FROM users
            WHERE user_type = 'VK'
            GROUP BY age_group
            ORDER BY count DESC
            """
        )
        demographics = cursor.fetchall()
        if not demographics:
            demographics = [
                {"age_group": "51-65 yrs", "count": 450},
                {"age_group": "31-50 yrs", "count": 320},
                {"age_group": "65+ Senior Varkaris", "count": 210},
                {"age_group": "16-30 yrs", "count": 140}
            ]

        # Missing Person Resolution Rate
        cursor.execute("SELECT COUNT(*) AS total FROM missing_persons")
        active_mp = cursor.fetchone()["total"]

        cursor.execute("SELECT COUNT(*) AS total FROM resolved_missing_persons")
        resolved_mp = cursor.fetchone()["total"]

        # Medical Stock Overview
        cursor.execute(
            """
            SELECT status, COUNT(*) AS count 
            FROM medicines 
            GROUP BY status
            """
        )
        stock_status = cursor.fetchall()

        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "data": {
                "sos_trend": sos_trend,
                "demographics": demographics,
                "missing_resolution": {
                    "active": active_mp,
                    "resolved": resolved_mp,
                    "resolution_rate": f"{round((resolved_mp / max(1, active_mp + resolved_mp)) * 100, 1)}%"
                },
                "medical_stock_summary": stock_status
            }
        }), 200
    except Exception as e:
        print("GET ANALYTICS ERROR:", e)
        return jsonify({"success": False, "message": "Failed to calculate analytics."}), 500


@app.route("/admin/seed-demo-data", methods=["POST"])
def seed_demo_data():
    """Populates PostgreSQL DB with rich realistic demo data for presentation testing."""
    try:
        init_db()
        conn = get_db_connection()
        cursor = conn.cursor()

        # 1. Seed Demo Varkaris
        demo_varkaris = [
            ('VK100001', '1234', 'VK', 'Pandurang', 'Jadhav', '1965-05-12', 61, 'Male', '9822011223', '9822011224', 'O+', '{Hypertension, Diabetes}', 18.4902, 73.8130),
            ('VK100002', '1234', 'VK', 'Rukmini', 'Shinde', '1972-08-20', 54, 'Female', '9890011225', '9890011226', 'B+', '{Asthma}', 18.4985, 73.8350),
            ('VK100003', '1234', 'VK', 'Eknath', 'Kulkarni', '1958-03-15', 68, 'Male', '9765433221', '9765433222', 'A+', '{Joint Pain, Dehydration}', 18.4350, 73.9820),
            ('VK100004', '1234', 'VK', 'Tukaram', 'Gaikwad', '1980-11-10', 46, 'Male', '9423144556', '9423144557', 'AB+', '{None}', 18.3440, 74.0300),
            ('VK100005', '1234', 'VK', 'Gyaneshwar', 'Patil', '1952-01-25', 74, 'Male', '9823055667', '9823055668', 'O-', '{Cardiac History}', 18.2750, 74.1590),
            ('VK100006', '1234', 'VK', 'Sopan', 'Bhosale', '1988-07-04', 38, 'Male', '9822188990', '9822188991', 'B-', '{None}', 18.0400, 74.1880)
        ]

        for u in demo_varkaris:
            cursor.execute(
                """
                INSERT INTO users (username, password, user_type, first_name, last_name, date_of_birth, age, gender, phone, emergency_contact, blood_group, health_conditions)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (username) DO UPDATE SET phone = EXCLUDED.phone
                """,
                u[:12]
            )
            cursor.execute(
                """
                INSERT INTO user_locations (username, latitude, longitude, updated_at)
                VALUES (%s, %s, %s, CURRENT_TIMESTAMP)
                ON CONFLICT (username) DO UPDATE SET latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, updated_at = CURRENT_TIMESTAMP
                """,
                (u[0], u[12], u[13])
            )

        # 2. Seed Demo Volunteers
        demo_volunteers = [
            ('VT101', '1234', 'VT', 'Rahul', 'Deshmukh', '1998-05-10', 28, 'Male', '9822099887', '9822099888', 'O+', '{None}', 18.4910, 73.8140),
            ('VT102', '1234', 'VT', 'Priya', 'Shinde', '2000-08-15', 26, 'Female', '9890088776', '9890088777', 'A+', '{None}', 18.4360, 73.9830),
            ('VT103', '1234', 'VT', 'Anand', 'Patil', '1994-03-22', 32, 'Male', '9765422110', '9765422111', 'B+', '{None}', 18.3450, 74.0310),
            ('VT104', '1234', 'VT', 'Sunita', 'Kulkarni', '1996-11-05', 30, 'Female', '9423155667', '9423155668', 'O+', '{None}', 18.2760, 74.1600)
        ]

        for vol in demo_volunteers:
            cursor.execute(
                """
                INSERT INTO users (username, password, user_type, first_name, last_name, date_of_birth, age, gender, phone, emergency_contact, blood_group, health_conditions)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (username) DO NOTHING
                """,
                (vol[0], vol[1], vol[2], vol[3], vol[4], vol[5], vol[6], vol[7], vol[8], vol[9], vol[10], vol[11])
            )
            cursor.execute(
                """
                INSERT INTO volunteer_locations (volunteer_username, latitude, longitude, is_active, updated_at)
                VALUES (%s, %s, %s, TRUE, CURRENT_TIMESTAMP)
                ON CONFLICT (volunteer_username) DO UPDATE SET latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, is_active = TRUE, updated_at = CURRENT_TIMESTAMP
                """,
                (vol[0], vol[12], vol[13])
            )

        # 3. Seed Demo SOS Requests
        demo_sos = [
            ('REQ-2026083001', 'VK100001', 18.4902, 73.8130, 'High blood pressure & severe dizziness near Karve Nagar', 'PENDING', None),
            ('REQ-2026083002', 'VK100003', 18.4350, 73.9820, 'Foot injury & muscle cramps at Dive Ghat top slope', 'ASSIGNED', 'VT102')
        ]

        for req in demo_sos:
            cursor.execute(
                """
                INSERT INTO assistance_requests (request_code, varkari_username, latitude, longitude, problem_description, status, assigned_volunteer_username, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP)
                ON CONFLICT (request_code) DO NOTHING
                """,
                req
            )

        # 4. Seed Demo Missing Persons
        demo_missing = [
            ('MP-10001', 'Shantabai More', 72, 'Female', '9822044332', 'Saswad Palkhi Maidan', '2026-08-30 08:30', 'Height 5ft 1in, wearing green nauvari saree with rudraksha mala.', 'Carrying brass water pot', 'Separated during afternoon Dindi procession', '', 'VK100002', 'VK', 'Saswad', 18.3440, 74.0300, 'Missing', 'None'),
            ('MP-10002', 'Ganesh Bhosale', 10, 'Male', '9890066554', 'Dive Ghat Hairpin Bend', '2026-08-30 09:15', 'Fair complexion, blue shirt and white shorts, carrying orange flag.', 'Knows home village address Pune', 'Got lost in crowd climb', '', 'VK100004', 'VK', 'Dive Ghat', 18.4280, 73.9720, 'Found - Verification Pending', 'Pending')
        ]

        for mp in demo_missing:
            cursor.execute(
                """
                INSERT INTO missing_persons (
                    missing_person_id, name, age, gender, contact_number, last_seen_location, last_seen_datetime,
                    physical_description, clothes_description, other_info, photo, reporter_id, reporter_type,
                    reporter_location, reporter_latitude, reporter_longitude, status, verification_status
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (missing_person_id) DO NOTHING
                """,
                mp
            )

        # 5. Seed Medical Camps & Medicines
        camps_data = [
            ('MED-100', 'एमएमसीओई प्रथमोपचार केंद्र (MMCOE First Aid Post)', 'MMCOE Campus, Karve Nagar, Pune', 18.4905, 73.8135, '+91 98230 55667', 'Dr. Shruti Joshi', '24/7', 'ACTIVE', 'High', 42),
            ('MED-101', 'दिवे घाट आरोग्य केंद्र (Dive Ghat Base)', 'Dive Ghat Top (km 18)', 18.4350, 73.9820, '+91 94231 44556', 'Dr. Anjali Patil', '24/7', 'ACTIVE', 'Critical Care', 88),
            ('MED-102', 'सासवड मध्यवर्ती रुग्णालय (Saswad Main Base)', 'Saswad City Ground (km 35)', 18.3440, 74.0300, '+91 98900 88776', 'Dr. Suresh Deshmukh', '24/7', 'ACTIVE', 'Hospital Ward', 156),
            ('MED-103', 'जेजुरी मेडिकल कॅम्प (Jejuri Aid Center)', 'Jejuri Temple Square (km 52)', 18.2750, 74.1590, '+91 97654 11223', 'Dr. Ramesh Kulkarni', '24/7', 'ACTIVE', 'Moderate', 64)
        ]

        for c in camps_data:
            cursor.execute(
                """
                INSERT INTO medical_camps (camp_id, name, location_name, latitude, longitude, contact_phone, doctor_in_charge, operating_hours, status, emergency_capability, patient_count)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (camp_id) DO UPDATE SET name = EXCLUDED.name
                """,
                c
            )

        meds_data = [
            ('MED-ITEM-101', 'ORS Hydration Packets (ओआरएस)', 'Hydration', 'MED-100', 250, 300, 'packs', '2027-12', 'In Stock'),
            ('MED-ITEM-102', 'First Aid Bandages & Gauze', 'First Aid', 'MED-100', 140, 150, 'kits', '2028-06', 'In Stock'),
            ('MED-ITEM-103', 'ORS Hydration Packets (ओआरएस)', 'Hydration', 'MED-101', 12, 200, 'packs', '2027-12', 'Critical'),
            ('MED-ITEM-104', 'Foot Blister Pain Ointment', 'Topical', 'MED-101', 18, 100, 'tubes', '2027-08', 'Low Stock'),
            ('MED-ITEM-105', 'Paracetamol & Antacids', 'Oral Painkiller', 'MED-102', 450, 500, 'tabs', '2028-01', 'In Stock'),
            ('MED-ITEM-106', 'Saline IV Bottles (सलाईन)', 'Emergency IV', 'MED-102', 110, 150, 'bottles', '2027-10', 'In Stock'),
            ('MED-ITEM-107', 'Emergency Oxygen Cylinders', 'Respiratory', 'MED-102', 2, 10, 'cylinders', '2029-01', 'Low Stock')
        ]

        for m in meds_data:
            cursor.execute(
                """
                INSERT INTO medicines (item_id, name, category, camp_id, available_quantity, total_capacity, unit, expiry_date, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (item_id) DO UPDATE SET available_quantity = EXCLUDED.available_quantity, status = EXCLUDED.status
                """,
                m
            )

        # 6. Seed Food & Water Points
        points_data = [
            ('WP-101', 'WATER', 'एमएमसीओई जल सेवा केंद्र (MMCOE Water Hub)', 'MMCOE Gate 1, Karve Nagar', 18.4902, 73.8130, 'AVAILABLE', 5000, 4200),
            ('WP-102', 'WATER', 'हडपसर पालखी जल केंद्र (Hadapsar Water Station)', 'Hadapsar Bypass Junction', 18.4980, 73.9350, 'AVAILABLE', 10000, 8500),
            ('FP-101', 'FOOD', 'दिवे घाट महाप्रसाद अन्नछत्र (Dive Ghat Annachhatra)', 'Vadki Nala Base', 18.4550, 73.9600, 'AVAILABLE', 3000, 2400),
            ('WP-103', 'WATER', 'दिवे घाट शिखर जल टाकी (Dive Ghat Top Tank)', 'Dive Ghat Viewpoint', 18.4280, 73.9720, 'LOW_SUPPLY', 2000, 350),
            ('FP-102', 'FOOD', 'सासवड श्री क्षेत्र अन्नछत्र (Saswad Food Pavilion)', 'Saswad Maidan', 18.3440, 74.0300, 'AVAILABLE', 8000, 6200)
        ]

        for p in points_data:
            cursor.execute(
                """
                INSERT INTO food_water_points (point_id, type, name, location_name, latitude, longitude, status, capacity_liters_or_meals, available_amount)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (point_id) DO UPDATE SET available_amount = EXCLUDED.available_amount, status = EXCLUDED.status
                """,
                p
            )

        # 7. Seed System Notifications
        notifications_data = [
            ('CRITICAL SOS ALERT', 'Varkari Pandurang Jadhav triggered SOS near Karve Nagar due to high blood pressure.', 'SOS', 'CRITICAL'),
            ('Low ORS Stock Alert', 'Dive Ghat Medical Post is critically low on ORS packets (12 packs remaining).', 'STOCK', 'HIGH'),
            ('Missing Person Reported', 'Shantabai More (72 yrs) reported missing near Saswad Maidan.', 'MISSING', 'HIGH'),
            ('Extreme Heat Advisory', 'Heat Index reached 42.5°C at Dive Ghat. ORS distribution alerted.', 'WEATHER', 'HIGH'),
            ('Missing Person Sighting', 'Ganesh Bhosale (10 yrs) located near Dive Ghat Hairpin. Verification pending.', 'MISSING', 'INFO')
        ]

        for n in notifications_data:
            cursor.execute(
                """
                INSERT INTO notifications (title, message, category, severity)
                VALUES (%s, %s, %s, %s)
                """,
                n
            )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({
            "success": True,
            "message": "PostgreSQL database seeded successfully with complete VariPath Command Center demo data!"
        }), 200

    except Exception as e:
        print("SEED DEMO DATA ERROR:", e)
        return jsonify({"success": False, "message": f"Failed to seed demo data: {str(e)}"}), 500


# ============================================================
# RUN SERVER
# ============================================================


# ============================================================
# MAIN ENTRYPOINT
# ============================================================

if __name__ == "__main__":
    init_db()
    app.run(
        host="0.0.0.0",
        port=5001,
        debug=True
    )

