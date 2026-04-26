# FOLD Trolley Tracker — Project Overview

## Background

This project was built to address a real operational problem in Australian retail: shopping trolleys are consistently misallocated across store zones, with parking areas accumulating excess trolleys while store entrances run short.

The FOLD Trolley Tracker solves this by creating a lightweight, event-driven data system where shoppers scan trolleys at pickup and dropoff points. The data captured feeds into:

1. Real-time stock visibility per location
2. Imbalance alerts against defined thresholds
3. A ShopBack-integrated rewards system to incentivise returns

---

## Retail Locations Covered

| Store Code | Retailer | Locations |
|---|---|---|
| STORE_A | Coles | Entrance, Basement |
| STORE_B | Woolworths | Parking, Basement |
| STORE_C | Aldi | Entrance, Parking, Basement |

Each location has a `target_min` and `target_max` threshold defining the acceptable trolley count range for operational efficiency.

---

## Event Data Model

Every trolley interaction is captured as a `trolley_event` with:

- **Who** scanned it (`user_id`)
- **Which trolley** (`trolley_id`)
- **Where** it happened (`location_id`)
- **What action** was taken (`pickup` or `dropoff`)
- **When** it happened (`event_ts` in UTC, reported in AEST)
- **GPS coordinates** of the scan (where available)

This creates a full audit trail of every trolley movement.

---

## Rewards System Design

The `reward_ledger` table is designed to award points for dropoff events — incentivising shoppers to return trolleys to designated zones rather than leaving them in car parks.

Reward eligibility logic (Query 10 in analytics):
- Action must be `dropoff`
- The event must not already have a corresponding reward record
- Points awarded: 10 per qualifying dropoff

This design is intentionally flexible — point values and eligibility rules can be updated without schema changes.

---

## Security Design

All five tables are protected by Row Level Security (RLS). The policy structure balances openness for the public-facing scan app with strict data integrity:

- **Public app** (anon role): can submit scans, but only for trolleys and locations that actually exist
- **Authenticated users**: can submit scans tied to their user record
- **Service role**: full backend access for admin operations

This prevents invalid data from entering the system through the front-end app.

---

## Skills Demonstrated

| Skill | Evidence |
|---|---|
| Relational database design | 5-table normalised schema with FK constraints |
| SQL (DDL) | CREATE TABLE, constraints, identity columns |
| SQL (DML/Analytics) | 10 analytical queries covering aggregation, filtering, ratios, date functions |
| Data governance | RLS policies across all tables with role-based access |
| Business problem solving | target_min/target_max thresholds for stock management |
| Event-driven data architecture | timestamp + GPS capture on every trolley movement |
| Rewards/loyalty data modelling | reward_ledger linked to source events |

---

*FOLD Trolley Tracker | Arha | Melbourne, 2026*
