# Collegians Harriers Website

Clean-sheet redesign of the Collegians Harriers website.

This GitHub repository is the source of truth for the new site. The legacy website is reference material only and its old design is not being migrated.

## Initial priorities

- New Home page and hero treatment
- Correct high-quality Collegians crest/logo
- Responsive navigation and mobile layout
- Membership, Running, Events, Results, News and Contact sections
- Longest Day 2026 page
- cPanel staging validation and approved production promotion

## Website handbook

The living build record, version-control policy and step-by-step administration instructions are maintained in [docs/WEBSITE_BUILD_AND_ADMINISTRATION.md](docs/WEBSITE_BUILD_AND_ADMINISTRATION.md).

Update the handbook in the same commit whenever a website change alters the site structure or an administration procedure.

## Publishing results

Approved PDF results can be placed in `results-inbox/` and published with `Publish Results.cmd`. The guided publisher files the PDFs by year, updates the public Results register and can optionally commit and push the update to `develop`.

## Building a cPanel staging package

Run `Build Staging Package.cmd` from a clean, committed `develop` branch. It creates a validated public-site folder and upload ZIP under the ignored `dist/` directory without accessing the hosting account. Staging upload and production promotion remain approval-controlled steps documented in the website handbook.
