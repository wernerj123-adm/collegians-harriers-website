# Collegians Harriers Website

## Build Record and Administration Handbook

| Record | Value |
|---|---|
| Handbook version | 1.0.0 |
| Website build phase | Development v0.5 |
| Last updated | 26 August 2026 |
| Active development branch | `develop` |
| Stable production branch | `main` |
| Development preview | <https://wernerj123-adm.github.io/collegians-harriers-website/> |
| Repository | <https://github.com/wernerj123-adm/collegians-harriers-website> |
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
| News | `news.html` | Club announcements, member stories and event updates |
| Contact | `contact.html` | Club location, contact routes and social channels |
| The Longest Day | `longest-day.html` | Dedicated 2026 event page |

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
| `assets/css/production-v04.css` | Accessibility and production-browser refinements |
| `assets/css/home-gallery-v05.css` | Landing-page photo slideshow styling |
| `assets/js/site.js` | Mobile navigation behaviour |
| `assets/js/home-gallery-v05.js` | Slideshow rotation, controls, swipe and reduced-motion behaviour |

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

1. Obtain permission to publish the photograph.
2. Prefer a clear landscape image at least 1200 pixels wide.
3. Resize and optimise the image where possible; aim for approximately 1 MB or less without visible quality loss.
4. Use a descriptive lowercase filename with hyphens, for example:

```text
collegians-hogsback-2026.jpg
```

5. Upload the file to `assets/img/`.
6. Open `index.html` and find the block marked `data-gallery-slide`.
7. Duplicate an existing `<figure>` slide.
8. Update the image filename, accurate alternative text, slide number and short caption.
9. Add one matching `data-gallery-dot` button and use the next number.
10. Check the image crop at desktop and phone sizes.
11. Test previous, next, dot and pause controls.
12. Commit the image and code together with a `content:` description.

Alternative text should briefly describe what is visible and useful, not repeat the caption word for word.

### 5.4 Publish race or time-trial results

Only publish a final, checked result file. Confirm names, categories, times, positions, dates and any corrections before upload.

1. Export the approved result as an accessible PDF. A web table may also be used when the data is short.
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

4. Open `results.html`.
5. Add the newest result at the top of the appropriate section so current results appear before the archive.
6. Include the date, event name, result type and file format in the link text.
7. If the result belongs to a hosted event, also add a link from that event page.
8. Open the file from the development preview and confirm that it downloads or displays correctly.
9. Check the PDF on a phone-sized screen.
10. Commit the HTML and result file together.

Suggested link wording:

```html
<a class="download" href="assets/results/2026/2026-08-25-tuesday-time-trial-results.pdf">
  <strong>Tuesday Time Trial — 25 August 2026</strong>
  <span>PDF results</span>
</a>
```

If a result is corrected later, replace the file, update the displayed revision date, and use a commit description that clearly says it is a corrected result.

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

- Populate the Results hub with approved current and historical files.
- Add a structured document library where required.
- Expand dedicated pages for major hosted events.
- Establish the staging-to-cPanel production deployment process.
- Consider a simple content-management workflow if nontechnical administrators need to publish frequently.
- Consider reusable site includes or a static-site generator if repeated navigation and footer maintenance becomes burdensome.

These are planned items, not completed features.

---

## 11. Handbook change log

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
