# Design (placeholder look and feel)
The creative team will replace the visuals. Keep ALL styling in `DesignSystem/` so that swap is a one-folder change.

## Tokens
| Token | Value (placeholder) |
|---|---|
| Colours | `brand`, `background`, `surface`, `textPrimary`, `textSecondary`, `error`, via Asset Catalog (light + dark) |
| Spacing | 4, 8, 12, 16, 24, 32; 44pt minimum tap target; 48pt search-row minimum height |
| Radius | 8, 12, 16 |
| Opacity | Disabled controls: 0.5 |
| Type | System text styles only (`.title`, `.headline`, `.body`, `.caption`) for Dynamic Type |

## Components
`ProductTile`, `ProductGrid`, `SectionHeader`, `LoadStateView` (loading/error/empty wrapper), `PrimaryButton`, `FormField`, `RatingView`, `RemoteImage` (AsyncImage + placeholder), `SearchBar` (compact rounded field with clear and icon-only submit buttons).

## Screens
| Screen | Content | States |
|---|---|---|
| Home | Compact search row with leading magnifier and trailing icon button, category chips, 5 featured tiles | loading, error+retry |
| Category | "Top rated" section (3), "More in <category>" section | loading, empty, error |
| Search results | Compact search row + results | idle, loading, empty ("No results for ..."), error |
| Product detail | Image, title, price, rating, description, **Enquire** button | loading, error |
| Enquiry form (sheet) | name, email, phone (optional), message, Submit | validating, submitting, success ("Thank you"), error |

## UX rules
- Search runs on button tap (and keyboard Search key), per the acceptance criteria.
- Inline validation messages; Submit disabled while submitting.
- Error text: plain language, e.g. "Cannot reach the server. Is the backend running?"
