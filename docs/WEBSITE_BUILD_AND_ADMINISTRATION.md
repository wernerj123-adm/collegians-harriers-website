# Collegians Harriers Website

## Build Record and Administration Handbook

| Record | Value |
|---|---|
| Handbook version | 1.3.0 |
| Website build phase | Development v0.8.0 |
| Last updated | 28 August 2026 |
| Active development branch | `develop` |
| Stable production branch | `main` |
| Development preview | <https://wernerj123-adm.github.io/collegians-harriers-website/> |
| Repository | <https://github.com/wernerj123-adm/collegians-harriers-website> |
| Confirmed staging site | <https://staging.collegiansharriers.co.za/> |
| Confirmed staging document root | `/home/colletdr/staging.collegiansharriers.co.za/` |
| Planned production destination | Collegians Harriers cPanel hosting |

This is the living operating manual for the Collegians Harriers website. It records what has been built, explains how the site works, and gives future administrators safe, repeatable instructions for keeping it current.

Update this handbook whenever a website change introduces a new page, asset type, external service, publishing step, or administrative procedure.

---

## 1. Website purpose

The website is the official, long-lived information home for Collegians Harriers. Social media remains useful for day-to-day conversation, but important information should also be available here in an organised and accessible form.

The site is designed around these principles:

- Use the Collegians red, black, white and warm-neutral colour palette.
- Preserve the approved club crest without cropping or distortion.
- Make essential information easy to find on desktop and mobile devices.
- Keep membership, running, events, results, news and contact information in clear sections.
- Use approved, good-quality club photography selectively.
- Keep the site fast, readable and accessible.
- Publish only confirmed information and approved personal information or photographs.

---

## 2. Current website structure

The website is a static site. Each page is an HTML file, styling is stored in CSS files, and small interactive features use JavaScript. There is no database or content-management system at this stage.

### Pages

| Public page | Source file | Purpose |
|---|---|---|
| Home | `index.html` | Club introduction, primary calls to action, photography slideshow and featured content |
| About | `about.html` | Club identity, history, disciplines, location and leadership |
| Membership | `membership.html` | 2026 fees, application process and official membership form |
| Running | `running.html` | Weekly running, time trial, road, trail, championships and resources |
| Events | `events.html` | Overview of Collegians-hosted events |
| Results | `results.html` | Results hub for time trials, championships, hosted events and archives |
| Result detail | `results/YYYY/YYYY-MM-DD-result-name.html` | Mobile-friendly HTML version of an approved result document |
| Time-trial results | `time-trial-results.html` | Searchable weekly history with the newest HTML result and archived PDFs |
| Race and event results | `race-event-results.html` | Searchable race, championship and hosted-event history |
| Results archive | `results-archive.html` | Searchable historical library organised by season and result type |
| News | `news.html` | Club announcements, member stories and event updates |
| Club Photos | `photos.html` | Latest weekly activity gallery and searchable permanent photo archive |
| Contact | `contact.html` | Club location, contact routes and social channels |
| The Longest Day | `longest-day.html` | Dedicated 2026 event page |
| uMngeni-uThukela Water Marathon | `umngeni-uthukela-water-marathon.html` | Official 2026 information, flyer, routes, course records and historical results |
| Duke of York | `duke-of-york.html` | 16 km race history, historical route and result archive |
| Hogsback Trail Run | `hogsback.html` | Boxing Day trail tradition, photo history and participation archive |
| Bill Butler Social Run | `bill-butler.html` | Prediction-run format and historical results |
| Club History | `history.html` | Preserved club and event-history documents |
| Page not found | `404.html` | Branded recovery page for old, moved or mistyped links |

### Shared assets

| Location | Contents |
|---|---|
| `assets/img/` | Crest and approved club photographs |
| `assets/css/site.css` | Core site layout, colours, header, footer and shared components |
| `assets/css/pages-v02.css` | Inner-page components |
| `assets/css/pages-v03.css` | Later inner-page components and refinements |
| `assets/css/crest-fix.css` | Crest display corrections |
| `assets/css/watermark.css` | Subtle crest watermark used across pages |
| `assets/css/membership-notes.css` | Membership footnote styling |
| `assets/css/longest-day-v03.css` | The Longest Day page styling |
| `assets/css/longest-day-flyer-v051.css` | Responsive presentation for the official Longest Day flyer |
| `assets/css/event-series-v080.css` | Shared layout for hosted-event and history pages |
| `assets/css/production-v04.css` | Accessibility and production-browser refinements |
| `assets/css/home-gallery-v05.css` | Landing-page photo slideshow styling |
| `assets/css/not-found-v053.css` | Branded page-not-found layout |
| `assets/css/results-library-v054.css` | Published-results register and filters |
| `assets/css/result-detail-v057.css` | Responsive tables and summary cards for HTML result pages |
| `assets/css/results-archive-v058.css` | Searchable archive layout, filters and historical result rows |
| `assets/css/photo-library-v060.css` | Weekly photo highlights, archive cards and responsive filters |
| `assets/js/site.js` | Mobile navigation behaviour |
| `assets/js/home-gallery-v05.js` | Slideshow rotation, controls, swipe and reduced-motion behaviour |
| `assets/js/results-library-v054.js` | Loads, sorts and filters approved result records |
| `assets/js/results-archive-v058.js` | Loads and filters the historical archive register |
| `assets/js/photo-library-v060.js` | Loads weekly photos and provides archive search and filters |
| `assets/data/results.json` | Versioned public register of approved result files |
| `assets/data/results-archive.json` | Generated register of approved historical result files |
| `assets/data/photos.json` | Public register of approved weekly and archived photographs |
| `assets/results/YYYY/` | Approved result documents organised by year |
| `assets/results/archive/YYYY/` | Curated historical PDFs organised by season and result type |
| `assets/events/` | Current event route maps and operational documents |
| `assets/history/` | Preserved club, event and photographic history PDFs |
| `results/YYYY/` | Approved HTML result pages organised by year |
| `results-inbox/` | Local drop folder for approved PDFs awaiting preparation |
| `photo-inbox/` | Local drop folder for approved JPG and PNG photographs |
| `Publish Results.cmd` | User-friendly Windows launcher for result publishing |
| `Publish Photos.cmd` | User-friendly Windows launcher for weekly photo publishing |
| `scripts/publish-results.ps1` | Validates, files, registers and optionally publishes results |
| `scripts/build-time-trial-html.py` | Validates weekly result tables and creates responsive HTML result pages |
| `scripts/publish-photos.ps1` | Validates, files, registers and optionally publishes photographs |
| `scripts/build-results-archive.ps1` | Curates and verifies the historical result collection without overwriting published files |
| `Build Staging Package.cmd` | Creates a checked cPanel staging ZIP without uploading it |
| `scripts/build-deployment-package.ps1` | Builds staging or production packages from the approved Git branch |
| `deployment/production.htaccess` | Apache configuration copied into cPanel deployment packages |
| `.agents/skills/collegians-publish-results/SKILL.md` | Codex workflow for safe current-result publication and verification |
| `.agents/skills/collegians-publish-photos/SKILL.md` | Codex workflow for approved photo-album publication and verification |

### Important external links

| Service | Current address |
|---|---|
| 2026 membership form | <https://form.jotform.com/collegiansharriers/collegians-harriers-Member-2026> |
| Facebook | <https://www.facebook.com/CollegiansHarriersPmb> |
| Instagram | <https://www.instagram.com/collegiansharrierspmbrunning/> |
| Strava | <https://www.strava.com/clubs/collegiansharriers> |

External links should open in a new tab and use `rel="noopener noreferrer"`.

---

## 3. Build record to date

### Phase 0.1 — Foundation

1. Created a clean-sheet static website rather than copying the legacy layout.
2. Established the red, black, white and warm-neutral visual system.
3. Added the main navigation, responsive mobile menu and shared footer.
4. Created the first Home page and the initial page structure.

### Phase 0.2 — Core club pages

1. Replaced the original photographic hero with the current graphic/editorial hero.
2. Added the verified Collegians crest and corrected its display.
3. Built full About, Running and Events pages.
4. Added responsive cards, information panels, content sections and calls to action.

### Phase 0.3 — Operational content

1. Built the Membership, Results, News and Contact pages.
2. Added the published 2026 membership fee breakdown.
3. Connected every membership call to action to the official 2026 Jotform.
4. Added the family discount note and Tuesday Time Trial collection footnote.
5. Built the dedicated Longest Day 2026 page.
6. Added the club crest as a subtle watermark across the site.
7. Corrected the club founding statement to “Established in 1934 in Pietermaritzburg”.

### Phase 0.4 — Accessibility and browser polish

1. Added a keyboard-accessible “Skip to main content” link.
2. Added clear keyboard focus styles.
3. Marked the current navigation item for assistive technology.
4. Added image dimensions where needed to reduce layout movement.
5. Added reduced-motion handling and browser theme/favicons.

### Phase 0.5 — Club photography slideshow

1. Added two approved club photographs to `assets/img/`.
2. Added the “Running together” slideshow below the Home page quick links.
3. Added automatic rotation, previous/next buttons, slide selectors and a pause control.
4. Added touchscreen swipe support.
5. Added accessible captions, alternative text and live slide announcements.
6. Disabled automatic movement when a visitor has enabled reduced-motion preferences.
7. Added responsive landscape and portrait presentation rules.

### Phase 0.5.1 — Longest Day event flyer

1. Added the approved full-width 2026 event flyer to The Longest Day page.
2. Preserved the complete flyer artwork and sponsor treatment without cropping.
3. Added a full-size viewing link for readability on smaller screens.

### Phase 0.5.2 — Production content review

1. Removed internal build-language and outdated “being developed” statements from public pages.
2. Updated the Events page to reflect that The Longest Day page is complete.
3. Made the current absence of approved result files explicit without publishing unconfirmed data.
4. Clarified where members should check for short-notice running updates.
5. Updated the project roadmap to reflect the actual remaining content and deployment work.

### Phase 0.5.3 — Link recovery and site consistency

1. Added a branded 404 page with routes back to Home, Membership, Running, Events and Results.
2. Replaced obsolete public redesign-version labels with the club's founding year and location.
3. Added explicit crest image dimensions consistently across site pages.
4. Removed the remaining internal build-language from the About page.
5. Added a repeatable broken-link check to the administration workflow.

### Phase 0.5.4 — Results publishing foundation

1. Added a versioned JSON register for approved result files.
2. Added automatic newest-first sorting and category filters.
3. Added an accessible empty state while no approved files are published.
4. Created the year-based results directory and filename convention.
5. Changed the administration process so routine result uploads no longer require editing `results.html`.

### Phase 0.5.5 — Guided results publisher

1. Added a local drop folder for approved PDF results.
2. Added a Windows launcher and guided PowerShell publisher.
3. Added PDF, filename, date, category, duplicate and JSON validation.
4. Added optional Git commit and push to the `develop` preview.
5. Added safeguards against overwriting published files or including unrelated staged changes.

### Phase 0.5.6 — First published weekly result

1. Published the approved Herman's Delight weekly results for 25 August 2026.
2. Verified all three PDF pages visually before publication.
3. Added optional title and note overrides for controlled non-interactive publishing.
4. Clarified the category choices for time trials, road races, trail races, championships and hosted events.

### Phase 0.5.7 — HTML result detail pages

1. Converted the approved 25 August 2026 Herman's Delight PDF into a responsive HTML result page.
2. Made the HTML page the primary Results-library destination while retaining the original PDF as a secondary link.
3. Added reusable summary cards and responsive result-table styling for weekly, race and event results.
4. Extended the results register and publisher to accept an optional HTML page path.

### Phase 0.5.8 — Historical results archive

1. Audited the club Results library and separated public results from drafts, templates, signed forms and administrative documents.
2. Preserved 241 approved PDFs spanning the available 1983–2026 history.
3. Added a searchable archive with year, result-type and text filters.
4. Added an archive builder that prevents accidental overwriting and regenerates the archive register from the approved source collection.
5. Verified that every archived PDF opens, contains at least one page and renders correctly.

### Phase 0.5.9 — Dedicated historical result hubs

1. Connected the Time-trial and Race and event rows on the Results page to dedicated libraries.
2. Combined the newest weekly HTML result with 174 approved historical time-trial PDFs in one newest-first page.
3. Grouped 45 road, championship and hosted-event records into a separate searchable page.
4. Added document, season and latest-result summaries with responsive search and filtering.
5. Retained the original approved PDFs while allowing new publications to use the mobile-friendly HTML format.

### Phase 0.6.0 — Weekly club photo library

1. Added a dedicated Club Photos page to the main navigation and footer.
2. Added a latest-activity area and a permanent searchable photo archive.
3. Added year and activity filters with full-size image links.
4. Created a data-driven photo register so weekly additions do not require rebuilding the page layout.
5. Linked the Home slideshow to the complete photo archive and recorded photography/privacy controls.

### Phase 0.6.1 — Guided photo publisher

1. Added a simple `photo-inbox` drop folder and Windows launcher.
2. Added guided prompts for the date, public title, activity, alternative text and caption.
3. Added real-image validation, consistent filenames, weekly grouping and overwrite protection.
4. Added automatic photo-register updates and optional publication to `develop`.
5. Kept the same staged-change and branch safeguards used by the results publisher.

### Phase 0.6.2 — Batch or individual upload information

1. Added an information-mode choice whenever either publisher finds multiple files.
2. Shared mode asks for the common date and result category or photo activity once, then derives individual titles from filenames.
3. Individual mode retains the full per-file questions for titles, notes, alternative text and captions.
4. Verified both shared and individual multi-file preparation flows in isolated test repositories.

### Phase 0.6.3 — Event photo albums

1. Changed the photo archive from individual archive cards to event/day album cards.
2. Added a dedicated album view that displays all photographs belonging to the selected event.
3. Added album names and stable album identifiers to the photo register.
4. Updated the photo publisher to store files in `assets/img/gallery/YYYY/album-name/`.
5. Grouped the existing Spar Ladies photographs into the `Spar Ladies 2026` album and folder.

### Phase 0.6.4 — Duplicate-safe HTML time-trial publishing

1. Removed an exact duplicate of the 25 August 2026 weekly result from the current-results register and public files.
2. Added a one-weekly-result-per-date rule so renaming the same upload cannot create a second time-trial card.
3. Added SHA-256 content checking so an already published PDF is rejected even when its filename or category is changed.
4. Added automatic conversion of approved weekly PDFs into responsive HTML result pages while retaining the original PDF.
5. Added table, date, route and finisher-count validation before a weekly result is moved out of the inbox.

### Phase 0.6.5 — Reusable Codex publishing skills

1. Added a project skill for approved current-result uploads, duplicate checks, weekly HTML creation, Git publication and live verification.
2. Added a project skill for permission-aware photo inspection, album grouping, publication and gallery verification.
3. Kept both skills connected to the existing PowerShell publishers instead of duplicating their deterministic filing and register logic.
4. Added user-facing skill metadata and validated both skill packages with the official Codex skill validator.

### Phase 0.7.0 — cPanel deployment packaging

1. Added a one-click Windows builder for a clean cPanel staging upload ZIP.
2. Restricted staging packages to committed `develop` content and production packages to committed `main` content.
3. Excluded source-control, administration, inbox, documentation and automation files from the public package.
4. Added automatic internal-link, data-register and required-file validation before a ZIP can be produced.
5. Rewrote the GitHub Pages-specific 404 base path only inside the package and added Apache 404, security, caching and compression rules.
6. Added a deployment manifest containing the exact source branch and commit so every upload is traceable and recoverable.

### Phase 0.7.1 — cPanel staging deployment

1. Created and confirmed the staging domain at `staging.collegiansharriers.co.za`.
2. Confirmed its cPanel document root as `/home/colletdr/staging.collegiansharriers.co.za/`.
3. Backed up the initial staging files outside the public document root.
4. Uploaded and extracted the validated `develop` package from commit `6de1730`.
5. Moved the uploaded deployment ZIP outside the public document root after extraction.
6. Verified the live Home, Results, Photos, weekly-result and server-side 404 pages on desktop and mobile with no broken images, horizontal overflow or browser errors.
7. Confirmed that membership links open the official Jotform in a new tab with `noopener noreferrer` protection.

### Phase 0.7.2 — Header membership CTA alignment

1. Changed the desktop “Join the club” header action to a wider horizontal button that keeps its text on one line.
2. Added intermediate desktop spacing rules so the brand, navigation and membership action remain aligned without crowding.
3. Moved the navigation to the mobile menu slightly earlier on narrow screens to prevent header overflow.
4. Retained the existing compact mobile header and verified the change across desktop and phone widths.

### Phase 0.7.3 — Automatic complete-photo slideshow

1. Connected the Home slideshow directly to the approved `assets/data/photos.json` register.
2. Included every currently published photograph and made future guided photo uploads appear automatically without editing `index.html`.
3. Removed pointer-hover pausing so timed rotation continues while a desktop pointer rests over the photograph.
4. Retained previous, next, direct slide selection, pause/play, swipe, reduced-motion and screen-reader status controls.
5. Added a compact numeric position indicator for future registers containing more than ten photographs.
6. Deployed the validated package to cPanel staging and confirmed six live slides, timed advancement, complete images and a clean browser log.

### Phase 0.8.0 — Hosted-event and history reconstruction

1. Rebuilt the uMngeni-uThukela Water Marathon as a complete 2026 event page using the approved four-page flyer, route maps, event-day information and published course records.
2. Created dedicated Duke of York, Hogsback Trail Run and Bill Butler Social Run pages, separating historical information from future dates that are not yet confirmed.
3. Added a club History page for preserved club, Longest Day and Hogsback documents.
4. Recovered and indexed 22 additional hosted-event result PDFs, including Water Marathon results from 2003 to 2024, Duke of York results from 1983 to 2019 and Longest Day results from 2017 and 2019.
5. Updated the Events page and The Longest Day page to connect the new collections.
6. Extended the archive builder so these repository-managed legacy records remain registered during future rebuilds.

### Build milestone ledger

This table links the principal completed changes to their recoverable Git history. Smaller supporting commits remain available in the complete repository history.

| Commit | Milestone |
|---|---|
| `e97b716` | Replaced and cache-refreshed the verified crest |
| `8f0c047` | Added the v0.2 inner-page component system |
| `030b6db` | Built the About page |
| `fdfe06c` | Built the Running page |
| `d6764f4` | Built the Events page |
| `6fe3eed` | Updated membership calls to action to the official 2026 form |
| `f306f1c` | Added the site-wide crest watermark |
| `8c70d11` | Corrected the Home page founding year to 1934 |
| `543e793` | Built Membership, Results, News and Contact |
| `a4c79f4` | Built The Longest Day 2026 page |
| `def0feb` | Added the family discount collection clarification |
| `1566e45` | Refined the family discount footnote presentation |
| `bcb5ab7` | Added accessibility and production-browser polish |
| `0cfc41d` | Added the Home page club-photography slideshow |
| `95f28a4` | Connected the Home slideshow to every approved photograph and deployed it to staging |
| `77e0b15` | Rebuilt hosted-event pages and recovered the historical PDF collections |

---

## 4. Version-control policy

Version control keeps a complete record of changes and makes it possible to restore a previous working version.

### Branches

- `develop` is the active working branch and feeds the GitHub Pages development preview.
- `main` is the approved stable baseline intended for production releases.
- A `feature/short-description` branch may be used for a large or risky change.

Do not make experimental changes directly on `main`.

### Version numbers

Use three numbers: `major.minor.patch`.

- **Major**: a redesign, technology change or other change that substantially alters administration. Example: `1.0.0` to `2.0.0`.
- **Minor**: a new page, content area or feature. Example: `0.5.0` to `0.6.0`.
- **Patch**: a text correction, updated link, new result file or small styling fix. Example: `0.5.0` to `0.5.1`.

The public site version and this handbook version are tracked separately. Update the handbook version whenever this document changes.

### Commit descriptions

Use a short description beginning with one of these labels:

- `content:` for wording, dates, fees, news or results
- `feat:` for a new feature or page
- `fix:` for a correction
- `style:` for a visual-only change
- `docs:` for handbook or project documentation
- `chore:` for maintenance that does not change visible content

Examples:

```text
content: publish 2026-08-25 time trial results
content: add September club news
fix: correct Longest Day start time
feat: add race results archive
docs: update results publishing procedure
```

### Standard update workflow

1. Confirm the new content is accurate and approved for publication.
2. Start from the latest `develop` branch.
3. Make one focused update at a time.
4. Check the changed page on desktop and mobile.
5. Check every changed link and download.
6. Check spelling, dates, prices and contact information.
7. Commit the update with a clear description.
8. Push the commit to `develop`.
9. Wait for the GitHub Pages build to finish.
10. Review the development preview with a fresh version query, for example `?v=commit-number`.
11. Obtain approval before promoting an update to `main` or production hosting.
12. Record structural or procedural changes in this handbook.

### Safe rollback

If a published change is wrong, restore it by creating a new commit that reverses the problem. Do not delete the repository history or force-push shared branches.

Before rollback:

1. Identify the exact commit that introduced the problem.
2. Confirm whether later updates depend on it.
3. Revert only that commit.
4. Check the development preview again.
5. Record the reason in the new commit description.

---

## 5. Day-to-day website administration

### Administrator quick locations

The current Windows website folder is:

```text
C:\Users\werne\.codex\.chatgpt-projects\g-p-6a607ca870548191a931d90470b9a4ba\website
```

Paste that address into the File Explorer address bar to open the folder. If the repository is moved or copied in future, use the new folder that contains `index.html`, `Publish Results.cmd` and `Publish Photos.cmd` as the website root.

| Purpose | Location from the website root | What it does |
|---|---|---|
| Results launcher | `Publish Results.cmd` | Opens the guided result uploader |
| Results inbox | `results-inbox\` | Place approved PDF result files here before running the launcher |
| Results publishing script | `scripts\publish-results.ps1` | Advanced PowerShell version used by the launcher |
| Time-trial HTML converter | `scripts\build-time-trial-html.py` | Reads the approved weekly PDF and creates the mobile-friendly result page |
| Current-results register | `assets\data\results.json` | Records current published results and optional HTML pages |
| Published current PDFs | `assets\results\YYYY\` | Final result PDFs filed automatically by year |
| Result HTML pages | `results\YYYY\` | Mobile-friendly result pages, when available |
| Historical result register | `assets\data\results-archive.json` | Records the approved historical archive |
| Historical PDFs | `assets\results\archive\YYYY\` | Approved archive files arranged by year and type |
| Photos launcher | `Publish Photos.cmd` | Opens the guided weekly photo uploader |
| Photo inbox | `photo-inbox\` | Place approved JPG, JPEG or PNG files here before running the launcher |
| Photo publishing script | `scripts\publish-photos.ps1` | Advanced PowerShell version used by the launcher |
| Photo register | `assets\data\photos.json` | Controls the latest activity and searchable photo archive |
| Published photographs | `assets\img\gallery\YYYY\album-name\` | Photographs filed automatically by year and album/event |
| Results Codex skill | `.agents\skills\collegians-publish-results\SKILL.md` | Guides Codex through result validation, publication and deployment checks |
| Photos Codex skill | `.agents\skills\collegians-publish-photos\SKILL.md` | Guides Codex through approved album publication and gallery checks |
| Staging package launcher | `Build Staging Package.cmd` | Produces a checked staging ZIP from committed `develop` content |
| Deployment package builder | `scripts\build-deployment-package.ps1` | Advanced staging and production package builder |
| Local deployment output | `dist\` | Ignored working folder containing generated site folders and ZIP files |
| Administration handbook | `docs\WEBSITE_BUILD_AND_ADMINISTRATION.md` | This build record and operating manual |

The relevant online locations are:

| Online destination | Address |
|---|---|
| GitHub repository | <https://github.com/wernerj123-adm/collegians-harriers-website> |
| Development website | <https://wernerj123-adm.github.io/collegians-harriers-website/> |
| Results hub | <https://wernerj123-adm.github.io/collegians-harriers-website/results.html> |
| Time-trial history | <https://wernerj123-adm.github.io/collegians-harriers-website/time-trial-results.html> |
| Race and event history | <https://wernerj123-adm.github.io/collegians-harriers-website/race-event-results.html> |
| Club Photos | <https://wernerj123-adm.github.io/collegians-harriers-website/photos.html> |

#### Quick result upload

1. Copy the final approved PDF into `results-inbox\`.
2. Return to the main website folder and double-click `Publish Results.cmd`.
3. If several PDFs are present, choose shared information for the whole batch or individual information for every file.
4. Review the date, title, result type and optional note.
5. For **Time trial**, the publisher verifies that the date is not already published and automatically creates the HTML result page.
6. Answer **Yes** when asked whether to publish to `develop`.
7. Wait for GitHub Pages and verify both **View results** and **PDF** from the Results hub.

#### Quick weekly photo upload

1. Confirm publication permission and copy the approved JPG, JPEG or PNG files into `photo-inbox\`.
2. Return to the main website folder and double-click `Publish Photos.cmd`.
3. If several photographs are present, choose shared weekly information or individual information for every image.
4. Enter the same album/event name for photographs from the same day or event, for example `Spar Ladies 2026`.
5. Review the date, public title, activity type, alternative text and caption.
6. Answer **Yes** when asked whether to publish to `develop`.
7. Wait for GitHub Pages, open the album from Club Photos to verify every image, and confirm the new photographs also appear in the Home slideshow.

Files sitting in an inbox are local and are not part of the public website. Once a file is committed and pushed to this public repository, it is publicly accessible. Check results for unnecessary personal information and confirm photograph permissions before answering **Yes** to publication.

#### Use the Codex publishing skills

The Windows launchers remain the simplest manual option. When asking Codex to perform and verify the workflow, use either project skill explicitly:

```text
Use $collegians-publish-results to publish the approved result PDFs in the inbox.
Use $collegians-publish-photos to publish the approved photographs in the photo inbox.
```

The skill files are version-controlled with the website. They tell Codex to use the existing publishers, preserve unrelated work, inspect the source material, respect duplicate and permission safeguards, wait for GitHub Pages, and verify the live result or album. They do not themselves grant permission to publish unapproved material.

#### Install or share the Codex skills

The repository already contains the skills under `.agents/skills/`. A colleague who clones or pulls the website repository receives those project-local copies automatically and can invoke them while working in that repository.

To make the skills available across all Codex projects on one Windows PC, copy the complete skill folders into the user's personal Codex skills folder:

```text
%USERPROFILE%\.codex\skills\collegians-publish-results\
%USERPROFILE%\.codex\skills\collegians-publish-photos\
```

Copy each complete folder, including `SKILL.md` and `agents/openai.yaml`; do not transfer only the Markdown file. Start a new Codex task after installation so the new skills are discovered.

For transfer by email, OneDrive or another approved file-sharing service, ZIP each complete skill folder separately. The receiving colleague should inspect the instructions, extract each folder into `%USERPROFILE%\.codex\skills\`, and retain the skill folder name. These Collegians skills still require a checkout of this website containing the matching `Publish Results.cmd`, `Publish Photos.cmd` and `scripts/` files.

Personal copies do not update automatically. When the repository skills change, review the update and replace or reinstall the personal copies. Project-local copies update normally when the colleague pulls the latest repository branch.

### 5.1 Change text on an existing page

1. Identify the page from the table in Section 2.
2. Open its HTML file.
3. Search for the existing visible sentence or heading.
4. Change only the required text, keeping the surrounding HTML tags intact.
5. If a date is displayed inside a `<time>` element, update both the visible date and its `datetime` value.
6. Preview the page and check that the revised wording still fits on mobile.
7. Commit the update with a `content:` description.

Avoid pasting formatted text directly from Word. Paste plain text so that hidden formatting is not introduced.

### 5.2 Change a link

1. Search the entire repository for the old address.
2. Replace every intended occurrence, including the header, page calls to action and footer where applicable.
3. For an external link, include:

```html
target="_blank" rel="noopener noreferrer"
```

4. Open the updated link from the preview and confirm that it reaches the correct destination.
5. Commit with `fix:` or `content:` depending on the change.

The membership form appears in several pages. Always search the whole repository when it changes.

### 5.3 Add photographs to the Home slideshow

The Home slideshow reads the same approved `assets/data/photos.json` register used by Club Photos. Do not add slides manually to `index.html`.

1. Obtain permission to publish the photograph.
2. Resize and optimise it where possible; prefer JPG for photographs and aim for approximately 1 MB or less without visible quality loss.
3. Publish it using `Publish Photos.cmd` or the `collegians-publish-photos` skill described below.
4. Confirm that the publisher added the image to `assets/data/photos.json`.
5. Wait for GitHub Pages, then check the new photograph in both its Club Photos album and the Home slideshow.
6. Check the Home crop at desktop and phone sizes; landscape photographs normally present best, while portrait photographs remain supported.
7. Test automatic rotation, previous, next, slide selector, pause/play and swipe controls after substantial photo batches.

The slideshow uses direct slide buttons for up to ten photographs. With larger collections, it automatically switches to a compact current/total counter while continuing to rotate through every registered photograph.

### 5.3A Add weekly photographs to Club Photos

All approved registered photographs appear in the Home rotation and in `photos.html`, where they remain grouped into albums and searchable after newer weeks are added.

#### Recommended: guided photo publisher

1. Confirm that every photograph is approved for public use. Take particular care with identifiable children.
2. Resize and optimise large files before publication. Prefer JPG for ordinary photographs and aim for approximately 1 MB or less.
3. Copy the approved JPG, JPEG or PNG files into `photo-inbox/`.
4. Double-click `Publish Photos.cmd` in the main website folder.
5. If more than one file is present, choose **shared weekly information** or **individual information**.
6. Shared mode asks for the date, activity and album/event name once, then creates titles and captions from the filenames. Individual mode asks for all information for every photograph.
7. Use exactly the same album name for all files that belong together. `Spar Ladies 2026`, for example, becomes the folder `assets/img/gallery/2026/spar-ladies-2026/` and one clickable album on the website.
8. The publisher validates the image, calculates its Monday week date, moves it into `assets/img/gallery/YYYY/album-name/` and updates `assets/data/photos.json`.
9. When asked, choose whether to commit and push the prepared photographs to `develop` immediately.
10. Wait for GitHub Pages, then open `photos.html`, select the new album and check every full-size image.

Photographs from the same Monday-to-Sunday week are kept together in the latest-activity area. The publisher never overwrites an existing public filename. Give a revised or alternate photograph a different public title.

The guided publisher offers these consistent activity types: **Time trial**, **Training**, **Race day**, **Trail running**, **Hosted event** and **Club gathering**.

#### Manual fallback

1. Create the year and album folders if needed and place the optimised image in `assets/img/gallery/YYYY/album-name/`.
2. Open `assets/data/photos.json` and add one object inside the `photos` array:

```json
{
  "title": "Tuesday time trial",
  "album": "Tuesday Time Trial - 1 September 2026",
  "albumSlug": "tuesday-time-trial-1-september-2026",
  "date": "2026-09-01",
  "week": "2026-08-31",
  "year": 2026,
  "activity": "Time trial",
  "image": "assets/img/gallery/2026/tuesday-time-trial-1-september-2026/2026-09-01-tuesday-time-trial.jpg",
  "alt": "Collegians runners starting the Tuesday time trial",
  "caption": "Members heading out for the weekly club time trial."
}
```

3. Use the real activity date and the Monday of that week in `YYYY-MM-DD` format.
4. Write accurate alternative text describing what is visible; do not use the filename as alternative text.
5. Update the top-level `updated` date in `photos.json`.
6. Test the gallery on desktop and mobile, then commit the image and register together.

Alternative text should briefly describe what is visible and useful, not repeat the caption word for word.

### 5.4 Publish race or time-trial results

Only publish a final, checked result file. Confirm names, categories, times, positions, dates and any corrections before upload.

#### Recommended: guided inbox publisher

1. Name the approved PDF with its date first, for example `2026-08-25-tuesday-time-trial-results.pdf`.
2. Copy it into `results-inbox/`.
3. Double-click `Publish Results.cmd` in the main website folder.
4. If more than one PDF is present, choose **shared event information** or **individual information**.
5. Shared mode asks for the date, category and optional note once, then creates titles from the filenames. Individual mode asks for all information for every PDF.
6. For a weekly time trial, the publisher confirms that no time trial is already registered for that date and that the PDF contents have not previously been published.
7. The publisher reads the approved weekly PDF, checks its displayed date, route headings, result rows and finisher counts, then automatically creates a responsive HTML page.
8. The original PDF is moved into `assets/results/YYYY/`, the HTML page is stored in `results/YYYY/`, and both paths are added to `assets/data/results.json`.
9. When asked, choose whether to commit and push the prepared result to `develop` immediately.
10. Wait for GitHub Pages, then open the Results page and verify **View results**, the responsive tables and the original **PDF** link.
11. If publishing is declined, the files remain prepared locally for later review and commit.

The publisher never overwrites an existing public filename. It also allows only one weekly time-trial result per date. If a weekly result needs correction, do not upload it as a second result: replace the existing approved PDF and regenerate its existing HTML page in one controlled correction commit. Keep the same public paths so members do not see duplicate cards or broken bookmarks.

Automatic HTML conversion applies to PDFs exported in the approved Herman's Delight weekly-results layout. If the converter cannot reliably read the date, routes, rows or totals, it leaves the PDF in `results-inbox/` and explains what must be corrected. Python and the `pdfplumber` reader are required; if the launcher reports that the reader is missing, run:

```powershell
py -m pip install pdfplumber
```

The PDF is always retained as the approved source. Weekly time trials receive an HTML page automatically. For another result type with a separately prepared HTML page, pass its repository-relative location to the publisher with `-PagePath`, for example:

```powershell
.\scripts\publish-results.ps1 -PagePath "results/2026/2026-08-25-hermans-delight-weekly-results.html"
```

The Results card will then open the HTML page first and show the original PDF as a secondary option. The same arrangement may be used for weekly time trials, race results, championship standings and hosted-event results.

Use **Time trial** for weekly club results, **Road** or **Trail** for ordinary race results, **Championship** for season logs and standings, and **Hosted event** for results from events organised by Collegians.

#### Manual fallback

1. Export the approved result as an accessible PDF. Create a responsive HTML detail page when members should be able to read the result directly on the website.
2. Name the file consistently:

```text
YYYY-MM-DD-event-or-series-results.pdf
```

Example:

```text
2026-08-25-tuesday-time-trial-results.pdf
```

3. Store results by year:

```text
assets/results/2026/
```

4. Open `assets/data/results.json` and set `updated` to the publication date.
5. Add one record to the `results` list. Use only these category values: `time-trial`, `road`, `trail`, `championship` or `hosted-event`.
6. Include the title, event date, category, season, PDF file path and format. If an HTML detail page exists, add its repository-relative path as `page`. A short optional note may identify a revision or distance.
7. If the result belongs to a hosted event, also add a link from that event page.
8. Open the Results page in the development preview. Confirm that the new record appears in the correct newest-first position and filter.
9. Open both the HTML result and original PDF from the generated buttons and check the HTML page on a phone-sized screen.
10. Commit the result file and `results.json` together.

Example register entry:

```json
{
  "title": "Tuesday Time Trial — 25 August 2026",
  "date": "2026-08-25",
  "category": "time-trial",
  "season": 2026,
  "page": "results/2026/2026-08-25-tuesday-time-trial-results.html",
  "file": "assets/results/2026/2026-08-25-tuesday-time-trial-results.pdf",
  "format": "PDF",
  "note": "2.8 km and 5.6 km"
}
```

If a result is corrected later, update both the approved PDF and its existing HTML page, update the displayed revision date, and use a commit description that clearly says it is a corrected result. Do not add a second register entry for the same weekly date.

#### Maintain the historical archive

The archive is deliberately separate from the current-results register. Current publications continue to use `assets/data/results.json`; the historical library uses `assets/data/results-archive.json`.

1. Keep the club's master result PDFs in the OneDrive `Collegians\Results` structure.
2. Confirm that each document is intended for public use. Do not include blank templates, witness sheets, drafts, signed forms, entry registers or administration documents.
3. From the website folder, run:

```powershell
.\scripts\build-results-archive.ps1
```

4. If the master Results folder is somewhere else, provide it explicitly:

```powershell
.\scripts\build-results-archive.ps1 -SourceRoot "D:\Club\Results"
```

5. The builder adds approved documents under `assets/results/archive/YYYY/` and regenerates `assets/data/results-archive.json`.
6. It never replaces a published archive file with different content. If a correction is required, publish a clearly named revised document so the change remains visible in version control.
7. Open `results-archive.html` and test text search, season filters, result-type filters and several PDF links before committing.
8. Commit the archive register, new PDFs and any builder-policy change together.

The same register automatically feeds the public subject pages:

- `time-trial-results.html` shows the `time-trial` records and merges in current publications from `assets/data/results.json`.
- `race-event-results.html` shows `hosted-event`, `road`, `trail` and `championship` records.

After rebuilding the archive, test both subject pages as well as the complete archive. No manual HTML list needs to be maintained.

The curated rules currently cover Herman's Delight weekly results, Hogsback and Bill Butler hosted events, final club-championship documents and selected road-race results. Update the builder's explicit rules when a new historical series is approved for the archive.

### 5.5 Update championship standings

1. Confirm that the standings include all approved events up to the stated date.
2. Display a clear “Updated” date beside the standings.
3. Keep current road and trail standings separate.
4. Upload the approved file into the relevant year under `assets/results/`.
5. Place the newest standings before older versions on `results.html`.
6. Retain final season standings in the archive after the season closes.
7. Check category names and totals before publishing.

### 5.6 Add a news item

1. Confirm the headline, publication date, summary and destination link.
2. Open `news.html`.
3. Find the `news-grid` section.
4. Add the newest item first.
5. Use a proper `<time>` element and a short, scannable summary.
6. Link to a permanent website page when one exists; use social media only when it is the original or only destination.
7. Move expired notices out of the prominent first position.
8. Check all dates and links before publishing.

Example structure:

```html
<article class="news-card">
  <time datetime="2026-09-01">1 September 2026</time>
  <h3>Short news headline</h3>
  <p>A concise summary explaining what members need to know.</p>
  <a href="events.html">Read more →</a>
</article>
```

### 5.7 Add or update an event

For a short listing:

1. Add or update the event card in `events.html`.
2. Include the confirmed date, venue, distances or format, and entry/status information.
3. Link to the official entry page using secure external-link attributes.

For a major Collegians event:

1. Use `longest-day.html` as the structural reference.
2. Create a descriptive lowercase filename, for example `duke-of-york.html`.
3. Add the shared header, navigation and footer.
4. Add event-specific content and styling only where needed.
5. Link the dedicated page from `events.html`, the Home page when featured, and relevant News items.
6. Test entry, rules, venue, contact and result links.
7. After the event, add results and retain the page as part of the event archive.

### 5.8 Update membership information

Membership information is time-sensitive and should be checked at the start of every membership year.

1. Confirm fees and wording against the approved club schedule.
2. Update the year, fee breakdown, new-member items and special conditions in `membership.html`.
3. Confirm the official application/renewal form address.
4. Search every HTML file for the previous membership address and year.
5. Keep fee notes immediately beside the fee they qualify.
6. Open every “Join the club” and “Join Collegians” button from the preview.
7. Confirm external links open in a new tab safely.
8. Commit the annual update as one clearly described change.

### 5.9 Add a downloadable club document

1. Confirm the document is final and approved.
2. Use PDF for documents that should preserve formatting.
3. Use a descriptive filename containing the year where relevant.
4. Store it in a suitable directory such as:

```text
assets/documents/2026/
```

5. Add a link that states the document name and file type.
6. Check that the document opens from the development preview.
7. Remove personal or confidential information before publication.

### 5.10 Change navigation or footer links

The header and footer are repeated in each HTML page because the site is currently static.

1. Make the same navigation or footer change in every HTML file.
2. On each page, ensure only that page’s navigation link has `class="active"` and `aria-current="page"`.
3. Check the desktop navigation, mobile menu and footer.
4. Search the repository for the old link or wording to confirm none were missed.

### 5.11 Change CSS or JavaScript

1. Prefer a small, clearly named stylesheet or script for a distinct new feature.
2. Keep shared rules in the existing shared files.
3. After changing a linked CSS or JavaScript file, update its version query in the HTML, for example:

```html
assets/css/example.css?v=20260826b
```

4. Test desktop, tablet and mobile layouts.
5. Test keyboard navigation and visible focus.
6. Test with reduced motion where animation is involved.
7. Check that existing pages have not changed unexpectedly.

### 5.12 Check broken links and the 404 page

1. Check every internal link after adding, renaming or removing a page or document.
2. Confirm that each local link points to a file that exists in the repository.
3. Open a deliberately incorrect development-preview address and confirm that `404.html` appears.
4. Test the Home, Membership, Running, Events and Results recovery links.
5. The source 404 page uses the GitHub Pages project base `/collegians-harriers-website/`. The deployment package builder changes it to `/` inside the cPanel package; do not edit the source page for this purpose.
6. Do not redirect every missing address automatically; visitors should be told that the requested page was not found.

### 5.13 Build and upload a cPanel package

The builder prepares a reviewable upload package. It does not sign in to cPanel, transmit files or change the live website.

#### Build a staging package

1. Confirm all intended changes are committed and pushed to `develop`.
2. Confirm the working tree is clean.
3. Double-click `Build Staging Package.cmd` in the main website folder.
4. The builder copies only public HTML, CSS, JavaScript, JSON, images, fonts and PDFs into a new `dist/staging-COMMIT/site/` folder.
5. It validates internal HTML and CSS references, result/photo register file paths, blocked administration extensions and required ZIP entries.
6. It changes the packaged 404 base path to `/`, adds `.htaccess`, and writes `deployment-manifest.json` with the source commit.
7. If all checks pass, use the ZIP named `dist/collegians-harriers-staging-COMMIT.zip` for the approved staging upload.

If the same commit has already been packaged, the builder stops rather than overwriting it. An administrator may rebuild that exact commit with:

```powershell
.\scripts\build-deployment-package.ps1 -Channel staging -Force
```

#### Upload to cPanel staging

1. Confirm the approved staging domain and its exact cPanel document root with the hosting administrator.
2. Back up any existing staging files before replacement.
3. Upload the generated ZIP into that document root using cPanel File Manager or the approved SFTP account.
4. Extract the ZIP so `index.html`, `.htaccess`, `assets/` and `results/` sit directly in the staging document root, not inside an extra folder.
5. Open `deployment-manifest.json` on staging and confirm its commit matches the approved package.
6. Test navigation, membership links, photo albums, current and archived results, PDF downloads, the mobile menu and a deliberately missing URL.
7. Do not promote staging to production until the club approves the staging review.

#### Confirmed staging configuration — 27 August 2026

| Item | Confirmed value |
|---|---|
| Staging address | `https://staging.collegiansharriers.co.za/` |
| cPanel document root | `/home/colletdr/staging.collegiansharriers.co.za/` |
| Deployed source | `develop` commit `95f28a4b2d2522a5f3b8ac8bdb4581fbc3815148` |
| Current deployment package | `/home/colletdr/collegians-harriers-staging-95f28a4b.zip` |
| Previous known-good package | `/home/colletdr/collegians-harriers-staging-6de17300.zip` |
| Pre-deployment backup | `/home/colletdr/staging-predeploy-defaults-20260827.zip` |

The deployment packages and backup are deliberately stored in `/home/colletdr/`, outside the public staging document root. No hosting credentials are stored in the repository or this handbook.

#### Staging rollback procedure

1. In cPanel File Manager, confirm that the current folder is exactly `/home/colletdr/staging.collegiansharriers.co.za/`.
2. Before changing the deployed site, compress its current contents into a new dated ZIP stored in `/home/colletdr/`.
3. Remove only the failed staging deployment files from the confirmed staging document root; do not alter `public_html` or any other domain folder.
4. Extract the last known-good staging package from `/home/colletdr/` back into the staging document root.
5. Confirm that `index.html`, `.htaccess`, `assets/` and `results/` sit directly in the document root.
6. Retest the Home page, results, photographs, downloads, mobile menu and a deliberately missing URL.

The small `staging-predeploy-defaults-20260827.zip` archive restores only the hosting provider's original placeholder files. Use the retained `collegians-harriers-staging-95f28a4b.zip` package as the current known-good website rollback package; the earlier `collegians-harriers-staging-6de17300.zip` package remains available as a secondary fallback.

Never store cPanel passwords, SFTP credentials or private keys in this repository or the deployment ZIP.

#### Build a production package

Production packages are allowed only from a clean `main` branch after an approved promotion from `develop`:

```powershell
.\scripts\build-deployment-package.ps1 -Channel production
```

Record the previous production commit before uploading so rollback remains possible. The same validation and folder-placement rules used for staging apply to production.

---

## 6. Pre-publication checklist

Complete the relevant checks before every push to `develop`:

### Content

- [ ] Names, dates, times, prices and venues are confirmed.
- [ ] Headings and link wording are clear.
- [ ] No draft notes or placeholder text remain.
- [ ] Personal information and photographs are approved for publication.

### Links and files

- [ ] Every changed link opens the intended destination.
- [ ] External links use a new tab and safe `rel` attributes.
- [ ] Downloads open successfully.
- [ ] Filenames contain no spaces and use lowercase hyphenated wording.

### Visual quality

- [ ] The page works on a desktop-sized screen.
- [ ] The page works on a phone-sized screen without horizontal scrolling.
- [ ] Images are sharp, correctly cropped and not distorted.
- [ ] The crest is not altered, stretched or cropped.

### Accessibility

- [ ] Informative images have useful alternative text.
- [ ] Buttons and links have clear names.
- [ ] Keyboard focus remains visible.
- [ ] Colour is not the only way information is communicated.
- [ ] Animation respects reduced-motion preferences.

### Version control and deployment

- [ ] The working branch is `develop` or an approved feature branch.
- [ ] The commit description accurately describes the update.
- [ ] GitHub Pages finishes successfully.
- [ ] The live development preview is checked after deployment.
- [ ] This handbook is updated if the site structure or procedure changed.

---

## 7. Routine maintenance schedule

### Weekly

- Publish approved time-trial or event results.
- Remove or revise urgent notices that are no longer current.
- Check the Home, News and Events pages for outdated information.

### Monthly

- Test the main navigation and important external links.
- Review upcoming event dates and entry links.
- Check downloads and results files.
- Review mobile presentation of recently added content.

### Annually

- Update membership year, fees, form link and membership conditions.
- Update committee or leadership information.
- Start new results and documents folders for the year.
- Archive the previous year’s final results and event information.
- Review copyright, photography permissions and contact details.
- Review browser accessibility and performance.

---

## 8. Security, privacy and content ownership

- Never commit passwords, hosting credentials, personal access tokens or private keys.
- Do not publish member telephone numbers, email addresses, medical information or other personal data without approval.
- Confirm permission before publishing identifiable photographs, especially photographs of children.
- Use only club-owned, licensed or expressly approved images and documents.
- Check result files for personal information that is not required for the published sporting record.
- Keep administrator access limited to authorised people and enable two-factor authentication on GitHub and hosting accounts.

---

## 9. Backup and recovery

The GitHub repository is the source of truth and provides the version history. Production hosting should be treated as a deployed copy, not the only copy of the site.

1. Keep all website changes in Git before deployment.
2. Do not edit the production files directly unless handling an emergency.
3. If an emergency production edit is made, reproduce it immediately in the repository.
4. Keep original approved result files, documents and photographs in the club’s managed storage as well as the website repository.
5. Before a major production release, confirm that the previous stable commit is known and recoverable.

---

## 10. Planned future work

- Continue converting newly approved results to mobile-friendly HTML while retaining each source PDF.
- Add a structured document library where required.
- Add future event dates and entry links only after the organising committee confirms them.
- Obtain club approval of the validated cPanel staging site, then promote the approved commit to `main` and build the production package.
- Consider a simple content-management workflow if nontechnical administrators need to publish frequently.
- Consider reusable site includes or a static-site generator if repeated navigation and footer maintenance becomes burdensome.

These are planned items, not completed features.

---

## 11. Handbook change log

### 1.3.0 — 28 August 2026

- Documented the reconstructed Water Marathon, Duke of York, Hogsback, Bill Butler and club-history pages.
- Recorded the recovered route, flyer, photo-history and hosted-event PDF structure.
- Updated the archive total to 241 approved PDFs and advanced the development build to v0.8.0.

### 1.2.4 — 27 August 2026

- Recorded deployment of `develop` commit `95f28a4b` to the confirmed cPanel staging document root.
- Confirmed that the live staging Home slideshow loads all six registered photographs, advances automatically and has no broken images or browser warnings.
- Updated the off-root deployment and rollback package record.

### 1.2.3 — 27 August 2026

- Connected the Home slideshow to the complete approved photo register.
- Removed pointer-hover pausing and documented automatic inclusion of future photo uploads.
- Replaced the former manual Home-slide editing instructions and advanced the build to v0.7.3.

### 1.2.2 — 27 August 2026

- Refined the desktop “Join the club” header action into a consistently aligned, single-line button.
- Added an earlier responsive navigation breakpoint to prevent crowding on narrow desktop screens.
- Advanced the development build to v0.7.2.

### 1.2.1 — 27 August 2026

- Recorded the successful cPanel staging deployment and live validation.
- Documented the confirmed staging address, document root, source commit and off-root backup locations.
- Added the tested staging rollback procedure and advanced the build to v0.7.1.

### 1.2.0 — 27 August 2026

- Added deterministic staging and production package generation for cPanel hosting.
- Added clean-branch, public-file, link, data-register, 404, ZIP and manifest safeguards.
- Documented staging upload, review, production promotion and rollback boundaries and advanced the build to v0.7.0.

### 1.1.7 — 27 August 2026

- Documented personal installation of the two Collegians publishing skills.
- Added colleague-transfer instructions for Git repository, folder-copy and ZIP workflows.
- Clarified discovery, required companion scripts and future skill updates.

### 1.1.6 — 27 August 2026

- Added project-local Codex skills for current results and photo-album publication.
- Documented their locations, invocation names, authorization boundaries and relationship to the Windows launchers.
- Advanced the development build to v0.6.5.

### 1.1.5 — 27 August 2026

- Added same-date and identical-content duplicate protection for result uploads.
- Added automatic responsive HTML conversion and validation for weekly time-trial PDFs.
- Documented the single-record correction policy and advanced the build to v0.6.4.

### 1.1.4 — 27 August 2026

- Added event/day albums, album URLs and physical year/album folders.
- Documented how matching album names group future photographs together.
- Recorded the migration of the Spar Ladies photographs and advanced the build to v0.6.3.

### 1.1.3 — 27 August 2026

- Added shared-batch and individual-file information modes to both uploaders.
- Documented how filenames supply individual titles when shared information is selected.
- Advanced the development build to v0.6.2.

### 1.1.2 — 27 August 2026

- Added the exact current Windows website folder and a quick-reference location table.
- Recorded the result and photo launchers, inboxes, scripts, registers and published destinations.
- Added concise result and weekly-photo upload checklists with public-repository guidance.

### 1.1.1 — 27 August 2026

- Added the guided photo-inbox publisher, Windows launcher and publication safeguards.
- Documented automatic weekly grouping and the manual JSON fallback.
- Advanced the development build to v0.6.1.

### 1.1.0 — 26 August 2026

- Added the weekly Club Photos page, permanent photo archive and site-wide navigation link.
- Documented the data-driven weekly photo publishing and privacy procedure.
- Advanced the development build to v0.6.0.

### 1.0.9 — 26 August 2026

- Added the dedicated time-trial and race/event historical result hubs.
- Documented how current HTML results and approved archive PDFs are combined automatically.
- Advanced the development build to v0.5.9.

### 1.0.6 — 26 August 2026

- Recorded the first approved weekly result published through the register.
- Added clear category guidance for race and event result files.
- Documented controlled title and note overrides and advanced the development build to v0.5.6.

### 1.0.5 — 26 August 2026

- Added the guided results-inbox publisher and Windows launcher instructions.
- Documented automated validation, preparation and optional `develop` publication.
- Advanced the development build to v0.5.5.

### 1.0.4 — 26 August 2026

- Added the data-driven results publishing procedure and register schema.
- Recorded the results library, year folders, automatic sorting and filters.
- Advanced the development build to v0.5.4.

### 1.0.3 — 26 August 2026

- Added the custom 404 recovery page and its administration procedure.
- Recorded the site-wide footer and crest-dimension consistency pass.
- Advanced the development build to v0.5.3.

### 1.0.2 — 26 August 2026

- Recorded the production content review across Running, Events, Results and News.
- Updated the remaining-work roadmap and advanced the development build to v0.5.2.

### 1.0.1 — 26 August 2026

- Recorded the addition of the approved 2026 flyer to The Longest Day page.
- Advanced the development build record to v0.5.1.

### 1.0.0 — 26 August 2026

- Created the initial build record covering development phases 0.1 through 0.5.
- Documented the current page, asset, branch and deployment structure.
- Added procedures for page edits, links, photos, results, standings, news, events, membership and downloads.
- Added publishing, quality, accessibility, privacy, backup and rollback guidance.

### Change-log template

Copy this block for the next handbook update:

```text
### X.Y.Z — DD Month YYYY

- Describe the procedure, structure or build record that changed.
- State why the handbook needed to change.
```
