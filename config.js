// WannaBeer configuration
// 1. Create a free project at https://supabase.com
// 2. Run supabase/schema.sql in the SQL editor
// 3. Paste the Project URL and the anon public key below (Settings → API)
// Leave both empty to run in "link-only" mode (1-on-1, no server).
window.WANNABEER_CONFIG = {
  SUPABASE_URL: "",
  SUPABASE_ANON_KEY: "",

  // Optional: OpenRouteService key (https://openrouteservice.org, free tier)
  // to replace the cycling time estimate with real routed cycling times.
  ORS_KEY: "",

  // Travel model (tweak to taste)
  BIKE_KMH: 15,
  WALK_KMH: 4.8,
  METRO_KMH: 32,        // in-vehicle, straight-line adjusted
  DETOUR: 1.3,          // straight line → street distance factor
  METRO_WAIT_MIN: 4,    // platform wait
  METRO_TRANSFER_MIN: 5,// flat penalty when origin and destination stations differ
  MAX_WALK_TO_STATION_M: 1200,
};
