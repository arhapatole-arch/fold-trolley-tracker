import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * FOLD Trolley Tracker — Threshold Alert Edge Function
 * 
 * Checks all active locations against their target_min / target_max thresholds.
 * Returns a JSON list of alerts for any location that is under or overstocked.
 * 
 * Deploy: supabase functions deploy trolley-threshold-check
 * Invoke:  GET /functions/v1/trolley-threshold-check
 * 
 * For automated alerting, call this on a cron schedule via:
 *   Supabase Dashboard → Edge Functions → Schedule
 */

Deno.serve(async (_req: Request) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // Get all active locations with their target thresholds
  const { data: locations, error: locErr } = await supabase
    .from("locations")
    .select("location_id, location_name, store_code, zone, target_min, target_max")
    .eq("is_active", true);

  if (locErr) return new Response(JSON.stringify({ error: locErr.message }), { status: 500 });

  // Count trolleys currently at each location
  const { data: trolleys, error: trErr } = await supabase
    .from("trolleys")
    .select("current_location_id")
    .eq("status", "active");

  if (trErr) return new Response(JSON.stringify({ error: trErr.message }), { status: 500 });

  // Build count map per location
  const countMap: Record<number, number> = {};
  for (const t of trolleys ?? []) {
    if (t.current_location_id) {
      countMap[t.current_location_id] = (countMap[t.current_location_id] ?? 0) + 1;
    }
  }

  // Evaluate each location against thresholds
  const alerts: object[] = [];
  for (const loc of locations ?? []) {
    const current = countMap[loc.location_id] ?? 0;
    let status = "ok";
    let message = "";

    if (current < loc.target_min) {
      status = "UNDERSTOCKED";
      message = `${loc.location_name} has ${current} trolleys — below minimum of ${loc.target_min}. Staff restock needed.`;
    } else if (current > loc.target_max) {
      status = "OVERSTOCKED";
      message = `${loc.location_name} has ${current} trolleys — above maximum of ${loc.target_max}. Redistribution needed.`;
    }

    if (status !== "ok") {
      alerts.push({
        location_id: loc.location_id,
        location_name: loc.location_name,
        store_code: loc.store_code,
        zone: loc.zone,
        current_count: current,
        target_min: loc.target_min,
        target_max: loc.target_max,
        status,
        message,
      });
    }
  }

  const result = {
    checked_at: new Date().toISOString(),
    locations_checked: locations?.length ?? 0,
    alerts_count: alerts.length,
    alerts,
  };

  console.log("Threshold check complete:", JSON.stringify(result));

  return new Response(JSON.stringify(result, null, 2), {
    headers: { "Content-Type": "application/json" },
  });
});
