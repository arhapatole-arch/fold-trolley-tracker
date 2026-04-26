# 🛒 FOLD Trolley Tracker

A real-time operational data system for tracking shopping trolleys across multiple retail locations in Melbourne, built on **PostgreSQL (Supabase)** with a **ShopBack rewards integration**.

This project was built as a Data Analyst portfolio piece demonstrating end-to-end database design, data governance, SQL analytics, and business intelligence.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Business Problem](#business-problem)
- [Database Schema](#database-schema)
- [Tech Stack](#tech-stack)
- [Key Analytics](#key-analytics)
- [Data Governance](#data-governance)
- [Project Structure](#project-structure)
- [How to Run](#how-to-run)
- [Insights & Findings](#insights--findings)
- [Next Steps](#next-steps)

---

## Project Overview

| Table | Rows | Description |
|---|---|---|
| `trolleys` | 100 | Each trolley's status, location & last action |
| `users` | 100 | Shoppers linked to ShopBack rewards |
| `locations` | 7 | Coles, Woolies & Aldi across Melbourne zones |
| `trolley_events` | 19 | Pickup & dropoff events with timestamps |
| `reward_ledger` | 0 | Reward points system (in progress) |

**Live system** tracking 100 trolleys across 7 locations at 3 Melbourne retailers (Coles, Woolworths, Aldi).

---

## Business Problem

Retail locations face a common operational inefficiency — trolleys accumulate in some zones (e.g. parking) while others run empty (e.g. store entrance), frustrating shoppers and increasing staff retrieval costs.

**This system solves that by:**
- Tracking every trolley pickup and dropoff event in real time
- Measuring actual trolley counts against per-location target thresholds (`target_min` / `target_max`)
- Incentivising shoppers to return trolleys via a ShopBack rewards system
- Providing analytical visibility into imbalances, peak usage times, and inactive trolleys

---

## Database Schema

```
trolleys
├── trolley_id (PK, VARCHAR)    e.g. TR001
├── status                      active / inactive
├── current_location_id (FK → locations)
├── last_action                 pickup | dropoff
└── last_event_ts

users
├── user_id (PK, VARCHAR)       e.g. U001
├── source                      shopback
└── created_at

locations
├── location_id (PK, BIGINT)
├── location_name               e.g. Coles - Entrance
├── store_code                  STORE_A / STORE_B / STORE_C
├── zone                        entrance | parking | basement
├── target_min / target_max     stock thresholds
├── latitude / longitude
└── is_active

trolley_events
├── event_id (PK, BIGINT)
├── trolley_id (FK → trolleys)
├── user_id (FK → users)
├── location_id (FK → locations)
├── action                      pickup | dropoff
├── event_ts
└── latitude / longitude

reward_ledger
├── reward_id (PK, BIGINT)
├── user_id (FK → users)
├── trolley_id (FK → trolleys)
├── points
├── reason
└── source_event_id (FK → trolley_events)
```

### Entity Relationship Diagram

```
locations ──< trolleys
locations ──< trolley_events
trolleys  ──< trolley_events
users     ──< trolley_events
users     ──< reward_ledger
trolleys  ──< reward_ledger
trolley_events ──< reward_ledger
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Database | PostgreSQL 17 (Supabase) |
| Backend API | Supabase REST + PostgREST |
| Auth & Security | Supabase RLS (Row Level Security) |
| Analytics | SQL (PostgreSQL) |
| Dashboard | Power BI Online |
| Frontend App | React / Next.js (Trolley Scan UI) |

---

## Key Analytics

Ten core SQL queries are included in [`/analytics/fold_trolley_analytics.sql`](./analytics/fold_trolley_analytics.sql):

| # | Query | Business Question |
|---|---|---|
| 1 | Stock level vs. targets | Which locations are under/overstocked? |
| 2 | Event volume by location | Where is activity highest? |
| 3 | Most active trolleys | Which trolleys are used most? |
| 4 | Most active users | Who should earn the most rewards? |
| 5 | Daily event trend | How is usage growing? |
| 6 | Hourly activity pattern (AEST) | When are trolleys most used? |
| 7 | Inactive trolleys | Which trolleys may be lost/misplaced? |
| 8 | Store-level summary | How is each retailer performing? |
| 9 | Pickup-to-dropoff ratio by zone | Which zones have net outflow? |
| 10 | Reward eligibility | Who should receive points right now? |

---

## Data Governance

Row Level Security (RLS) is enabled on **all 5 tables**. Policies are structured around three roles:

| Role | Access |
|---|---|
| `anon` | Read all events; insert events (validated against trolleys + locations) |
| `authenticated` | Insert events (validated against users); read all |
| `service_role` | Full access (admin/backend operations) |

This ensures public-facing apps can submit scans without exposing or corrupting backend data.

---

## Project Structure

```
fold-trolley-tracker/
│
├── README.md                        ← You are here
│
├── schema/
│   ├── 01_create_tables.sql         ← Full schema DDL
│   └── 02_rls_policies.sql          ← All RLS policy definitions
│
├── analytics/
│   └── fold_trolley_analytics.sql   ← 10 core analytics queries
│
├── dashboard/
│   └── README.md                    ← Power BI connection guide
│
└── docs/
    └── project_overview.md          ← Extended project documentation
```

---

## How to Run

### 1. Clone the repo
```bash
git clone https://github.com/<your-username>/fold-trolley-tracker.git
cd fold-trolley-tracker
```

### 2. Connect to your own Supabase project
- Create a project at [supabase.com](https://supabase.com)
- Run `schema/01_create_tables.sql` in the SQL editor
- Run `schema/02_rls_policies.sql` to apply security policies

### 3. Run the analytics queries
- Open `analytics/fold_trolley_analytics.sql` in Supabase SQL Editor
- Run individual queries to explore the data

### 4. Connect Power BI
- See `dashboard/README.md` for the full connection guide

---

## Insights & Findings

From live data (April 2026):

- **Aldi Parking** is the highest-activity location (6 events), all pickups — zero dropoffs
- **Entrance zones** have a pure outflow pattern: trolleys leave, none return
- **Parking zones** have a 2.67:1 pickup-to-dropoff ratio — significant net drain
- **4 dropoff events** are eligible for reward points but have not yet been awarded
- **TR001** is the most active trolley (5 events across 3 locations)

These findings directly support the business case: without a rewards incentive, trolleys accumulate away from entrances and staff must manually retrieve them.

---

## Next Steps

- [ ] Populate `reward_ledger` from eligible dropoff events
- [ ] Build Power BI dashboard (stock levels, event trends, zone heatmap)
- [ ] Add GPS coordinates to all locations
- [ ] Expand to additional store locations
- [ ] Python notebook for predictive restocking analysis

---

*Built by Arha | Data Analyst Portfolio Project | Melbourne, 2026*
