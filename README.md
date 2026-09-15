# WannaBeer 🍺

Ask friends for a beer. When they say **Yes** (the *No* button runs away), everyone shares their location and the app suggests bars that are **fair for the whole group** — ranked so that nobody's trip is much longer than anyone else's, using the best of **bike / metro / walk** for each person.

Works in any city: bars and metro / light-rail stations come from OpenStreetMap.

## How it works

1. **Host** opens the page, enters a name, shares location → gets an invite link.
2. **Friend** opens the link, sees *"Hey Karim, want to grab a beer?"*, taps Yes, shares location.
3. Everyone sees the plan: participants on a map and the top 5 bars, each with per-person times and a **Route ↗** link opening Google Maps directions (bicycling / transit / walking).

Ranking = minimise the *longest* trip among participants (tie-break: total time).

**Favourites.** Tap ☆ on any bar to star it. A participant's favourite is suggested first whenever its longest trip is within `FAV_TOLERANCE_MIN` (default 10 min) of the fairest bar, tagged "⭐ Name". Favourites are tied to the browser (no login), so star from the phone you use to say yes.

**Accounts & friends (optional).** Sign in with Google or an email login link. Then you can pick friends from a list instead of sharing a link: they see "Omar wants a beer" on their home screen and get an email whose link drops them straight onto the plan. Friends are added by email, or automatically after a beer together (with a running count); ★ pins a friend to the front of the list. Link sharing keeps working for anyone without an account.

**Google Maps pins.** Google offers no API for saved places, but you can import them once: [Google Takeout](https://takeout.google.com) → deselect all → tick **Maps (your places)** → export → upload `Saved Places.json` via "Import my Google Maps saved places" on the home page. Imported places count as favourites only when OpenStreetMap knows a bar at that spot (so your home doesn't get suggested).

Travel times are estimates from straight-line distance × 1.3 detour factor (bike 15 km/h, walk 4.8 km/h; metro = walk to nearest station + wait + ride + walk). Add an OpenRouteService key in `config.js` to replace the cycling estimate with real routed times.

## Setup (5 minutes)

### 1. Supabase (free) — needed for groups and live updates
1. Create a project at [supabase.com](https://supabase.com).
2. SQL Editor → paste `supabase/schema.sql` → Run. Then `supabase/002_favourites.sql` → Run. Then `supabase/003_accounts.sql` → Run.
3. Settings → API → copy **Project URL** and **anon public** key into `config.js`.

### 1b. Sign-in (for accounts & friends)
1. **Authentication → URL Configuration**: Site URL = your app URL (e.g. `https://wannabeer.netlify.app`), and add `https://wannabeer.netlify.app/**` to Redirect URLs (also the GitHub Pages URL if you use both).
2. **Email login links**: work out of the box, but Supabase's built-in mailer is limited to a couple of emails per hour. For real use, set **Authentication → SMTP Settings** to a free provider (e.g. Resend, Brevo, or Gmail with an app password).
3. **Invite email wording**: Authentication → Email Templates → *Magic Link*. The same template is used for sign-in and for beer invites, so something like *"Someone wants a beer with you 🍺 — tap to see where"* works for both.
4. **Google sign-in** (optional): Google Cloud Console → APIs & Services → Credentials → OAuth client (Web). Authorised redirect URI = `https://<your-project>.supabase.co/auth/v1/callback`. Paste client ID/secret in Supabase → Authentication → Providers → Google.

Without keys the app still works in **link-only mode** (1-on-1): the host's location is encoded in the link and the friend's phone computes the bar.

### 2. GitHub Pages
Repo → Settings → Pages → Source: `main` / root. The site is then at
`https://guedouaromar.github.io/WannaBeer/`.

Geolocation requires HTTPS, which GitHub Pages provides.

## Files
- `index.html` — the whole app
- `config.js` — keys and travel-model constants
- `supabase/schema.sql` — plans + participants tables with row-level-security policies
- `supabase/002_favourites.sql` — favourites table + `participants.device_id`
- `supabase/003_accounts.sql` — profiles, friends, invites + policies for signed-in users

## Privacy
Locations are stored only as plan participants, readable by anyone holding the plan link (a random UUID). The optional pg_cron line in `schema.sql` deletes plans after 2 days.
