# CropzCard Home Screen Refresh — Updated Task List

Reference implementation:

- `/run/media/dishaan/G/cropzcard-landing/index.html`
- `/run/media/dishaan/G/cropzcard-landing/styles.css`
- `/run/media/dishaan/G/cropzcard-landing/cropzcard-poster.png`

Target application:

- `frontend/lib/main.dart`
- `frontend/lib/pages/help_page.dart`
- `frontend/lib/pages/privacy_policy_page.dart`
- `frontend/test/widget_test.dart`

## Implementation progress — 2026-07-23

- [x] Rebuilt Home with the reference header, hero, supplied poster, feature grid, three-step section, CTA, and dark footer.
- [x] Applied the reference green/lime/cream colour system and responsive desktop/tablet/mobile breakpoints.
- [x] Wired real Features, How it works, and Contact scrolling.
- [x] Removed the About route, navigation, callbacks, and user-facing references.
- [x] Wired Help and Privacy Policy from the Home footer and compact menu.
- [x] Added Help and Privacy Policy to the desktop top bar with real route wiring.
- [x] Replaced the generated brand mark with the supplied HD CropzCard logo asset.
- [x] Converted Home, Help, Privacy Policy, shared-card labels, validation, and status messages to English.
- [x] Hardened Netlify deployment config: cache-safe Flutter SDK install path, static asset headers, and updated deployment notes.
- [x] Preserved card fetching, app deep links, copy actions, document links, and Help form submission.
- [x] Added subtle glossy overlays plus hover lift/shadow to Home widgets: poster frame, feature cards, step cards, and CTA panel.
- [x] Added English Home/navigation widget coverage; `flutter analyze` and `flutter test` pass.
- [x] Produced a successful release web build.
- [ ] Complete final browser screenshot comparison when an in-app preview browser is available.
- [ ] Publish through the repository's existing hosting workflow when deployment is requested.

## Definition of done

- The `/` route reproduces every visible section, widget, label, link, image, colour, spacing pattern, and responsive layout from the reference landing page.
- The site is English-only, including Home, Help, Privacy Policy, menus, validation, notifications, and error states.
- There is no About page, About navigation item, About route, or About copy.
- Help and Privacy Policy are reachable from the new Home page and link back to Home and to each other.
- Existing shared-card routes (`/{cardId}`), API requests, deep links, and support-form submission continue to work.
- Desktop, tablet, and mobile layouts pass automated checks and visual comparison against the reference.

## 1. Protect existing behaviour and establish the baseline

- [ ] Record screenshots of the reference at desktop (1440 px), tablet (900 px), and mobile (390 px) widths.
- [ ] Record matching screenshots of the current Flutter Home page for comparison.
- [ ] Add stable widget keys or semantic labels to Home sections and primary links so navigation and visual tests are reliable.
- [ ] Run the current `flutter analyze` and `flutter test` suites and record any pre-existing failures before changing behaviour.

## 2. Remove About completely

- [ ] Confirm there is no About value in `_PageMode` and no `/about` route handler.
- [ ] Remove every About label, link, callback, stale widget, and navigation branch that remains in the frontend.
- [ ] Remove the About reference in Privacy Policy copy (currently present in the Tamil navigation description).
- [ ] Add a route/navigation test confirming the Home UI exposes no About link.
- [ ] Decide and test the legacy `/about` result: treat it as an unknown card route or explicitly redirect it to `/`, without restoring an About page.

## 3. Rebuild the shared landing-page foundation

- [ ] Define the reference colour tokens exactly:
  - `#194F32` primary green
  - `#2D7A48` secondary green
  - `#83C341` lime
  - `#13251A` ink
  - `#617066` muted text
  - `#F4F7F3` cream
  - `#FFFFFF` white
  - `#DCE6DD` border
- [ ] Match the reference typography stack, weights, line heights, letter spacing, and responsive headline sizes.
- [ ] Match the 1140 px maximum content width and 40 px/28 px responsive page gutters.
- [ ] Match the reference border radii, borders, shadows, gradients, hover/elevation states, and section spacing.
- [ ] Prevent the animated preview-page background from visually altering the Home, Help, and Privacy landing theme.
- [ ] Extract reusable brand, eyebrow, button, section-heading, footer-link, and responsive-container widgets where this improves exact consistency.

## 4. Match the Home header exactly

- [ ] Reproduce the sticky 74 px desktop / 66 px mobile white translucent header with blur and bottom border.
- [ ] Match the CropzCard brand mark: 37 px rounded-square lime-to-green gradient with the white `C`.
- [ ] Match the `Cropz` bold + `Card` regular wordmark sizing and spacing.
- [ ] Wire `Features`, `How it works`, and `Contact` to real in-page scrolling targets.
- [ ] Replace the current print/no-op section scrolling and `/#...` no-op navigation with working scroll behaviour.
- [ ] Match the `Get the app` button and open the Google Play listing in a new/external destination.
- [ ] Match reference responsive behaviour: hide the three section links below 900 px and hide the header CTA below 600 px.
- [ ] Keep Help and Privacy accessible on compact screens without changing the reference desktop header composition (use the compact menu and footer links).

## 5. Match the hero exactly

- [ ] Reproduce the reference radial/vertical hero background and 720 px desktop minimum height.
- [ ] Match the two-column desktop grid, alignment, gap, and single-column tablet/mobile ordering.
- [ ] Match the exact English eyebrow, headline, lead paragraph, CTA labels, and trust indicators from `index.html`.
- [ ] Use the reference Google Play icon artwork rather than the current generic play-circle icon.
- [ ] Make `Download on Google Play` open the Play Store directly; do not run the native-app deep-link fallback from this download CTA.
- [ ] Make `Explore features` smoothly scroll to the Features section.
- [ ] Copy `cropzcard-poster.png` into a tracked Flutter asset directory and register it in `pubspec.yaml`.
- [ ] Replace the generated phone/logo placeholder with the actual 1529 × 2048 poster.
- [ ] Match the poster frame: maximum width, white border, 30 px radius, shadow, green glow, desktop rotation, and flat mobile treatment.
- [ ] Match desktop/tablet centred alignment and the reference left-aligned mobile hero.

## 6. Match the Features section exactly

- [ ] Use the exact eyebrow, heading, paragraph, six feature titles, six descriptions, and six icon glyphs from the reference.
- [ ] Match the three-column desktop, two-column tablet, and one-column mobile grid.
- [ ] Match 20 px gaps, 28 px card padding, 20 px radii, border colour, icon tiles, and hover lift/shadow.
- [ ] Verify long copy wraps and all cards retain consistent visual rhythm at each breakpoint.

## 7. Match the How it works section exactly

- [ ] Reproduce the cream full-width section background.
- [ ] Use the exact English eyebrow, heading, section text, three step titles, and three descriptions.
- [ ] Match the two-column desktop layout and stacked tablet/mobile layout.
- [ ] Match the white step cards, numbered 44 px green circles, borders, spacing, radii, and typography.

## 8. Match the CTA section exactly

- [ ] Use the exact eyebrow, heading, and `Get CropzCard` label.
- [ ] Match the dark-green diagonal gradient, 28 px radius, shadow, padding, and content width.
- [ ] Match the desktop horizontal layout and stacked tablet/mobile layout.
- [ ] Wire the CTA button directly to the Google Play listing.

## 9. Match the footer and wire Help/Privacy

- [ ] Reproduce the dark `#0F2418` footer instead of the current light footer.
- [ ] Match the three-column desktop layout and responsive two-/one-column layouts.
- [ ] Match the reference brand, description, contact email, Google Play link, divider, muted text, hover colours, and spacing.
- [ ] Add `Help` and `Privacy Policy` under the footer Links group.
- [ ] Wire `Help` to `/help` and `Privacy Policy` to `/privacy`.
- [ ] Preserve browser back/forward navigation and direct loading for both routes.
- [ ] Generate the copyright year dynamically instead of keeping `2024`.
- [ ] Keep `cropzdigitalservices@gmail.com` as a working email link.

## 10. Convert Help to English and apply the landing theme

- [ ] Translate every Help-page title, paragraph, issue type, field label, hint, validation message, button, loading state, success message, failure message, email subject, and email body to English.
- [ ] Keep the existing `/api/error-requests` payload contract and submission behaviour intact.
- [ ] Keep Gmail/mail-app fallback behaviour intact.
- [ ] Restyle the page using the same landing colour tokens, typography, container width, cards, buttons, borders, and responsive spacing.
- [ ] Provide clearly visible links back to Home and to Privacy Policy.
- [ ] Confirm the support address is intentional: Help currently uses `cropzsupport@gmail.com`, while the landing footer uses `cropzdigitalservices@gmail.com`.

## 11. Convert Privacy Policy to English and apply the landing theme

- [ ] Translate every policy heading, paragraph, bullet, note, link, and CTA to English.
- [ ] Remove the existing About-page statement from the policy.
- [ ] Preserve the current policy meaning, including public card data, sharing, third-party services, retention/control, and contact requests.
- [ ] Restyle the page using the shared landing colour tokens, typography, cards, borders, buttons, and responsive spacing.
- [ ] Provide clearly visible links back to Home and to Help.
- [ ] Retain the disclaimer that the page is a privacy notice and not legal advice.

## 12. Preserve card-preview functionality

- [ ] Confirm all non-reserved first-path routes still render a shared card preview.
- [ ] Confirm `/help` and `/privacy` remain reserved routes and never trigger a card API request.
- [ ] Confirm card fetching still uses same-origin `/api/cards/{cardId}` unless `API_BASE` is explicitly provided.
- [ ] Confirm `Open in App`, phone copy, documents, bank accounts, addresses, and query-string filters still work.
- [ ] Translate any user-visible Tamil strings in shared-card loading, error, copy, and app-fallback states so the entire web experience is English.

## 13. Tests and verification

- [ ] Update `widget_test.dart` to assert English Home, Help, and Privacy labels instead of the old Tamil text.
- [ ] Test Home-to-Help, Home-to-Privacy, Help-to-Privacy, Privacy-to-Help, and return-to-Home navigation.
- [ ] Test Features, How it works, and Contact links scroll to the correct section.
- [ ] Test every Google Play CTA uses the exact production URL.
- [ ] Test the Help form validation, API success/failure handling, and email fallback.
- [ ] Test unknown/card routes remain separate from the three reserved routes.
- [ ] Add responsive widget tests at desktop, tablet, and mobile viewport widths.
- [ ] Run `dart format` on changed Dart files.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Build the production web bundle with the repository build script.
- [ ] Compare final screenshots side by side with the reference at 1440 px, 900 px, and 390 px; fix all visible differences before completion.

## Acceptance checklist

- [ ] Home contains the exact reference sequence: Header → Hero → Features → How it works → CTA → Footer.
- [ ] The poster is the supplied reference image, not a placeholder.
- [ ] All reference Home copy is exact and in English.
- [ ] Theme colours match the supplied hex values.
- [ ] All reference buttons, cards, icons, links, and responsive states are present.
- [ ] About is absent everywhere.
- [ ] Help and Privacy are reachable from Home and mutually connected.
- [ ] No Tamil user-facing text remains anywhere in the web frontend.
- [ ] Existing card-preview and support workflows have no regressions.
- [ ] Analysis, tests, production build, and visual comparison all pass.
