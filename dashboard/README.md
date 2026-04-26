# Power BI Dashboard — Connection Guide

This guide explains how to connect Power BI Online to your Supabase PostgreSQL database.

---

## Prerequisites

- Power BI Online account
- Supabase project URL and credentials
- On-premises data gateway (required for direct PostgreSQL connection from Power BI Online)

---

## Option A: Connect via PostgreSQL Direct (Recommended)

### Step 1 — Get your Supabase connection details

In your Supabase project dashboard go to:
**Settings → Database → Connection string**

Note down:
- Host: `db.<your-project-ref>.supabase.co`
- Port: `5432`
- Database: `postgres`
- User: `postgres`
- Password: your database password

### Step 2 — In Power BI Online

1. Go to **My Workspace → New → Dataset**
2. Choose **PostgreSQL database**
3. Enter your host and database name
4. Under credentials, enter your Supabase DB username and password
5. Click **Connect**

### Step 3 — Select your tables

Select all 5 tables:
- `public.trolleys`
- `public.users`
- `public.locations`
- `public.trolley_events`
- `public.reward_ledger`

---

## Option B: Connect via Supabase REST API (No Gateway Required)

Use Power BI's **Web connector** with Supabase's auto-generated REST API.

Example URL to fetch all trolley events:
```
https://<your-project-ref>.supabase.co/rest/v1/trolley_events?select=*
```

Add headers:
- `apikey`: your Supabase anon key
- `Authorization`: `Bearer <your-anon-key>`

---

## Recommended Dashboard Pages

| Page | Visuals |
|---|---|
| **Overview** | Total trolleys, events today, active locations (KPI cards) |
| **Stock Levels** | Bar chart: current trolleys vs. target_min/target_max per location |
| **Event Trends** | Line chart: daily pickups vs. dropoffs over time |
| **Zone Analysis** | Pickup-to-dropoff ratio by zone (Entrance / Parking / Basement) |
| **Top Users** | Table: users ranked by total scans + dropoffs |
| **Inactive Trolleys** | Table: trolleys with no events in last 7 days |

---

## Suggested DAX Measures

```dax
-- Total Pickups
Total Pickups = CALCULATE(COUNTROWS(trolley_events), trolley_events[action] = "pickup")

-- Total Dropoffs
Total Dropoffs = CALCULATE(COUNTROWS(trolley_events), trolley_events[action] = "dropoff")

-- Pickup to Dropoff Ratio
Pickup Ratio = DIVIDE([Total Pickups], [Total Dropoffs], 0)

-- Understocked Locations
Understocked = 
CALCULATE(
    COUNTROWS(locations),
    locations[current_count] < locations[target_min]
)
```

---

*See the main README for full project context.*
