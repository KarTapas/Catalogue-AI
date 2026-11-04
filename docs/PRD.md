# PRD: Product Catalogue (iOS PoC)

## Goal
A proof of concept the entrepreneur can interact with to firm up the vision. It must be a foundation that grows, not a throwaway.
Expected to change later: product data source, look and feel, email provider.

## Users
- **Customer**: browses, searches, and enquires about products.
- **Sales team**: receives enquiry emails in a shared inbox.

## User stories and acceptance criteria

### US1 Home: featured products
```gherkin
GIVEN I have chosen 5 products to be "top rated"
WHEN I am viewing the home page
THEN I see those 5 featured products
```
### US2 Category page
```gherkin
GIVEN my products are organised into categories
WHEN I tap a category
THEN I see top rated products for that category
AND I see additional products in that category
```
### US3 Search
```gherkin
GIVEN I have entered a search term
WHEN I tap the search button
THEN I only see products whose text matches the term
```
### US4 Product details
```gherkin
GIVEN I am browsing products
WHEN I tap a product tile
THEN I see the product details page
```
### US5 Enquiry
```gherkin
GIVEN I am viewing a product and tap Enquire
AND I complete the form with my contact details
WHEN I submit
THEN the sales inbox receives an email
AND I see a "Thank you" message
```

## Assumptions (gaps in the brief; mirrored in DECISIONS.md)
| # | Gap | Assumption |
|---|---|---|
| A1 | Who "chooses" the 5 featured? | Backend config `FEATURED_IDS`; fallback to top 5 by rating |
| A2 | "Top rated" in a category | Top 3 by `rating.rate` (ties: higher `rating.count`), then the rest |
| A3 | Search scope | Server-side, case-insensitive, title + description + category, trimmed, min 2 chars |
| A4 | Empty/short search | Server returns 400 `VALIDATION_ERROR`; app disables the button |
| A5 | Enquiry fields | name, email, phone (optional), message, productId |
| A6 | Enquiry storage | None. Email only. DB is a next step |
| A7 | Platform | iPhone, iOS 17+, portrait, Simulator only |

## Non-goals
Auth, cart, payments, admin UI, offline cache, pagination, iPad layout, localisation, analytics.

## Constraints (from the brief)
- App talks ONLY to our backend. Never to Fake Store API.
- No secrets in the repo. No paid services. AWS-compatible infra only.
- Reviewer runs it locally in under 10 minutes.
