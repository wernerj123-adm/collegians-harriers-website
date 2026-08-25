# Collegians Harriers Website Redesign

## Principle

This is a clean-sheet redesign. The legacy website is a content/reference source only. We do not reproduce its layout, styling or page structure by default.

## Brand direction

- Collegians red, black, white and restrained warm-neutral backgrounds
- Strong sporting typography and generous whitespace
- Approved Collegians crest used without cropping, distortion or decorative alteration
- Mobile-first responsive navigation
- Real club photography should be used selectively and only when image quality supports the design

## v0.2 design decision

The original V1 photographic hero was rejected. V0.2 replaces it with a graphic/editorial hero that does not depend on a weak legacy photograph. This creates a stronger, more timeless club identity and leaves room for high-quality current photography lower on the site or in future hero variants.

## Information architecture

- Home
- About
- Membership
- Running
- Events
- Results
- News
- Contact
- Dedicated event pages, beginning with The Longest Day

## Git workflow

- `main`: stable/approved baseline
- `develop`: active integration branch
- `feature/*`: focused changes where useful

## Deployment target

cPanel hosting for collegiansharriers.co.za. Production deployment will only happen after review on a staging location.

## Next work

1. Add approved high-resolution transparent crest and favicon assets.
2. Populate remaining page templates in GitHub.
3. Build staging deployment workflow.
4. Refine Home content after visual review.
5. Expand event, results and document-library components.
