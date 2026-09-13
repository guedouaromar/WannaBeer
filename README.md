# WannaBeer 🍺

Ask friends for a beer. When they say **Yes** (the *No* button runs away), everyone shares their location and the app suggests bars that are **fair for the whole group** — ranked so that nobody's trip is much longer than anyone else's, using the best of **bike / metro / walk** for each person.

Works in any city: bars and metro / light-rail stations come from OpenStreetMap.

## How it works

1. **Host** opens the page, enters a name, shares location → gets an invite link.
2. **Friend** opens the link, sees *"Hey Karim, want to grab a beer?"*, taps Yes, shares location.
3. Everyone sees the plan: participants on a map and the top 5 bars, each with per-person times and a **Route ↗** link opening Google Maps directions (bicycling / transit / walking).

Ranking = minimise the *longest* trip among participants (tie-break: total time).

Travel times are estimates from straight-line distance × 1.3 detour factor (bike 15 km/h, walk 4.8 km/h; metro = walk to nearest station + wait + ride + walk). Add an OpenRouteService key in `config.js` to replace the cycling estimate with real routed times.

## Setup (5 minutes)

### 1. Supabase (free) — needed for groups and live updates
1. Create a project at [supabase.com](https://supabase.com).
2. SQL Editor → paste `supabase/schema.sql` → Run.
3. Settings → API → copy **Project URL** and **anon public** key into `config.js`.

Without keys the app still works in **link-only mode** (1-on-1): the host's location is encoded in the link and the friend's phone computes the bar.

### 2. GitHub Pages
Repo → Settings → Pages → Source: `main` / root. The site is then at
`https://guedouaromar.github.io/WannaBeer/`.

Geolocation requires HTTPS, which GitHub Pages provides.

## Files
- `index.html` — the whole app
- `config.js` — keys and travel-model constants
- `supabase/schema.sql` — two tables + row-level-security policies

## Privacy
Locations are stored only as plan participants, readable by anyone holding the plan link (a random UUID). The optional pg_cron line in `schema.sql` deletes plans after 2 days.
