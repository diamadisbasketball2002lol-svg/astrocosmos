# Cosmic Explorer — secure publishing starter

This bundle contains your existing Cosmic Explorer page plus a Supabase-backed admin dashboard starter.

## What is included
- `index.html`: the existing Cosmic Explorer HTML copied without redesigning its contents.
- `admin/index.html`: email/password sign-in and CRUD editor for content, quizzes and settings.
- `admin/config.example.js`: browser-safe configuration template.
- `supabase/schema.sql`: database tables, RLS policies, and a private admin allow-list.

## Important status / limitation
This is a **starter architecture**, not a live deployment. The admin dashboard manages records in Supabase, but the existing HTML still contains its current content/quizzes in JavaScript. The next integration step is to connect the public page to `site_content`, `quizzes`, and `site_settings` so edits in the dashboard update the public website. Keep the existing website live until that integration is tested.

## A. Set up Supabase
1. Open https://supabase.com and create a project. Save the database password somewhere private; do not put it in site files.
2. In Project Settings / API, copy the Project URL and the publishable key (or legacy anon key). Do **not** copy a `service_role` or secret key into any browser file.
3. Open SQL Editor in the Supabase dashboard and run all of `supabase/schema.sql`.
4. In Authentication settings, disable public sign-ups if you don't need other accounts. Add your owner account using the dashboard's user-management interface (invite/create a user) and use a strong unique password. Enable MFA where available.
5. Find your account's UUID in Authentication > Users. In SQL Editor, run this after replacing the placeholder with your exact UUID:
   `insert into public.admin_users (user_id) values ('YOUR-AUTH-USER-UUID');`
   Never use an email supplied by a visitor as proof of admin. The UUID must be the account you control.
6. Copy `admin/config.example.js` to `admin/config.js` and replace the two placeholders. The URL and publishable/anon key are expected to be visible to browsers; security comes from Auth and RLS. Never add a secret/service-role key.

## B. Test locally before publishing
1. Open `index.html` to test the public page.
2. Serve the folder over localhost (rather than `file://`) for auth testing. If Python is installed, open a terminal in this folder and run `python -m http.server 8080`, then visit `http://localhost:8080/admin/`.
3. Sign in with the owner account. Try creating a draft content record, a quiz record, and a setting. Sign out and confirm the dashboard is no longer accessible for edits. Do not publish any record until the public page integration is complete.

## C. Publish with a custom domain (Cloudflare Pages)
1. Put this folder in a private GitHub repository. Do not commit passwords, database credentials, or secret keys. `admin/config.js` contains only a publishable key, but if you prefer, add it as a file in the repository after configuring it.
2. In Cloudflare, open Workers & Pages > Create > Pages > Connect to Git and select the repository.
3. For a plain HTML project, use build command `exit 0` and the project root as the output directory (if this folder is the repository root, use `.`).
4. Deploy and test the generated `*.pages.dev` URL.
5. In the Pages project, open Custom domains > Set up a domain. Follow the dashboard's instructions. For an apex domain (`example.com`), Cloudflare requires the domain to be added as a zone and its nameservers pointed to Cloudflare. For a subdomain, use the provided CNAME instructions.
6. Wait for domain verification and HTTPS to become active, then test the site and `/admin/` over `https://`.

## D. Supabase Auth URL settings
Once you know the final domain, configure Supabase Authentication URL settings:
- Site URL: `https://YOUR-DOMAIN`
- Add Redirect URLs for `https://YOUR-DOMAIN/**` and your local testing URL if needed.
Use your exact domain, not the placeholder.

## E. Before calling it finished
- Connect public page sections to published rows in Supabase; currently this starter's dashboard data does not automatically replace the existing hard-coded page content.
- Test that anonymous users can read only published content/quizzes and public settings, and cannot insert/update/delete anything.
- Test that a normal authenticated account cannot write any records and that only the UUID in `admin_users` can.
- Keep RLS enabled. Do not expose the Supabase service-role key. Back up the project and enable MFA on owner accounts.
- Register/buy the domain and manage billing with a parent/guardian if required by the registrar's age and payment rules.

## Architecture
Browser (public site/admin) -> Supabase Auth -> PostgreSQL tables protected by RLS. `public.is_admin()` checks a private `admin_users` allow-list; clients have no direct grants on that allow-list. Content writes require `is_admin() = true` at the database layer.
