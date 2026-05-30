# PaperFlow

A tool for researchers who **write papers**, **review** them, and manage the
whole process that turns a draft into a published research article.

Built with **Flutter** so a single codebase ships as a **web PWA**, an **iOS**
app and an **Android** app.

## The idea

A manuscript is treated as a set of plain files — markdown for the text,
referenced graphics in an `assets/` folder, a JSON bibliography — so the whole
lifecycle (writing → submission → review → revision) can eventually live in
**git as the "cloud"**: transparent, versioned and reproducible, without a
central platform.

## Lifecycle

```
draft → submitted → under review → revision requested → resubmitted → accepted / rejected
```

Three roles, switchable from the app bar (single-device prototype):

- **Author** — writes sections, manages figures and references, submits, and
  responds to reviews.
- **Editor** — starts review rounds and records the decision that closes each
  round.
- **Reviewer** — writes a review (comments to authors, confidential comments
  to the editor, recommendation, score) per round.

## Data model (git-friendly)

Each paper maps to an on-disk layout:

```
paper.json          # metadata: title, authors, status, version
content/*.md        # sections in markdown; figures via ![cap](assets/foo.png)
assets/*            # graphics referenced from the markdown
references.json      # bibliography; cited as [@citationKey]
reviews/round-N/    # reviews + editor decision per round
```

In the current prototype this serialises into `SharedPreferences` (works on
web, iOS and Android). The persistence boundary is the `PaperRepository`
interface in `lib/data/` — the git-backed sync layer will implement that same
interface.

## Project layout

```
lib/
  models/      # Paper, Section, Reference, Asset, Review, ReviewRound, enums
  services/    # Workflow — the lifecycle state machine
  data/        # PaperRepository (persistence boundary)
  state/       # AppState (ChangeNotifier) + seed data
  ui/          # screens, tabs and shared widgets
```

## Running

Flutter 3.5+ is required.

```bash
flutter pub get

# Web PWA
flutter run -d chrome
flutter build web         # production build in build/web

# Mobile
flutter run -d <android-or-ios-device>
flutter build apk         # Android
flutter build ios         # iOS (on macOS)
```

## Roadmap

- [ ] Git-backed repository: serialise papers to the on-disk layout and
      sync/commit/push (the "git as cloud" backend).
- [ ] Real multi-user identity and authentication for reviewers/editors.
- [ ] Inline comment threads anchored to the manuscript text.
- [ ] Export to PDF / LaTeX.
- [ ] Citation rendering and reference import (BibTeX, DOI lookup).
