# 🚩 वारीपथ (VariPath) — Organizer & Admin Command Center Dashboard

A real-time, hackathon-ready **Emergency Command Center & Organizer Dashboard** built for **VariPath (वारीपथ)** to monitor and manage the Pandharpur Wari Palkhi pilgrimage (Pune NH 965 route to Pandharpur).

---

## 🏗️ Architecture

```
[ Mobile App (Flutter) ] <---> [ Flask Backend API (port 5001) ] <---> [ PostgreSQL DB ]
                                        ^
                                        | (REST APIs + Live Polling)
                                        v
                    [ React + Vite Command Center Dashboard ]
```

---

## 🚀 Quick Setup & How to Run Locally

### 1. Start the Backend API & Database

Make sure PostgreSQL is running locally on port `5432` with database `varipath`.

```bash
cd backend
venv/bin/python app.py
```
> Flask API will start running at `http://localhost:5001`.

### 2. Start the Organizer Dashboard Web App

In a second terminal window:

```bash
cd dashboard
npm run dev
```
> The dashboard will launch at `http://localhost:5173`.

---

## 🔑 Login Credentials

* **Username**: `admin`
* **Password**: `admin123`

---

## ⚡ Features & Modules

1. **Dashboard Home / Command Center**: Real-time KPI summary cards, embedded live map, active SOS feeds, missing person alerts.
2. **Live Wari Map**: Interactive Leaflet map with authentic NH 965 route polyline, layer toggles for Varkaris, Volunteers, Camps, Water, SOS, and Heat-risk zones.
3. **SOS & Emergency Monitoring**: Emergency distress feed, severity badges, volunteer dispatch, and resolution actions.
4. **Varkari Management**: Searchable/sortable pilgrim directory, health conditions, and emergency contacts.
5. **Volunteer Hub**: Volunteer availability, task assignments, and duty status updates.
6. **Missing Persons**: Active missing cases, volunteer sighting verification, and resolved history.
7. **Medical Camps & Medicines**: Medical post capacity, doctor contacts, and inventory stock replenishment alerts.
8. **Food & Water Points**: Hydration tanks and Annachhatra food distribution points status management.
9. **Heat & Weather Risk**: Temperature telemetry, heat-stroke warnings, and hydration advisories.
10. **Reports & Analytics**: Recharts graphics and CSV data export.
11. **Seed Demo Data Utility**: One-click button in Top Bar & Admin section to seed real PostgreSQL demo records.
