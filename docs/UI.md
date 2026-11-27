# CivicConnect — Complete Mobile UI Design

> Flutter Material 3 · Phase 1 · All Roles · All Screens

---

## Table of Contents

1. [User Flow](#1-user-flow)
2. [Navigation Flow](#2-navigation-flow)
3. [Screen List](#3-screen-list)
4. [Material 3 Design System](#4-material-3-design-system)
   - 4.1 Typography
   - 4.2 Color System
   - 4.3 Elevation & Shape
   - 4.4 Icons
   - 4.5 Spacing & Grid
5. [Components](#5-components)
6. [Wireframes](#6-wireframes)
   - Splash
   - Onboarding
   - Login
   - Register
   - Forgot Password
   - OTP Verification
   - Home (Citizen)
   - Map View
   - Report Issue (Multi-Step)
   - Issue Details
   - Notifications
   - Profile
   - Settings
   - Officer Dashboard (Field Worker + Supervisor)
   - Admin Dashboard

---

## 1. User Flow

### 1.1 Citizen User Flow

```
APP LAUNCH
    │
    ▼
[Splash Screen]  ──► Check auth token
    │
    ├── Token valid ──────────────────────────────► [Home Screen]
    │
    └── No token / expired
            │
            ▼
    [Onboarding] (first launch only)
            │
            ▼
    [Login Screen]
            │
            ├── Have account ──► Enter credentials ──► [Home Screen]
            │
            ├── New user ──────► [Register Screen]
            │                         │
            │                    Enter details
            │                         │
            │                    [OTP Verification]
            │                         │
            │                    Verified ──────────► [Home Screen]
            │
            └── Forgot password ► [Forgot Password]
                                       │
                                  Enter email/phone
                                       │
                                  [OTP Verification]
                                       │
                                  Enter new password
                                       │
                                  ─────────────────► [Login Screen]

HOME SCREEN (Citizen)
    │
    ├── [Report Issue Button / FAB]
    │       │
    │       ├── Step 1: Select Category
    │       ├── Step 2: Add Location (GPS auto / Map pin)
    │       ├── Step 3: Add Photos (up to 5)
    │       ├── Step 4: Add Description
    │       └── Step 5: Review & Submit
    │               │
    │               ├── Nearby duplicates found? ──► [Nearby Issues Modal]
    │               │                                      │
    │               │                               Upvote existing
    │               │                               or continue submit
    │               │
    │               └── Submit ──────────────────► [Success Screen]
    │                                                     │
    │                                              ──────►[Issue Details]
    │
    ├── [My Issues Tab] ──────────────────────────► [Issue List]
    │                                                     │
    │                                              Tap issue ──► [Issue Details]
    │                                                                   │
    │                                              If Resolved ────► [Verify Resolution]
    │                                                                   │
    │                                                          Confirm ─► Close
    │                                                          Reject ──► Reopen + Reason
    │
    ├── [Map Tab] ──────────────────────────────► [Map Screen]
    │                                                  │
    │                                          Tap marker ──► [Issue Preview Card]
    │                                                               │
    │                                                       View Details ──► [Issue Details]
    │
    ├── [Notifications Tab] ──────────────────► [Notifications Screen]
    │                                                  │
    │                                          Tap notification ──► [Issue Details]
    │
    └── [Profile Tab] ───────────────────────► [Profile Screen]
                                                    │
                                            ├── Edit Profile
                                            ├── [Settings]
                                            └── Logout
```

---

### 1.2 Field Worker User Flow

```
LOGIN ──► [Officer Dashboard — Field Worker View]
    │
    ├── [My Tasks Tab]
    │       │
    │       ├── View task list (assigned issues)
    │       ├── Tap task ──────────► [Task Detail Screen]
    │       │                              │
    │       │                      ├── View location + description
    │       │                      ├── Navigate (open in Maps)
    │       │                      ├── Update status: Accept → In Progress
    │       │                      ├── Upload resolution photos
    │       │                      ├── Mark as Completed
    │       │                      └── Request Escalation
    │       │
    │       └── Filter: All / Pending / In Progress / Completed
    │
    └── [Profile Tab] ──► [Profile] ──► [Settings]
```

---

### 1.3 Department Supervisor User Flow

```
LOGIN ──► [Officer Dashboard — Supervisor View]
    │
    ├── [Queue Tab] — All dept issues
    │       │
    │       ├── Filter by: status / priority / ward / SLA
    │       ├── Tap issue ──► [Issue Detail — Supervisor View]
    │       │                        │
    │       │                ├── Assign to field worker
    │       │                ├── Change priority
    │       │                ├── Add internal note
    │       │                ├── Escalate / Reject (with reason)
    │       │                └── Merge duplicate
    │       │
    │       └── Bulk select ──► Bulk assign
    │
    ├── [Team Tab] — Field worker workload view
    │
    ├── [Analytics Tab] — Dept metrics
    │
    └── [Profile / Settings]
```

---

### 1.4 Admin User Flow

```
LOGIN ──► [Admin Dashboard]
    │
    ├── [Overview Tab] — City-wide stats + alerts
    ├── [Issues Tab] — Cross-department issue list
    ├── [Analytics Tab] — Charts, heatmap, trends
    ├── [Config Tab]
    │       │
    │       ├── Departments
    │       ├── Categories & routing rules
    │       ├── SLA policies
    │       └── Escalation rules
    ├── [Users Tab] — Manage authority accounts
    └── [Settings / Profile]
```

---

## 2. Navigation Flow

### 2.1 Route Map (go_router)

```
/splash
/onboarding
/auth
  /auth/login
  /auth/register
  /auth/forgot-password
  /auth/otp?context=[register|reset]
/citizen                          ← ShellRoute (Bottom Nav)
  /citizen/home
  /citizen/map
  /citizen/report
    /citizen/report/category
    /citizen/report/location
    /citizen/report/photos
    /citizen/report/description
    /citizen/report/review
    /citizen/report/success
  /citizen/issues
    /citizen/issues/:id
    /citizen/issues/:id/verify
  /citizen/notifications
  /citizen/profile
    /citizen/profile/edit
    /citizen/settings
/officer                          ← ShellRoute (Bottom Nav)
  /officer/dashboard
  /officer/tasks
    /officer/tasks/:id
  /officer/notifications
  /officer/profile
    /officer/settings
/admin                            ← ShellRoute (Bottom Nav)
  /admin/dashboard
  /admin/issues
    /admin/issues/:id
  /admin/analytics
  /admin/config
    /admin/config/departments
    /admin/config/categories
    /admin/config/sla
    /admin/config/users
  /admin/profile
    /admin/settings
```

---

### 2.2 Navigation Patterns by Role

| Role | Shell | Primary Nav | Secondary Nav |
|---|---|---|---|
| Citizen | BottomNavigationBar (4 items) | Home · Map · Notifications · Profile | FAB → Report flow |
| Field Worker | BottomNavigationBar (3 items) | Tasks · Notifications · Profile | Task detail via list tap |
| Supervisor | BottomNavigationBar (4 items) | Queue · Team · Analytics · Profile | Issue detail via list tap |
| Admin | BottomNavigationBar (5 items) | Overview · Issues · Analytics · Config · Profile | Sub-sections via list tap |

---

### 2.3 Auth Guard Logic

```
Route requested
      │
      ▼
Is token present and valid?
      │
      ├── No  ──────────────────────► Redirect to /auth/login
      │
      └── Yes
            │
            ▼
      Does route match user role?
            │
            ├── No  ─────────────────► Redirect to role's home route
            │
            └── Yes ─────────────────► Allow navigation
```

---

### 2.4 Deep Link Support

| Deep Link | Destination |
|---|---|
| `civicconnect://issue/:id` | Issue Details screen |
| `civicconnect://notification/:id` | Notification detail |
| `civicconnect://report` | Report Issue flow (Step 1) |
| `civicconnect://verify/:id` | Verify Resolution screen |

---

## 3. Screen List

### Citizen Screens (14)

| # | Screen | Route | Trigger |
|---|---|---|---|
| C-01 | Splash | `/splash` | App launch |
| C-02 | Onboarding | `/onboarding` | First launch only |
| C-03 | Login | `/auth/login` | Unauthenticated access |
| C-04 | Register | `/auth/register` | "Sign Up" tap |
| C-05 | Forgot Password | `/auth/forgot-password` | "Forgot?" tap |
| C-06 | OTP Verification | `/auth/otp` | Register or password reset |
| C-07 | Home | `/citizen/home` | Post-login (Citizen) |
| C-08 | Map View | `/citizen/map` | Bottom nav tap |
| C-09 | Report Issue — Category | `/citizen/report/category` | FAB tap |
| C-10 | Report Issue — Location | `/citizen/report/location` | Category selected |
| C-11 | Report Issue — Photos | `/citizen/report/photos` | Location confirmed |
| C-12 | Report Issue — Description | `/citizen/report/description` | Photos done |
| C-13 | Report Issue — Review | `/citizen/report/review` | Description entered |
| C-14 | Report Success | `/citizen/report/success` | Submit tapped |
| C-15 | My Issues | `/citizen/issues` | Bottom nav / home shortcut |
| C-16 | Issue Details | `/citizen/issues/:id` | List item tap |
| C-17 | Verify Resolution | `/citizen/issues/:id/verify` | "Verify" notification tap |
| C-18 | Notifications | `/citizen/notifications` | Bottom nav |
| C-19 | Profile | `/citizen/profile` | Bottom nav |
| C-20 | Edit Profile | `/citizen/profile/edit` | Edit tap |
| C-21 | Settings | `/citizen/settings` | Profile → Settings |

### Officer / Field Worker Screens (7)

| # | Screen | Route | Notes |
|---|---|---|---|
| O-01 | Officer Dashboard | `/officer/dashboard` | Post-login (Field Worker) |
| O-02 | Task List | `/officer/tasks` | Default tab |
| O-03 | Task Detail | `/officer/tasks/:id` | Task item tap |
| O-04 | Supervisor Queue | `/officer/dashboard` | Post-login (Supervisor) — same shell, different content |
| O-05 | Issue Detail — Supervisor | `/officer/tasks/:id` | Issue item tap (supervisor view) |
| O-06 | Team Workload | `/officer/team` | Bottom nav |
| O-07 | Officer Notifications | `/officer/notifications` | Bottom nav |

### Admin Screens (8)

| # | Screen | Route | Notes |
|---|---|---|---|
| A-01 | Admin Dashboard | `/admin/dashboard` | Post-login (Admin) |
| A-02 | Issues Overview | `/admin/issues` | Bottom nav |
| A-03 | Analytics | `/admin/analytics` | Bottom nav |
| A-04 | Config — Departments | `/admin/config/departments` | Config tab |
| A-05 | Config — Categories | `/admin/config/categories` | Config tab |
| A-06 | Config — SLA | `/admin/config/sla` | Config tab |
| A-07 | User Management | `/admin/config/users` | Config tab |
| A-08 | Admin Settings | `/admin/settings` | Profile section |

**Total: 36 screens**

---

## 4. Material 3 Design System

### 4.1 Typography

CivicConnect uses **Google Fonts — Outfit** as the primary typeface. Outfit is a geometric sans-serif with excellent legibility at small sizes on mobile screens. Falls back to system sans-serif.

```
Material 3 Type Scale → Outfit Mapping

Role                  Weight    Size    Line Height    Usage
────────────────────────────────────────────────────────────────────
displayLarge          300       57sp    64sp           Hero numbers (stats)
displayMedium         300       45sp    52sp           —
displaySmall          400       36sp    44sp           Onboarding headings

headlineLarge         400       32sp    40sp           Screen titles
headlineMedium        400       28sp    36sp           Card headings
headlineSmall         400       24sp    32sp           Section headings

titleLarge            500       22sp    28sp           AppBar title
titleMedium           500       16sp    24sp           List item title
titleSmall            500       14sp    20sp           Chip labels

bodyLarge             400       16sp    24sp           Primary body text
bodyMedium            400       14sp    20sp           Secondary body text
bodySmall             400       12sp    16sp           Captions, metadata

labelLarge            500       14sp    20sp           Buttons, CTAs
labelMedium           500       12sp    16sp           Tags, badges
labelSmall            500       11sp    16sp           Overline text, status chips
```

**Accessibility note:** Minimum touch target 48×48dp. Minimum readable body text 14sp. All text meets WCAG AA contrast ratio 4.5:1 minimum.

---

### 4.2 Color System

CivicConnect uses a **civic blue + amber accent** palette. Blue signals trust, authority, and civic government. Amber signals urgency, alerts, and actionable items.

#### Seed Color
```
Primary seed: #1565C0   (deep civic blue)
```

#### Light Theme Tokens

```
Token                   Hex         Role
──────────────────────────────────────────────────────────────
primary                 #1565C0     Main brand blue — buttons, FAB, active states
onPrimary               #FFFFFF     Text/icons on primary
primaryContainer        #D6E4FF     Tinted backgrounds (chips, selected cards)
onPrimaryContainer      #001848     Text on primary container

secondary               #5B6B8A     Subdued blue-grey — secondary actions
onSecondary             #FFFFFF
secondaryContainer      #DFE6F5     Light secondary surface
onSecondaryContainer    #18223B

tertiary                #F59E0B     Amber — alerts, warnings, SLA indicators
onTertiary              #FFFFFF
tertiaryContainer       #FEF3C7     Light amber surface
onTertiaryContainer     #451A03

error                   #BA1A1A     Error states, destructive actions
onError                 #FFFFFF
errorContainer          #FFDAD6
onErrorContainer        #410002

surface                 #F8F9FE     App background
onSurface               #191C20     Primary text
surfaceVariant          #E1E5EE     Card backgrounds, input fills
onSurfaceVariant        #44474F     Secondary text, labels

outline                 #74777F     Borders, dividers
outlineVariant          #C4C6CF     Subtle dividers
inverseSurface          #2E3135     Dark surfaces (snackbars)
inverseOnSurface        #EEF0F8
inversePrimary          #A8C7FF

shadow                  #000000
scrim                   #000000
```

#### Dark Theme Tokens

```
Token                   Hex
──────────────────────────────────────────────
primary                 #A8C7FF
onPrimary               #002F6D
primaryContainer        #00429B
onPrimaryContainer      #D6E4FF

secondary               #BFC8DC
onSecondary             #293040
secondaryContainer      #3F4757
onSecondaryContainer    #DFE6F5

tertiary                #FFD77A
onTertiary              #3D2C00
tertiaryContainer       #583F00
onTertiaryContainer     #FEF3C7

error                   #FFB4AB
onError                 #690005
errorContainer          #93000A
onErrorContainer        #FFDAD6

surface                 #111318
onSurface               #E2E2E9
surfaceVariant          #44474F
onSurfaceVariant        #C4C6CF

outline                 #8E9099
outlineVariant          #44474F
```

#### Semantic Status Colors

```
Status          Light Bg        Light Text      Dark Bg         Dark Text
────────────────────────────────────────────────────────────────────────────
SUBMITTED       #E3F2FD         #0D47A1         #0D3B6E         #90CAF9
ASSIGNED        #EDE7F6         #4527A0         #3D1A78         #CE93D8
IN_PROGRESS     #FFF8E1         #E65100         #4E2700         #FFCC02
RESOLVED        #E8F5E9         #1B5E20         #0A3D12         #A5D6A7
OVERDUE         #FFEBEE         #B71C1C         #4A0000         #EF9A9A
CLOSED          #F5F5F5         #424242         #2C2C2C         #BDBDBD
```

#### Priority Colors

```
Priority        Color           Hex
────────────────────────────────────
LOW             Green           #2E7D32
MEDIUM          Amber           #F59E0B
HIGH            Orange          #E65100
CRITICAL        Red             #B71C1C
```

---

### 4.3 Elevation & Shape

```
Material 3 Elevation Levels → CivicConnect Usage

Level 0  (0dp  shadow)  — Page backgrounds
Level 1  (1dp  tint)    — Cards at rest, navigation drawer
Level 2  (3dp  tint)    — Filled cards (report cards), search bar
Level 3  (6dp  tint)    — FAB at rest, menus, dropdowns
Level 4  (8dp  tint)    — FAB pressed, navigation bars
Level 5  (12dp tint)    — Modals, dialogs, bottom sheets
```

```
Shape Scale (rounded corners)

extraSmall   4dp    — Chips, small tags, badges
small        8dp    — Input fields, small cards
medium       12dp   — Cards, list tiles
large        16dp   — Bottom sheets (top corners), side drawers
extraLarge   28dp   — FAB, dialogs
full         50%    — Circular avatars, icon buttons
```

---

### 4.4 Icons

Icon set: **Material Symbols — Rounded** (variable font, weight 400, grade 0, optical size 24).

```
Feature Area        Icon Name                   Symbol
────────────────────────────────────────────────────────────
Navigation
  Home              home_rounded
  Map               map_rounded
  Notifications     notifications_rounded
  Profile           person_rounded
  Dashboard         dashboard_rounded
  Settings          settings_rounded
  Analytics         bar_chart_rounded
  Config            tune_rounded

Issue Actions
  Report Issue      add_circle_rounded
  Submit            send_rounded
  Camera/Photo      photo_camera_rounded
  Location Pin      location_on_rounded
  GPS               my_location_rounded
  Upvote            thumb_up_rounded
  Verify            check_circle_rounded
  Reopen            restart_alt_rounded
  Escalate          arrow_upward_rounded
  Assign            person_add_rounded
  Close/Resolved    task_alt_rounded
  Merge             merge_rounded
  Duplicate         content_copy_rounded

Status Icons
  Submitted         upload_rounded
  Assigned          assignment_ind_rounded
  In Progress       pending_rounded
  Resolved          verified_rounded
  Overdue           schedule_rounded (amber)
  Closed            lock_rounded

Categories
  Roads             directions_car_rounded
  Water             water_drop_rounded
  Electricity       bolt_rounded
  Sanitation        delete_rounded
  Streetlight       lightbulb_rounded
  Parks/Trees       park_rounded
  Drainage          water_rounded
  Other             category_rounded

Auth
  Email             email_rounded
  Password          lock_rounded
  Phone/OTP         smartphone_rounded
  Eye (show/hide)   visibility_rounded / visibility_off_rounded
  Google            (custom SVG — Google "G" logo)

Misc
  Filter            filter_list_rounded
  Search            search_rounded
  Sort              sort_rounded
  More options      more_vert_rounded
  Back              arrow_back_rounded
  Close/X           close_rounded
  Edit              edit_rounded
  Delete            delete_rounded
  Share             share_rounded
  Download/Export   download_rounded
  Refresh           refresh_rounded
  Info              info_rounded
  Warning           warning_rounded
  Error             error_rounded
  Success           check_circle_rounded
  Attachment        attach_file_rounded
  Tracking ID       tag_rounded
  Time/SLA          timer_rounded
  Department        business_rounded
  Municipality      location_city_rounded
```

---

### 4.5 Spacing & Grid

```
Base unit: 8dp

Spacing scale:
  xs      4dp    — Inline spacing (icon-to-text gap)
  sm      8dp    — Tight spacing (within components)
  md      16dp   — Standard padding (card content, form fields)
  lg      24dp   — Section spacing
  xl      32dp   — Screen-level vertical rhythm
  xxl     48dp   — Hero section spacing

Screen margins:
  Phone portrait  16dp horizontal margin
  Phone landscape 24dp horizontal margin

Grid:
  Columns         4 (phone) / 8 (tablet)
  Gutter          16dp
  Margin          16dp

Safe areas:
  Top             StatusBar height (system)
  Bottom          BottomNav height + system nav bar
```

---

## 5. Components

### 5.1 Buttons

```
Primary Button (FilledButton)
  Height:         48dp
  Corner radius:  extraLarge (28dp — full pill)
  Background:     primary (#1565C0)
  Label:          labelLarge, onPrimary
  State layers:   hover 8%, pressed 12%, disabled 38% opacity
  Usage:          Primary CTA — Submit, Login, Confirm

  ┌────────────────────────────────┐
  │          SUBMIT REPORT         │
  └────────────────────────────────┘

Secondary Button (OutlinedButton)
  Height:         48dp
  Border:         1dp, outline color
  Corner radius:  extraLarge
  Label:          labelLarge, primary
  Usage:          Secondary actions — Cancel, Skip, View Details

  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  │            CANCEL              │
  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

Text Button (TextButton)
  Height:         40dp
  Usage:          Tertiary actions — Forgot Password, Skip

Danger Button (FilledButton — error color)
  Background:     error (#BA1A1A)
  Usage:          Destructive — Delete account, Reject resolution

Icon Button (FilledIconButton / IconButton)
  Size:           40×40dp
  Usage:          Toolbar actions, filter, share

FAB (FloatingActionButton — large)
  Size:           96×56dp (extended) / 56×56dp (standard)
  Corner:         extraLarge (28dp)
  Background:     primaryContainer
  Icon:           add_circle_rounded, primary
  Label:          "Report Issue" (extended FAB on home)
```

---

### 5.2 Input Fields

```
Text Input (OutlinedTextField / FilledTextField)
  Style:          Filled (surfaceVariant background)
  Height:         56dp
  Corner radius:  small (8dp top) + 0dp bottom (filled style)
  Label:          Floating label, bodyMedium
  Helper text:    bodySmall, onSurfaceVariant
  Error text:     bodySmall, error color
  Leading icon:   24dp, optional
  Trailing icon:  24dp — clear, show/hide password

  ┌──────────────────────────────────┐
  │ 📧  Email address                │
  │                                  │
  └──────────────────────────────────┘
    Helper: We'll send OTP to this address

Phone Input
  Leading:        Country flag + dial code picker
  Input:          10-digit number, numeric keyboard

OTP Input (6 boxes)
  Individual boxes: 48×56dp each
  Spacing:        8dp between boxes
  Auto-advance:   On digit entry
  Style:          Outlined, medium corner radius

  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐
  │ 3  │ │ 7  │ │ _  │ │    │ │    │ │    │
  └────┘ └────┘ └────┘ └────┘ └────┘ └────┘

Search Field
  Style:          Filled, surfaceVariant
  Leading:        search icon
  Trailing:       clear icon (when text present)
  Corner:         full (pill shape — Material 3 search bar style)

Multiline Text Area
  Min lines:      4
  Max lines:      8
  Character count shown at bottom right
```

---

### 5.3 Cards

```
Issue Card (citizen list)
  Corner radius:  medium (12dp)
  Elevation:      Level 1
  Padding:        16dp
  Width:          Full width − 32dp margin

  ┌──────────────────────────────────────────────┐
  │ [Category Icon]  ROADS            [Status]   │
  │ Pothole on MG Road near Signal No.3          │
  │ ─────────────────────────────────────────── │
  │ 📍 MG Road, Ward 4    🕐 2 days ago          │
  │                              👍 24 upvotes   │
  └──────────────────────────────────────────────┘

  Status chip: colored badge (see status colors)
  Category icon: 24dp, colored per category
  Tap: navigate to Issue Details

Task Card (field worker)
  Same structure, shows:
  - Priority badge (Low/Med/High/Critical) instead of upvotes
  - Assigned time instead of submission time
  - [Navigate] icon button on right

Summary Card (dashboard stats)
  Corner radius:  medium (12dp)
  Elevation:      Level 2
  Padding:        20dp
  Layout:         Icon + large number + label

  ┌───────────────────────┐
  │  🔵                   │
  │  142                  │
  │  Open Issues          │
  └───────────────────────┘

Notification Card
  Leading:        Avatar or category icon (40dp circle)
  Title:          titleSmall
  Body:           bodySmall, 2 lines max
  Trailing:       timestamp + unread dot
  Divider:        none (use spacing)
```

---

### 5.4 Status & Priority Chips

```
Status Chip (FilterChip / custom)
  Height:         32dp
  Corner radius:  full (pill)
  Padding:        8dp horizontal
  Font:           labelMedium

  ● SUBMITTED      — blue bg/text
  ● ASSIGNED       — purple bg/text
  ● IN PROGRESS    — amber bg/text
  ● RESOLVED       — green bg/text
  ● OVERDUE        — red bg/text
  ● CLOSED         — grey bg/text

Priority Badge
  Size:           20×20dp dot + labelSmall text
  CRITICAL        — red
  HIGH            — orange
  MEDIUM          — amber
  LOW             — green
```

---

### 5.5 Navigation Components

```
Bottom Navigation Bar (NavigationBar — M3)
  Height:         80dp (including system nav indicator)
  Items:          3–5 (label always visible)
  Indicator:      Pill highlight on selected item
  Font:           labelMedium

  Citizen:
  ┌──────────────────────────────────────────────┐
  │   🏠 Home   🗺 Map   🔔 Alerts   👤 Profile  │
  └──────────────────────────────────────────────┘

  Field Worker:
  ┌─────────────────────────────────────────────┐
  │        ✅ Tasks    🔔 Alerts    👤 Profile   │
  └─────────────────────────────────────────────┘

  Supervisor:
  ┌───────────────────────────────────────────────────────┐
  │  📋 Queue   👥 Team   📊 Analytics   👤 Profile       │
  └───────────────────────────────────────────────────────┘

  Admin:
  ┌─────────────────────────────────────────────────────────────┐
  │  📊 Overview  📋 Issues  📈 Analytics  ⚙ Config  👤 Profile │
  └─────────────────────────────────────────────────────────────┘

App Bar (TopAppBar — M3)
  Height:         64dp
  Style:          CenterAligned (screens) / Small (detail screens)
  Scroll behavior: Pinned on main screens / CollapsingToolbar on detail

Step Indicator (Report flow)
  Style:          Horizontal segmented progress dots
  Active:         primary filled circle
  Completed:      primary filled circle + check
  Inactive:       outline circle

  ●─────●─────○─────○─────○
  1     2     3     4     5
```

---

### 5.6 List Items

```
Standard List Tile (ListTile — M3)
  Height:         72dp (with subtitle) / 56dp (title only)
  Leading:        40dp circle avatar or 24dp icon
  Title:          titleMedium
  Subtitle:       bodySmall, onSurfaceVariant
  Trailing:       icon / text / chip

Issue List Tile (Officer queue)
  Height:         88dp
  Leading:        category icon in colored circle
  Title:          issue title (1 line, ellipsis)
  Subtitle:       location + time (1 line)
  Trailing:       priority dot + SLA countdown chip

  ┌───────────────────────────────────────────────────┐
  │  [💧]   Water leakage near Bus Stop 4             │
  │         📍 Shivaji Nagar  ·  3 hrs ago   [2h SLA]│
  └───────────────────────────────────────────────────┘
```

---

### 5.7 Dialogs & Sheets

```
Confirmation Dialog
  Width:          Constrained (280–560dp)
  Corner:         extraLarge (28dp)
  Title:          headlineSmall
  Content:        bodyMedium
  Actions:        text buttons (cancel left, confirm right)

Bottom Sheet (Modal)
  Corner:         large top corners (16dp)
  Handle:         4×32dp pill at top center
  Content:        scrollable
  Uses: category picker, location options, filter options,
        assign field worker, internal notes, reject reason

Snackbar
  Position:       bottom, above nav bar
  Duration:       4 seconds
  Style:          inverseSurface bg, inverseOnSurface text
  Action:         optional, labelLarge, inversePrimary

  ┌────────────────────────────────────────────────┐
  │  ✓  Report submitted · CC-2024-00142    VIEW  │
  └────────────────────────────────────────────────┘

Tooltip
  Style:          M3 rich tooltip for icon buttons
```

---

### 5.8 Map Components

```
Map Pin (issue marker)
  Size:           40×48dp (pin shape)
  Color:          per status (blue=submitted, amber=in-progress, green=resolved)
  Count badge:    for clustered markers

Issue Preview Card (map bottom sheet)
  Drag handle at top
  Shows: category icon, title, status, distance from current location
  CTA: "View Details" button

My Location Button
  Style:          FAB small, elevation 3
  Position:       bottom-right of map, above preview card
```

---

### 5.9 Empty States & Loading

```
Empty State
  Illustration:   SVG spot illustration (context-specific)
  Title:          titleLarge, centered
  Body:           bodyMedium, centered, onSurfaceVariant
  Action:         optional FilledButton

  My Issues — Empty:
  [Illustration: person with magnifying glass]
  "No issues reported yet"
  "Tap the + button to report a civic issue"
  [Report an Issue]

Loading States
  Full screen:    CircularProgressIndicator centered on surface
  List loading:   Shimmer skeleton tiles (3–5 items)
  Card loading:   Shimmer skeleton card shape
  Button loading: CircularProgressIndicator inside button, disabled state

Error State
  Icon:           error_rounded (48dp, error color)
  Title:          "Something went wrong"
  Body:           specific error message
  Action:         [Try Again] button
```

---

## 6. Wireframes

> All wireframes use ASCII art at ~390dp width (standard phone).
> Dimensions shown in dp. Icons shown as [icon_name].

---

### C-01 — Splash Screen

```
┌──────────────────────────────┐  390×844dp
│                              │
│                              │
│                              │
│                              │
│                              │
│         ●●●●●●●●●            │  ← App icon (96×96dp)
│        ●         ●           │     rounded square
│       ●  [bridge] ●          │     primary bg
│        ●         ●           │
│         ●●●●●●●●●            │
│                              │
│       CivicConnect           │  ← displaySmall, onPrimary
│                              │
│   Connecting Citizens with   │  ← bodyMedium, onPrimary 70%
│        Government            │
│                              │
│                              │
│                              │
│                              │
│         ════════             │  ← LinearProgressIndicator
│                              │     primaryContainer, 4dp height
│                              │
│                              │
│   Powered by Smart Cities    │  ← labelSmall, onPrimary 50%
└──────────────────────────────┘

Background: primary (#1565C0) full bleed
Animation: icon scale 0→1 (300ms), then text fade in (200ms)
Min display: 1.5 seconds, then auto-navigate
```

---

### C-02 — Onboarding (3 Pages)

```
Page 1 of 3 — "Report Any Issue"

┌──────────────────────────────┐
│                         ✕    │  ← Skip button (TextButton, top-right)
│                              │
│                              │
│   ┌──────────────────────┐   │
│   │                      │   │  ← Illustration area (240×200dp)
│   │   [SVG: citizen      │   │    SVG spot illustration
│   │    photographing     │   │
│   │    pothole]          │   │
│   └──────────────────────┘   │
│                              │
│  Report Any Civic Issue      │  ← headlineMedium, onSurface
│                              │
│  From potholes to broken     │  ← bodyLarge, onSurfaceVariant
│  streetlights — report in    │    centered, 2-line max
│  under 60 seconds.           │
│                              │
│                              │
│         ●  ○  ○              │  ← Page indicator dots (8dp)
│                              │     active: primary, inactive: outline
│                              │
│  ┌────────────────────────┐  │  ← FilledButton
│  │         NEXT           │  │    full width − 32dp
│  └────────────────────────┘  │
│                              │
└──────────────────────────────┘

Page 2 of 3 — "Track in Real Time"
  Illustration: phone showing status timeline
  Headline: "Track Your Reports Live"
  Body: "Get notified at every step. Know exactly when your issue is assigned and resolved."
  Dots: ○ ● ○

Page 3 of 3 — "Make Your City Better"
  Illustration: city with resolved issues checkmarks
  Headline: "Your City, Your Voice"
  Body: "Every report makes a difference. Join thousands of citizens improving their community."
  Dots: ○ ○ ●
  Button: "GET STARTED" → /auth/login
```

---

### C-03 — Login Screen

```
┌──────────────────────────────┐
│                              │
│   ●●●  CivicConnect   ●●●   │  ← Logo + app name, centered
│                              │    titleLarge, primary
│                              │
│   Welcome back 👋            │  ← headlineMedium, onSurface
│   Sign in to continue        │  ← bodyMedium, onSurfaceVariant
│                              │
│  ┌──────────────────────────┐│  ← Email TextField (Filled)
│  │[email]  Email address    ││    leading icon, floating label
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← Password TextField
│  │[lock]   Password     [👁]││    trailing: show/hide toggle
│  └──────────────────────────┘│
│                              │
│                Forgot password?│  ← TextButton, right-aligned
│                              │
│  ┌──────────────────────────┐│  ← FilledButton (primary)
│  │          LOG IN          ││
│  └──────────────────────────┘│
│                              │
│  ──────────  OR  ──────────  │  ← Divider with label
│                              │
│  ┌──────────────────────────┐│  ← OutlinedButton + Google logo
│  │ [G]   Sign in with Google││
│  └──────────────────────────┘│
│                              │
│  Don't have an account?      │  ← bodyMedium inline
│  Sign Up                     │  ← TextButton, primary color
│                              │
└──────────────────────────────┘

Validation:
  Email: format check, required
  Password: min 8 chars
  Error messages appear below respective fields
  Button disabled until both fields non-empty
  Loading: spinner replaces button label on tap
```

---

### C-04 — Register Screen

```
┌──────────────────────────────┐
│  [←]   Create Account        │  ← TopAppBar, back arrow
│                              │
│   Join CivicConnect          │  ← headlineMedium
│   Help improve your city     │  ← bodyMedium, onSurfaceVariant
│                              │
│  ┌──────────────────────────┐│  ← Full Name
│  │[person]  Full name       ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← Email
│  │[email]   Email address   ││
│  └──────────────────────────┘│
│                              │
│  ┌──── ┐┌─────────────────┐ │  ← Phone: [+91 ▼][number field]
│  │+91 ▼││  Mobile number  │ │    dial code picker + number
│  └──── ┘└─────────────────┘ │
│                              │
│  ┌──────────────────────────┐│  ← Password
│  │[lock]   Password     [👁]││
│  └──────────────────────────┘│
│   Min 8 chars, 1 number      │  ← helper text
│                              │
│  ┌──────────────────────────┐│  ← Confirm Password
│  │[lock]  Confirm password  ││
│  └──────────────────────────┘│
│                              │
│  ☐ I agree to Terms of Use  │  ← Checkbox + inline link
│    and Privacy Policy        │
│                              │
│  ┌──────────────────────────┐│  ← FilledButton
│  │       CREATE ACCOUNT     ││
│  └──────────────────────────┘│
│                              │
│  Already have an account?    │
│  Log In                      │  ← TextButton
│                              │
└──────────────────────────────┘
```

---

### C-05 — Forgot Password Screen

```
┌──────────────────────────────┐
│  [←]   Reset Password        │  ← TopAppBar
│                              │
│                              │
│   [illustration: locked      │  ← spot illustration 180×160dp
│    envelope/phone]           │
│                              │
│   Forgot your password?      │  ← headlineMedium
│                              │
│   Enter your email or mobile │  ← bodyMedium, onSurfaceVariant
│   number. We'll send you a   │    centered
│   verification code.         │
│                              │
│  ┌──────────────────────────┐│
│  │[email]  Email or mobile  ││  ← single field, auto-detect
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← FilledButton
│  │     SEND OTP CODE        ││
│  └──────────────────────────┘│
│                              │
│  Remembered it? Log In       │  ← TextButton
│                              │
└──────────────────────────────┘
```

---

### C-06 — OTP Verification Screen

```
┌──────────────────────────────┐
│  [←]   Verify OTP            │  ← TopAppBar
│                              │
│                              │
│   [illustration: phone with  │  ← spot illustration
│    message bubbles]          │
│                              │
│   Enter verification code    │  ← headlineMedium
│                              │
│   We sent a 6-digit code to  │  ← bodyMedium
│   +91 98765 43210            │  ← bold, onSurface
│   [Change]                   │  ← TextButton inline
│                              │
│   ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐   │  ← OTP boxes
│   │  │  │  │  │  │  │  │  │  │  │  │   │    6 × 48×56dp
│   └──┘  └──┘  └──┘  └──┘  └──┘  └──┘   │
│                              │
│  ┌──────────────────────────┐│  ← FilledButton
│  │         VERIFY           ││    disabled until 6 digits
│  └──────────────────────────┘│
│                              │
│   Didn't receive the code?   │  ← bodyMedium
│   Resend in 00:45            │  ← countdown timer, labelLarge
│   (or [Resend] TextButton    │    after timer expires
│    after countdown)          │
│                              │
└──────────────────────────────┘

Auto-submit when 6th digit entered
Auto-focus next box on digit entry
Backspace clears current and focuses previous
```

---

### C-07 — Home Screen (Citizen)

```
┌──────────────────────────────┐
│  Good morning, Priya 👋   🔔 │  ← greeting (titleLarge) + notif bell
│  Mumbai · Andheri West       │  ← bodyMedium, location + ward
│                              │
│ ┌────────────────────────────┐  ← Search bar (M3 SearchBar style)
│ │ [🔍]  Search issues...     │    pill shape, surfaceVariant
│ └────────────────────────────┘
│                              │
│  ┌──────┐┌──────┐┌──────┐┌──┐│  ← Quick stats row (Summary Cards)
│  │  🔵  ││  🟡  ││  🟢  ││📊││    2×2 grid or horizontal scroll
│  │  12  ││  5   ││  89  ││  ││
│  │ Open ││ Mine ││Resolvd││  ││
│  └──────┘└──────┘└──────┘└──┘│
│                              │
│  Nearby Issues               │  ← sectionLabel (titleMedium)
│  Issues within 500m of you   │  ← bodySmall, onSurfaceVariant
│                              │
│  ┌────────────────────────── ┐│  ← Issue Card
│  │ [🛣]  ROADS    ● OPEN    ││
│  │ Pothole causing accidents ││
│  │ on Link Road near flyover ││
│  │ 📍 200m away  🕐 3h  👍18 ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│  ← Issue Card
│  │ [💡] LIGHT   ● IN PROG   ││
│  │ Street light out for      ││
│  │ past 4 days               ││
│  │ 📍 350m away  🕐 1d  👍 7 ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │ [💧] WATER   ✅ RESOLVED  ││
│  │ Water supply disruption…  ││
│  │ 📍 480m away  🕐 2d  👍 3 ││
│  └───────────────────────────┘│
│                              │
│     View all nearby (47)     │  ← TextButton, centered
│                              │
│                              │
│  My Recent Reports           │  ← section label
│                              │
│  ┌───────────────────────────┐│
│  │ [🛣] Pothole, MG Road     ││  ← my issue card (compact)
│  │ CC-2024-00142  ● ASSIGNED ││
│  └───────────────────────────┘│
│                              │
│ ─────────────────────────────│
│  🏠Home  🗺Map  🔔(3) 👤Profile│  ← BottomNavigationBar
└──────────────────────────────┘

FAB (Extended, bottom-right above nav bar):
┌────────────────────────┐
│  ➕  Report Issue       │
└────────────────────────┘

Pull-to-refresh on scroll
Shimmer loading for cards on initial load
```

---

### C-08 — Map Screen

```
┌──────────────────────────────┐
│  [←]        Map View    [⚙] │  ← TopAppBar, settings = filter
│                              │
│ ┌────────────────────────── ┐│  ← Filter chips (horizontal scroll)
│ │ All │ Roads │ Water │ More││    FilterChip M3, surfaceVariant
│ └────────────────────────── ┘│
│                              │
│  ╔══════════════════════════╗ │
│  ║                          ║ │  ← Google Map full width
│  ║   [📍]     [📍📍]        ║ │    pins colored by status
│  ║                          ║ │
│  ║       [📍]    [📍]       ║ │    cluster badge when multiple
│  ║                          ║ │    issues overlap
│  ║  [📍]                    ║ │
│  ║               [📍]       ║ │
│  ║                          ║ │
│  ║           [⊙]            ║ │  ← My location button (FAB-small)
│  ╚══════════════════════════╝ │    bottom-right of map
│                              │
│  ╔══════════════════════════╗ │  ← Issue Preview Bottom Sheet
│  ║  [🛣] Roads              ║ │    drag handle at top
│  ║  Pothole on Link Road    ║ │    shows on marker tap
│  ║  ● IN PROGRESS  200m away║ │
│  ║  [View Details]          ║ │
│  ╚══════════════════════════╝ │
│                              │
│ ─────────────────────────────│
│  🏠Home  🗺Map  🔔   👤       │
└──────────────────────────────┘

Map pins:
  Blue solid   = Submitted
  Purple solid = Assigned
  Amber solid  = In Progress
  Green solid  = Resolved
  Number badge = Clustered count

Legend button: top-right of map (info icon → legend sheet)
```

---

### C-09 to C-13 — Report Issue Flow (5 Steps)

```
STEP INDICATOR (persistent, below AppBar on all steps)
  ●──────●──────○──────○──────○
  Cat   Loc   Photo  Desc  Review
  Step 1 of 5

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 1 — Category Selection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌──────────────────────────────┐
│  [←]  Report an Issue        │
│  ●──────○──────○──────○──────○│
│                              │
│  What type of issue?         │  ← headlineMedium
│  Select the best category    │  ← bodyMedium, onSurfaceVariant
│                              │
│ ┌─────────────────────────── ┐│  ← 2-column grid of category cards
│ │┌──────────┐ ┌──────────┐  ││
│ ││   🛣     │ │   💧     │  ││  ← Category Card (selectable)
│ ││  Roads   │ │  Water   │  ││    84×84dp, icon + label
│ │└──────────┘ └──────────┘  ││    selected: primaryContainer bg
│ │┌──────────┐ ┌──────────┐  ││    + primary border + check
│ ││   ⚡     │ │   🗑     │  ││
│ ││ Electric │ │Sanitation│  ││
│ │└──────────┘ └──────────┘  ││
│ │┌──────────┐ ┌──────────┐  ││
│ ││   💡     │ │   🌳     │  ││
│ ││Streetlght│ │  Parks   │  ││
│ │└──────────┘ └──────────┘  ││
│ │┌──────────┐ ┌──────────┐  ││
│ ││   💦     │ │   ···    │  ││
│ ││ Drainage │ │  Other   │  ││
│ │└──────────┘ └──────────┘  ││
│ └────────────────────────── ┘│
│                              │
│  ┌──────────────────────────┐│
│  │        NEXT →            ││  ← disabled until selection made
│  └──────────────────────────┘│
└──────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 2 — Location
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌──────────────────────────────┐
│  [←]  Report an Issue        │
│  ●──────●──────○──────○──────○│
│                              │
│  Where is the issue?         │  ← headlineMedium
│                              │
│  ╔══════════════════════════╗ │  ← Map with draggable pin
│  ║                          ║ │    160dp height
│  ║         [📍]             ║ │    pin centered on GPS location
│  ║                          ║ │    draggable to correct position
│  ╚══════════════════════════╝ │
│                              │
│  ┌──────────────────────────┐│  ← Reverse-geocoded address
│  │[location] Link Rd, Andheri│   (auto-filled, read-only)
│  │          West, Mumbai     │
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← OutlinedButton
│  │[⊙]  Use My Current GPS  ││
│  └──────────────────────────┘│
│                              │
│  Or search for a location:   │  ← bodyMedium
│  ┌──────────────────────────┐│
│  │[🔍]  Search address...   ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │        NEXT →            ││
│  └──────────────────────────┘│
└──────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 3 — Photos
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌──────────────────────────────┐
│  [←]  Report an Issue        │
│  ●──────●──────●──────○──────○│
│                              │
│  Add photos                  │  ← headlineMedium
│  Up to 5 photos help resolve │  ← bodyMedium
│  issues faster               │
│                              │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ │  ← Photo thumbnails (88×88dp each)
│ │[+] │ │[+] │ │[+] │ │[+] │ │    empty = dashed border + add icon
│ │    │ │    │ │    │ │    │ │    filled = photo thumbnail + X badge
│ └────┘ └────┘ └────┘ └────┘ │
│                              │
│  ┌──────────────────────────┐│  ← OutlinedButton
│  │[📷]  Take Photo          ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← OutlinedButton
│  │[🖼]  Choose from Gallery ││
│  └──────────────────────────┘│
│                              │
│  Photos are optional         │  ← bodySmall, onSurfaceVariant
│                              │
│  ┌──────────────────────────┐│
│  │   NEXT → (or Skip)       ││  ← "Skip" as TextButton below
│  └──────────────────────────┘│
│         Skip this step       │
└──────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 4 — Description
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌──────────────────────────────┐
│  [←]  Report an Issue        │
│  ●──────●──────●──────●──────○│
│                              │
│  Describe the issue          │  ← headlineMedium
│  More detail = faster fix    │  ← bodyMedium, onSurfaceVariant
│                              │
│  ┌──────────────────────────┐│  ← Title field (single line)
│  │[edit]  Issue title       ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← Description (multiline, 4 lines min)
│  │  Describe the issue in   ││
│  │  detail...               ││
│  │                          ││
│  │                          ││
│  │                    0/500 ││  ← character counter
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │        NEXT →            ││
│  └──────────────────────────┘│
└──────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 5 — Review & Submit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌──────────────────────────────┐
│  [←]  Review Report          │
│  ●──────●──────●──────●──────●│
│                              │
│  Review your report          │  ← headlineMedium
│                              │
│  ┌──────────────────────────┐│  ← Summary Card
│  │ Category:  🛣 Roads      ││
│  │ Location:  Link Rd, Andhe││
│  │            ri West       ││
│  │ Photos:    3 attached    ││
│  │ Title:     Pothole near  ││
│  │            school        ││
│  │ Details:   Large pothole ││
│  │            causing...    ││
│  └──────────────────────────┘│
│                              │
│  [Photo thumbnail 1]  [2] [3]│  ← Thumbnail row
│                              │
│  ── Nearby duplicate check ──│  ← if nearby issues found:
│  ⚠ 2 similar reports nearby  │    amber info card
│  ┌──────────────────────────┐│
│  │ View nearby issues first?││
│  │ [View]   [Continue]      ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← Primary CTA
│  │      SUBMIT REPORT       ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← OutlinedButton
│  │   ← Edit Report          ││
│  └──────────────────────────┘│
└──────────────────────────────┘
```

---

### C-14 — Report Success Screen

```
┌──────────────────────────────┐
│                              │
│                              │
│         ✅                   │  ← animated check icon (72dp)
│                              │    Lottie animation: circle draws
│                              │    then checkmark appears
│                              │
│   Report Submitted!          │  ← headlineLarge, centered
│                              │
│   Thank you for making       │  ← bodyLarge, centered,
│   your city better.          │    onSurfaceVariant
│                              │
│  ┌──────────────────────────┐│  ← Tracking ID card
│  │  Tracking ID             ││
│  │  CC-2024-00142           ││  ← labelLarge, primary
│  │  [📋 Copy]               ││    IconButton to copy
│  └──────────────────────────┘│
│                              │
│  Expected resolution:        │  ← bodyMedium
│  Within 3 working days       │  ← based on category SLA
│                              │
│                              │
│  ┌──────────────────────────┐│  ← FilledButton
│  │     TRACK THIS ISSUE     ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← OutlinedButton
│  │      BACK TO HOME        ││
│  └──────────────────────────┘│
│                              │
└──────────────────────────────┘
```

---

### C-15 — My Issues List

```
┌──────────────────────────────┐
│  [←]      My Reports    [🔍] │  ← TopAppBar + search icon
│                              │
│ ┌──────────────────────────┐ │  ← Filter chips (horizontal scroll)
│ │ All(12)│Open│In Prog│Done│ │    FilterChip row
│ └──────────────────────────┘ │
│                              │
│  ┌───────────────────────────┐│  ← Issue list tile
│  │ [🛣]  Pothole, Link Road  ││    leading: category icon circle
│  │ CC-2024-00142             ││    subtitle: tracking ID + date
│  │ 📍 Andheri West  🕐 2d   ││
│  │              ● ASSIGNED  ││    trailing: status chip
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │ [💡] Street Light Out     ││
│  │ CC-2024-00138             ││
│  │ 📍 Link Road   🕐 5d      ││
│  │           ● IN PROGRESS  ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │ [💧] Water Leakage        ││
│  │ CC-2024-00121             ││
│  │ 📍 SV Road     🕐 12d     ││
│  │  ✅ RESOLVED  [Verify →] ││  ← "Verify" CTA when resolved
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │ [🗑] Garbage Not Collected││
│  │ CC-2024-00099             ││
│  │ 📍 Lokhandwala  🕐 20d    ││
│  │              ● CLOSED    ││
│  └───────────────────────────┘│
│                              │
│         Load more…           │  ← TextButton / infinite scroll
│                              │
│ ─────────────────────────────│
│  🏠Home  🗺Map  🔔   👤       │
└──────────────────────────────┘

Swipe-to-reveal actions on each tile:
  Right swipe: [Share] (secondary color)
  Left swipe:  [View on Map] (tertiary color)

Sort button in AppBar trailing: sort by date / status / category
```

---

### C-16 — Issue Details (Citizen View)

```
┌──────────────────────────────┐
│  [←]  Issue Details   [↗][⋮]│  ← back, share, more options
│                              │
│  ╔══════════════════════════╗ │  ← Photo carousel (200dp height)
│  ║                          ║ │    PageView with dot indicators
│  ║    [Issue Photo 1/3]     ║ │    if no photos: category icon
│  ║                          ║ │    on primaryContainer bg
│  ║  ●  ○  ○                 ║ │
│  ╚══════════════════════════╝ │
│                              │
│  [🛣] ROADS                  │  ← category chip (labelMedium)
│  Pothole on Link Road near   │  ← titleLarge (2 lines max)
│  school entrance             │
│                              │
│  ● ASSIGNED                  │  ← status chip (large)
│                              │
│  ┌──────────────────────────┐│  ← Info row card (surfaceVariant)
│  │ 📍 Link Road, Andheri W  ││
│  │ 🏷 CC-2024-00142         ││  ← tracking ID
│  │ 🕐 Reported 2 days ago   ││
│  │ ⏱ SLA: 3 working days   ││
│  │ 🏢 Roads Department      ││  ← assigned department
│  └──────────────────────────┘│
│                              │
│  Description                 │  ← titleMedium section header
│  Large pothole at the school ││  ← bodyMedium, onSurface
│  gate. Approximately 2ft wide│
│  and 6 inches deep. Has been │
│  there since last monsoon.   │
│                              │
│  👍 18 citizens upvoted this │  ← upvote count, bodyMedium
│  ┌──────────────────────────┐│  ← OutlinedButton (if not upvoted)
│  │ 👍  Upvote this Issue    ││    or filled (if already upvoted)
│  └──────────────────────────┘│
│                              │
│  ──── Status Timeline ────   │  ← section header
│                              │
│  ✅ Submitted                │  ← timeline item (done)
│  │  Jun 12, 2024, 9:41 AM   │
│  ✅ Assigned                 │
│  │  Jun 12, 2024, 11:00 AM  │
│  │  Roads Dept — Suresh P.  │
│  ◌ In Progress               │  ← current (animated pulse dot)
│  │  Pending update           │
│  ◌ Resolved                  │  ← future (grey, empty dot)
│  ◌ Closed                    │
│                              │
│ ─────────────────────────────│
│  🏠Home  🗺Map  🔔   👤       │
└──────────────────────────────┘

AppBar "more" menu (⋮):
  - View on Map
  - Share
  - Report as Spam

"Verify" button appears prominently (FilledButton, full width)
when status = RESOLVED, replacing the upvote section.
```

---

### C-17 — Verify Resolution Screen

```
┌──────────────────────────────┐
│  [←]  Verify Resolution      │
│                              │
│  Issue has been marked       │  ← headlineMedium
│  resolved                    │
│                              │
│  The Roads Department has    │  ← bodyMedium, onSurfaceVariant
│  marked your report as       │
│  resolved. Please check and  │
│  confirm.                    │
│                              │
│  ── Resolution Evidence ──   │  ← section label
│                              │
│  ╔════════════╗╔════════════╗ │  ← Before/After photo pair
│  ║            ║║            ║ │    labeled "Before" / "After"
│  ║  [Before]  ║║  [After]   ║ │    each 160×120dp
│  ║            ║║            ║ │
│  ╚════════════╝╚════════════╝ │
│                              │
│  Resolution note:            │  ← titleSmall
│  "Pothole filled and road    │  ← bodyMedium, onSurfaceVariant
│  surface relaid. Work        │
│  completed Jun 14."          │
│                              │
│  Resolved on Jun 14, 2024    │  ← labelMedium, onSurfaceVariant
│                              │
│  ── Was this resolved? ──    │  ← section label
│                              │
│  ┌──────────────────────────┐│  ← FilledButton (green / success)
│  │  ✅  Yes, it's resolved  ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← OutlinedButton (error outline)
│  │  ❌  No, still an issue  ││
│  └──────────────────────────┘│
│                              │
│  ── Rate the resolution ──   │  ← section label (shown after confirm)
│                              │
│   ★ ★ ★ ★ ☆                 │  ← StarRating widget (5 stars, 40dp each)
│   Leave a comment (optional) │
│  ┌──────────────────────────┐│
│  │  Your feedback...        ││  ← multiline text field
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│
│  │       SUBMIT RATING      ││
│  └──────────────────────────┘│
└──────────────────────────────┘

If "No, still an issue" tapped:
  → Bottom sheet with reason field (required)
  → "Reason for reopening..." text input
  → [REOPEN ISSUE] FilledButton (error color)
  → Issue status reverts to SUBMITTED with reopen note
```

---

### C-18 — Notifications Screen

```
┌──────────────────────────────┐
│  [←]  Notifications   [✓✓] │  ← "Mark all read" icon button
│                              │
│ ┌──────────────────────────┐ │  ← Filter chips
│ │  All  │  Reports  │ Alerts│ │
│ └──────────────────────────┘ │
│                              │
│  Today                       │  ← Date group label (labelMedium)
│                              │
│  ┌───────────────────────────┐│  ← Unread notification tile
│  │●[🛣] Your report has been ││    ● = unread indicator dot (8dp)
│  │      assigned to the Roads││    primary color
│  │      Dept.                ││
│  │      CC-2024-00142 · 2h   ││    timestamp (labelSmall)
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│  ← Unread
│  │●[✅] Issue CC-2024-00138  ││
│  │      has been resolved.   ││
│  │      Verify the fix.      ││
│  │      CC-2024-00138 · 4h   ││
│  └───────────────────────────┘│
│                              │
│  Yesterday                   │  ← Date group label
│                              │
│  ┌───────────────────────────┐│  ← Read notification (no dot)
│  │ [🔔] 12 citizens upvoted  ││    background: surface (not variant)
│  │      your report on Link  ││
│  │      Road.                ││
│  │      CC-2024-00142 · 1d   ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │ [📋] Your report has been ││
│  │      submitted to Mumbai  ││
│  │      Municipal Corp.      ││
│  │      CC-2024-00142 · 1d   ││
│  └───────────────────────────┘│
│                              │
│  This week                   │
│         ·  ·  ·              │  ← more items
│                              │
│ ─────────────────────────────│
│  🏠Home  🗺Map  🔔   👤       │
└──────────────────────────────┘

Swipe left on any tile to dismiss (delete notification)
Tap: navigate to relevant Issue Details screen
Empty state: bell illustration + "You're all caught up"
```

---

### C-19 — Profile Screen (Citizen)

```
┌──────────────────────────────┐
│         Profile          [✏]│  ← CenterAlignedTopAppBar + edit
│                              │
│                              │
│          ┌──────┐            │  ← Avatar (72dp circle)
│          │  PN  │            │    initials fallback, primary bg
│          └──────┘            │
│        Priya Nair            │  ← titleLarge, centered
│     priya.nair@gmail.com     │  ← bodyMedium, onSurfaceVariant
│   Mumbai · Andheri West      │  ← bodySmall, onSurfaceVariant
│          Member since Jun'24 │  ← labelSmall
│                              │
│  ┌──────┐ ┌──────┐ ┌──────┐ │  ← Stats row
│  │  12  │ │  10  │ │  4.8 │ │    3 summary cards
│  │Reports│ │Resvd │ │ Avg ★│ │
│  └──────┘ └──────┘ └──────┘ │
│                              │
│  ── Activity ─────────────── │
│                              │
│  [📋] My Reports         [›] │  ← Navigation list tiles
│  [🔔] Notifications      [›] │    56dp height each
│  [⭐] My Ratings          [›] │
│                              │
│  ── Account ──────────────── │
│                              │
│  [✏] Edit Profile        [›] │
│  [🔒] Change Password     [›] │
│  [🌐] Language            [›] │
│  [⚙] Settings            [›] │
│                              │
│  ── Support ───────────────── │
│                              │
│  [❓] Help & FAQ          [›] │
│  [📄] Terms of Service    [›] │
│  [🔏] Privacy Policy      [›] │
│                              │
│  ┌──────────────────────────┐│  ← TextButton, error color
│  │       LOG OUT            ││
│  └──────────────────────────┘│
│                              │
│ ─────────────────────────────│
│  🏠Home  🗺Map  🔔   👤       │
└──────────────────────────────┘
```

---

### C-20 — Edit Profile Screen

```
┌──────────────────────────────┐
│  [←]   Edit Profile   [Save] │  ← Save = TextButton, primary
│                              │
│          ┌──────┐            │
│          │  PN  │            │  ← Avatar (72dp)
│          │  [✏] │            │  ← edit overlay on avatar tap
│          └──────┘            │
│       Tap to change photo    │  ← labelSmall, onSurfaceVariant
│                              │
│  ┌──────────────────────────┐│
│  │[person]  Full name       ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← read-only (grayed)
│  │[email]   Email address   ││    with lock icon trailing
│  └──────────────────────────┘│
│   Email cannot be changed    │  ← helper text
│                              │
│  ┌──── ┐┌─────────────────┐ │
│  │+91 ▼││  Mobile number  │ │
│  └──── ┘└─────────────────┘ │
│                              │
│  ┌──────────────────────────┐│  ← City / location
│  │[location]  City          ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│
│  │[location]  Ward / Area   ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← Filled primary button
│  │       SAVE CHANGES       ││
│  └──────────────────────────┘│
└──────────────────────────────┘
```

---

### C-21 — Settings Screen

```
┌──────────────────────────────┐
│  [←]       Settings          │
│                              │
│  ── Notifications ─────────  │  ← Section header (labelMedium,
│                              │    onSurfaceVariant, uppercase)
│  Push Notifications          │  ← SwitchListTile (M3)
│  Receive app notifications [■]│    toggle on right, 56dp
│                              │
│  Email Alerts              [■]│
│  Status updates by email     │
│                              │
│  SMS Alerts                [□]│  ← toggle off
│  Status updates by SMS       │
│                              │
│  ── Appearance ────────────  │
│                              │
│  Theme                   [›] │  ← opens sub-screen: Light/Dark/System
│  System default              │    current value shown as subtitle
│                              │
│  Language                [›] │  ← opens language picker sheet
│  English                     │
│                              │
│  Text Size                   │  ← Slider (M3 Slider)
│  A ━━━━●━━━━━━━━━ A          │    Small → Large, 5 steps
│                              │
│  ── Privacy ───────────────  │
│                              │
│  Location Access          [■]│  ← SwitchListTile
│  Used for issue reporting    │
│                              │
│  Anonymous Reporting       [□]│
│  Hide identity on reports    │
│                              │
│  ── Data & Storage ────────  │
│                              │
│  Offline Drafts           [›] │  ← X drafts saved, clear option
│  Clear App Cache          [›] │
│  Download My Data         [›] │  ← GDPR data export
│                              │
│  ── Account ───────────────  │
│                              │
│  Delete Account           [›] │  ← error color text
│                              │
│  App Version: 1.0.0 (42)     │  ← labelSmall, onSurfaceVariant
│                              │
└──────────────────────────────┘
```

---

### O-01 — Officer Dashboard (Field Worker View)

```
┌──────────────────────────────┐
│  Good morning, Suresh 👷  🔔 │  ← greeting + notification bell
│  Roads Dept · Andheri Ward   │  ← role + department + ward
│                              │
│  ┌──────┐ ┌──────┐ ┌──────┐ │  ← Today's summary cards
│  │  8   │ │  3   │ │  5   │ │
│  │Total │ │Done  │ │Pendin│ │
│  └──────┘ └──────┘ └──────┘ │
│                              │
│  My Tasks Today              │  ← titleMedium section header
│                              │
│  ── URGENT (SLA < 2h) ─────  │  ← sub-section, error color label
│                              │
│  ┌───────────────────────────┐│  ← Task card (urgent — error border)
│  │ [🛣] ● CRITICAL           ││    left border: 4dp error color
│  │ Road collapse near market ││
│  │ 📍 SV Road, 0.3km    [🗺] ││    map icon = navigate CTA
│  │ ⏱ SLA expires in 1h 20m  ││    SLA chip: error color
│  │ [ACCEPT TASK]             ││    CTA button
│  └───────────────────────────┘│
│                              │
│  ── IN PROGRESS ────────────  │  ← amber section label
│                              │
│  ┌───────────────────────────┐│  ← Task card (in progress)
│  │ [🛣] ● HIGH               ││    amber left border
│  │ Pothole, Link Road        ││
│  │ 📍 Link Road, 0.8km  [🗺] ││
│  │ ⏱ SLA: 5h remaining      ││
│  │ Status: In Progress       ││
│  │ [UPDATE STATUS]           ││
│  └───────────────────────────┘│
│                              │
│  ── PENDING ────────────────  │  ← blue section label
│                              │
│  ┌───────────────────────────┐│
│  │ [🛣] ● MEDIUM             ││
│  │ Damaged road divider      ││
│  │ 📍 MG Road, 1.2km    [🗺] ││
│  │ ⏱ SLA: 2 days remaining  ││
│  │ [ACCEPT TASK]             ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │ [🛣] ● LOW                ││
│  │ Speed bump damaged        ││
│  │ 📍 D.N. Road, 2.1km  [🗺] ││
│  │ ⏱ SLA: 4 days remaining  ││
│  │ [ACCEPT TASK]             ││
│  └───────────────────────────┘│
│                              │
│ ─────────────────────────────│
│    ✅Tasks   🔔Alerts  👤Me  │  ← BottomNavigationBar (3 items)
└──────────────────────────────┘
```

---

### O-03 — Task Detail (Field Worker View)

```
┌──────────────────────────────┐
│  [←]   Task Detail     [↗]  │  ← back + share
│                              │
│  ╔══════════════════════════╗ │  ← Photo carousel (issue photos)
│  ║                          ║ │    200dp, swipeable
│  ║   [Issue photo / map]    ║ │
│  ║                          ║ │
│  ╚══════════════════════════╝ │
│                              │
│  [🛣] ROADS          ● HIGH  │  ← category chip + priority chip
│  Pothole on Link Road near   │  ← titleLarge
│  school entrance             │
│                              │
│  ┌──────────────────────────┐│  ← Task info card
│  │ 🏷 CC-2024-00142         ││
│  │ 📍 Link Road, Andheri W  ││
│  │ 🕐 Assigned: Jun 12, 10am││
│  │ ⏱ SLA: 5h 20m remaining ││  ← SLA timer (amber if < 4h)
│  │ 👤 Assigned by: Anitha R.││
│  └──────────────────────────┘│
│                              │
│  Issue Description           │  ← titleSmall
│  Large pothole approx 2ft    │  ← bodyMedium
│  wide, school children at    │
│  risk. High foot traffic.    │
│                              │
│  ┌──────────────────────────┐│  ← Navigate button (prominent)
│  │ [🗺]  Navigate to Site   ││    opens Google Maps / Maps app
│  └──────────────────────────┘│
│                              │
│  ── Update Status ──────────  │  ← section header
│                              │
│  Current: ● ASSIGNED         │  ← current status chip
│                              │
│  ┌──────────────────────────┐│  ← FilledButton (primary)
│  │  ▶  MARK AS IN PROGRESS  ││
│  └──────────────────────────┘│
│                              │
│  ── Add Notes ──────────────  │
│  ┌──────────────────────────┐│
│  │  Internal note...        ││  ← multiline text field
│  └──────────────────────────┘│
│                              │
│  ── Upload Resolution ──────  │  ← shown when status = In Progress
│                              │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ │  ← Photo upload grid
│ │[+] │ │[+] │ │[+] │ │[+] │ │    for resolution evidence
│ └────┘ └────┘ └────┘ └────┘ │
│                              │
│  ┌──────────────────────────┐│  ← Available after photos added
│  │  ✅  MARK AS COMPLETED   ││    FilledButton (success green)
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← TextButton (error color)
│  │  ⬆  REQUEST ESCALATION  ││
│  └──────────────────────────┘│
└──────────────────────────────┘

Mark as Completed → Confirmation dialog:
  "Are you sure? This will notify the citizen."
  [Cancel] [CONFIRM]
```

---

### O-04 — Officer Dashboard (Supervisor View)

```
┌──────────────────────────────┐
│  Water Dept · Supervisor  🔔 │  ← role title + bell
│  Anitha Rao                  │  ← subtitle
│                              │
│  ┌──────┐┌──────┐┌──────┐┌──┐│  ← Summary stats row
│  │  28  ││  4   ││  12  ││  ││
│  │ Open ││Overdue│ Resolvd││📊││
│  └──────┘└──────┘└──────┘└──┘│
│   ↑ 5 from yesterday         │  ← trend indicator, labelSmall
│                              │
│  ── Requires Attention ────  │  ← error section: overdue issues
│                              │
│  ┌───────────────────────────┐│  ← Overdue tile (error bg tint)
│  │●[💧] Water main break     ││    ● = red priority dot
│  │ CC-2024-00131  OVERDUE ⏱ ││    OVERDUE chip (error color)
│  │ 📍 Kurla East  ·  6h late ││
│  │ Unassigned                ││    "Unassigned" badge (warning)
│  │ [ASSIGN NOW]              ││    CTA button
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │●[💧] Pipe burst, market   ││
│  │ CC-2024-00128  OVERDUE ⏱ ││
│  │ 📍 Dharavi  ·  2h late    ││
│  │ Assigned: Ravi K.         ││
│  │ [REASSIGN]   [ESCALATE]   ││  ← two action buttons
│  └───────────────────────────┘│
│                              │
│  ── All Open Issues ────────  │  ← full queue section
│                              │
│  ┌──────────────────────────┐ │  ← Filter / Sort bar
│  │[🔍] Filter  Sort: Newest▼│ │    inline search + sort dropdown
│  └──────────────────────────┘ │
│                              │
│  ┌───────────────────────────┐│  ← Standard issue list tile
│  │ [💧] Water discoloration  ││
│  │ CC-2024-00145  ● SUBMITTED││
│  │ 📍 Goregaon W  ·  1h     ││    SLA chip: 2d 4h remaining
│  │ Unassigned       [2d SLA] ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │ [💧] Low water pressure   ││
│  │ CC-2024-00144  ● ASSIGNED ││
│  │ 📍 Malad W  ·  3h        ││
│  │ → Suresh P.    [1d SLA]  ││
│  └───────────────────────────┘│
│                              │
│  Load more (22 remaining)    │
│                              │
│ ─────────────────────────────│
│  📋Queue  👥Team  📊Stats  👤 │  ← Supervisor bottom nav
└──────────────────────────────┘
```

---

### O-05 — Issue Detail (Supervisor View)

```
┌──────────────────────────────┐
│  [←]  Issue Detail    [⋮]   │  ← more: merge, delete, history
│                              │
│  ╔══════════════════════════╗ │  ← Photo carousel
│  ║   [Issue Photo]          ║ │
│  ╚══════════════════════════╝ │
│                              │
│  [💧] WATER         ● OVERDUE│  ← category + OVERDUE status chip
│  Water main break on         │  ← titleLarge
│  LBS Road, Kurla             │
│                              │
│  ┌──────────────────────────┐│  ← Issue info card
│  │ 🏷 CC-2024-00131         ││
│  │ 📍 LBS Road, Kurla East  ││
│  │ 🕐 Reported: 18h ago     ││
│  │ ⏱ OVERDUE by 6 hours    ││  ← error color row
│  │ 👍 41 upvotes            ││
│  └──────────────────────────┘│
│                              │
│  ── Assignment ─────────────  │
│                              │
│  Currently: Unassigned       │  ← labelMedium + status
│                              │
│  ┌──────────────────────────┐│  ← FilledButton
│  │ [👤]  ASSIGN TO WORKER   ││    opens worker picker bottom sheet
│  └──────────────────────────┘│
│                              │
│  ── Priority ───────────────  │
│                              │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ │  ← Priority selector (ChoiceChip row)
│  │Low │ │Med │ │High│ │CRIT│ │    CRITICAL selected (error bg)
│  └────┘ └────┘ └────┘ └────┘ │
│                              │
│  ── Actions ────────────────  │
│                              │
│  ┌──────────────────────────┐│  ← FilledButton (tertiary/warning)
│  │ ⬆  ESCALATE TO ADMIN    ││
│  └──────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← OutlinedButton
│  │ ✕  REJECT (with reason) ││
│  └──────────────────────────┘│
│                              │
│  ── Internal Notes ─────────  │  ← not visible to citizen
│                              │
│  [Anitha R., 2h ago]         │  ← existing note
│  "Contractor required.       │
│   Notified PWD."             │
│                              │
│  ┌──────────────────────────┐│  ← Add note field
│  │  Add internal note...    ││
│  └──────────────────────────┘│
│  [POST NOTE]                 │  ← TextButton
│                              │
│  ── Timeline ───────────────  │  ← collapsible section
│  ✅ Submitted · 18h ago      │
│  ◌  Unassigned (pending)     │
└──────────────────────────────┘

Worker Picker Bottom Sheet (on ASSIGN tap):
┌──────────────────────────────┐
│  ▬▬▬                         │  ← drag handle
│  Assign to Field Worker      │  ← titleMedium
│  ┌──────────────────────────┐│
│  │[🔍]  Search workers...   ││
│  └──────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│  ← Worker list tile
│  │[SP] Suresh Patil          ││    initials avatar
│  │     3 active tasks  ● Avl ││    task count + availability dot
│  └───────────────────────────┘│
│  ┌───────────────────────────┐│
│  │[RK] Ravi Kumar            ││
│  │     5 active tasks  ● Busy││    "Busy" amber dot
│  └───────────────────────────┘│
│  ┌──────────────────────────┐ │
│  │       ASSIGN             │ │  ← disabled until selection
│  └──────────────────────────┘ │
└──────────────────────────────┘
```

---

### O-06 — Team Workload Screen (Supervisor)

```
┌──────────────────────────────┐
│  [←]   Team Workload         │
│  Water Dept — Today          │
│                              │
│  ┌──────┐ ┌──────┐ ┌──────┐ │  ← Team stats
│  │  6   │ │  2   │ │  0   │ │
│  │Workers│ │ Busy │ │Ofline│ │
│  └──────┘ └──────┘ └──────┘ │
│                              │
│  ┌──────────────────────────┐ │  ← Sort: By workload ▼
│  │  Sort: By workload ▼     │ │
│  └──────────────────────────┘ │
│                              │
│  ┌───────────────────────────┐│  ← Worker card
│  │[SP] Suresh Patil  ● Online││    avatar + name + status dot
│  │     ████████░░  3/5 tasks ││    progress bar: tasks done
│  │ Current: Pothole, Link Rd ││    current active task
│  │ ⏱ SLA in 5h 20m          ││
│  │ [VIEW TASKS]  [+ ASSIGN]  ││    two action buttons
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │[RK] Ravi Kumar    ● Online││
│  │     ██████████  5/5 tasks ││    fully loaded bar
│  │ Current: Pipe burst, Kurla││
│  │ ⏱ OVERDUE ⚠               ││    error color
│  │ [VIEW TASKS]  [+ ASSIGN]  ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │[AM] Anil Mane     ● Online││
│  │     ██░░░░░░░░  1/5 tasks ││    low load bar
│  │ Current: Idle             ││
│  │ [VIEW TASKS]  [+ ASSIGN]  ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │[VJ] Vijay Jadhav  ○ Offln ││    grey dot = offline
│  │     ░░░░░░░░░░  0/5 tasks ││
│  │                           ││
│  └───────────────────────────┘│
│                              │
│ ─────────────────────────────│
│  📋Queue  👥Team  📊Stats  👤 │
└──────────────────────────────┘
```

---

### A-01 — Admin Dashboard (Overview)

```
┌──────────────────────────────┐
│  CivicConnect · Admin     🔔 │  ← App bar (no back arrow on root)
│  Mumbai Municipal Corp.      │  ← municipality name, bodyMedium
│                              │
│  ─── City Overview ─────────  │  ← section label
│  June 2024 · Real-time       │  ← bodySmall, onSurfaceVariant
│                              │
│  ┌──────────┐ ┌──────────┐  │  ← 2×2 Summary card grid
│  │    🔵    │ │    🟡    │  │
│  │   247    │ │    18    │  │
│  │   Open   │ │  Overdue │  │    overdue card: error bg tint
│  └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │    🟢    │ │    ⭐    │  │
│  │  1,824   │ │   4.2    │  │
│  │ Resolved │ │ Avg Rating│  │
│  └──────────┘ └──────────┘  │
│                              │
│  ─── Dept Performance ─────  │  ← section label
│                              │
│  ┌───────────────────────────┐│  ← Horizontal scroll dept cards
│  │ 🛣 Roads                  ││
│  │ 64 open · 3 overdue      ││
│  │ SLA: ██████████ 82%       ││  ← mini progress bar
│  └───────────────────────────┘│
│  ┌───────────────────────────┐│
│  │ 💧 Water Supply           ││
│  │ 91 open · 8 overdue      ││
│  │ SLA: ████████░░ 71%       ││
│  └───────────────────────────┘│
│  ┌───────────────────────────┐│
│  │ ⚡ Electricity            ││
│  │ 42 open · 4 overdue      ││
│  │ SLA: █████████░ 88%       ││
│  └───────────────────────────┘│
│  → Swipe for more depts       │  ← hint text
│                              │
│  ─── Recent Alerts ─────────  │
│                              │
│  ┌───────────────────────────┐│  ← Alert tile (error bg tint)
│  │⚠ 8 issues OVERDUE in      ││
│  │  Water Dept · 2h ago      ││
│  │  [VIEW DEPT]              ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│  ← Info alert tile
│  │ℹ SLA policy updated for   ││
│  │  Roads by System Admin    ││
│  │  Yesterday               ││
│  └───────────────────────────┘│
│                              │
│  ─── Issue Trend ───────────  │
│                              │
│  ┌──────────────────────────┐ │  ← Sparkline chart (7-day)
│  │ ╭──╮                    │ │    issues submitted per day
│  │╭╯  ╰╮    ╭╮            │ │    primary color line
│  ││    ╰────╯ ╰───         │ │
│  │Mon Tue Wed Thu Fri Sat  │ │
│  └──────────────────────────┘ │
│  View full analytics →        │  ← TextButton
│                              │
│ ─────────────────────────────│
│  📊Oview 📋Issues 📈Stats ⚙Config 👤│  ← Admin bottom nav (5 items)
└──────────────────────────────┘
```

---

### A-02 — Admin Issues Screen

```
┌──────────────────────────────┐
│  [←]  All Issues       [🔍] │
│                              │
│  ┌──────────────────────────┐ │  ← Filter row (horizontal scroll)
│  │ All │Roads│Water│Elec│+  │ │    category filter chips
│  └──────────────────────────┘ │
│  ┌──────────────────────────┐ │  ← Second filter row
│  │ All │Open │Overdue│Resol │ │    status filter chips
│  └──────────────────────────┘ │
│                              │
│  247 issues  Sort: Newest▼   │  ← count + sort control
│                              │
│  ┌───────────────────────────┐│  ← Issue list tile (Admin view)
│  │ [💧] ● OVERDUE   ● CRIT  ││    status + priority chips
│  │ Water main break, Kurla  ││
│  │ 📍 LBS Road  ·  18h ago  ││
│  │ Water Dept · Unassigned  ││    dept + assignment info
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │ [🛣] ● ASSIGNED   ● HIGH ││
│  │ Road collapse, Thane     ││
│  │ 📍 Pokhran Rd  ·  3h ago ││
│  │ Roads Dept · Suresh P.   ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │ [⚡] ● SUBMITTED ● MED   ││
│  │ Power outage, sector 7   ││
│  │ 📍 Vashi  ·  45min ago   ││
│  │ Electricity · Unassigned ││
│  └───────────────────────────┘│
│                              │
│         Load more…           │
│                              │
│ ─────────────────────────────│
│  📊Oview 📋Issues 📈Stats ⚙Config 👤│
└──────────────────────────────┘

Tap issue → opens Issue Detail (read-only admin view with override actions)
Long-press → multi-select for bulk operations (bulk assign dept, bulk close)
```

---

### A-03 — Analytics Screen (Admin)

```
┌──────────────────────────────┐
│  [←]  Analytics       [↗]  │  ← export icon (CSV/PDF)
│                              │
│  ┌──────────────────────────┐ │  ← Date range picker chip
│  │ 📅  Last 30 days    [▼] │ │    options: 7d / 30d / 90d / custom
│  └──────────────────────────┘ │
│                              │
│  ── Issue Volume Trend ─────  │
│                              │
│  ┌──────────────────────────┐ │  ← Line chart (fl_chart)
│  │    ╭──╮                  │ │    primary = Submitted
│  │   ╭╯  ╰╮  ╭╮            │ │    green = Resolved
│  │  ╭╯    ╰──╯ ╰────        │ │    x-axis: dates, y-axis: count
│  │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─    │ │
│  │ 1  5  9 13 17 21 25 29  │ │
│  │     ━━ Submitted  ━━ Resolvd│
│  └──────────────────────────┘ │
│                              │
│  ── Issues by Category ─────  │
│                              │
│  ┌──────────────────────────┐ │  ← Horizontal bar chart
│  │ Roads      ████████ 38% │ │
│  │ Water      ██████   28% │ │
│  │ Electric   ████     18% │ │
│  │ Sanitation ███      12% │ │
│  │ Other      █         4% │ │
│  └──────────────────────────┘ │
│                              │
│  ── Dept Performance ───────  │
│                              │
│  ┌──────────────────────────┐ │  ← Table / data rows
│  │ Dept       SLA%  AvgTime │ │
│  │ ──────────────────────── │ │
│  │ Roads       82%   2.1d   │ │
│  │ Water       71%   3.4d   │ │    71% → amber color (warning)
│  │ Electricity 88%   1.8d   │ │
│  │ Sanitation  65%   4.2d   │ │    65% → error color
│  └──────────────────────────┘ │
│                              │
│  ── Heatmap ────────────────  │
│                              │
│  ┌──────────────────────────┐ │  ← Google Map with heatmap overlay
│  │  ╔═══════════════════╗   │ │    heat gradient: green → red
│  │  ║  [heatmap layer]  ║   │ │    intensity = issue density
│  │  ║   hot spots in    ║   │ │
│  │  ║   Kurla & Dharavi ║   │ │
│  │  ╚═══════════════════╝   │ │
│  └──────────────────────────┘ │
│                              │
│  ── Citizen Satisfaction ───  │
│                              │
│  ┌──────────────────────────┐ │  ← Rating breakdown
│  │  Overall: ⭐ 4.2 / 5     │ │
│  │  ★★★★★  ████████  52%   │ │    horizontal bars
│  │  ★★★★   █████     31%   │ │
│  │  ★★★    ██        12%   │ │
│  │  ★★     █          4%   │ │
│  │  ★      ░          1%   │ │
│  └──────────────────────────┘ │
│                              │
│ ─────────────────────────────│
│  📊Oview 📋Issues 📈Stats ⚙Config 👤│
└──────────────────────────────┘

Export bottom sheet (on ↗ tap):
  [📄 Export as PDF]
  [📊 Export as CSV]
  [📧 Email Report]
  Date range confirmation before export
```

---

### A-04 — Config Screen (Admin)

```
┌──────────────────────────────┐
│  [←]  Configuration          │
│  Mumbai Municipal Corp.      │
│                              │
│  ── Departments ────────────  │
│                              │
│  ┌───────────────────────────┐│  ← Dept list tile
│  │ [🛣] Roads Department    ││
│  │ 12 field workers · 64 open││
│  │                       [›] ││
│  └───────────────────────────┘│
│  ┌───────────────────────────┐│
│  │ [💧] Water Supply         ││
│  │ 8 field workers · 91 open ││
│  │                       [›] ││
│  └───────────────────────────┘│
│  ┌───────────────────────────┐│
│  │ [⚡] Electricity          ││
│  │ 6 field workers · 42 open ││
│  │                       [›] ││
│  └───────────────────────────┘│
│                              │
│  ┌──────────────────────────┐│  ← OutlinedButton
│  │ [+]  Add Department      ││
│  └──────────────────────────┘│
│                              │
│  ── Issue Categories ───────  │
│                              │
│  ┌───────────────────────────┐│
│  │ Issue Categories      [›] ││  ← navigation tile
│  │ 8 categories configured   ││
│  └───────────────────────────┘│
│                              │
│  ── SLA Policies ───────────  │
│                              │
│  ┌───────────────────────────┐│
│  │ SLA Configuration     [›] ││
│  │ 4 severity levels         ││
│  └───────────────────────────┘│
│                              │
│  ── Escalation Rules ───────  │
│                              │
│  ┌───────────────────────────┐│
│  │ Escalation Rules      [›] ││
│  │ 3 rules active            ││
│  └───────────────────────────┘│
│                              │
│  ── User Management ────────  │
│                              │
│  ┌───────────────────────────┐│
│  │ Authority Users       [›] ││
│  │ 34 users · 2 pending      ││
│  └───────────────────────────┘│
│                              │
│  ── Municipality ───────────  │
│                              │
│  ┌───────────────────────────┐│
│  │ Municipality Settings [›] ││
│  │ Mumbai Municipal Corp.    ││
│  └───────────────────────────┘│
│                              │
│ ─────────────────────────────│
│  📊Oview 📋Issues 📈Stats ⚙Config 👤│
└──────────────────────────────┘
```

---

### A-07 — User Management Screen (Admin)

```
┌──────────────────────────────┐
│  [←]  Authority Users  [+]  │  ← add user button (+ icon)
│                              │
│ ┌──────────────────────────┐ │  ← Search + filter
│ │[🔍]  Search users...     │ │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ All │Supervisor│FieldWork│ │    role filter chips
│ └──────────────────────────┘ │
│                              │
│  34 users                    │  ← count
│                              │
│  ┌───────────────────────────┐│  ← User tile
│  │[AR] Anitha Rao        ●  ││    ● = active (green dot)
│  │ Dept Supervisor           ││    role label
│  │ Water Supply Dept         ││    department
│  │ anitha.rao@mumbai.gov.in  ││
│  │ [EDIT]       [DEACTIVATE] ││    action buttons
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│
│  │[SP] Suresh Patil      ●  ││
│  │ Field Worker              ││
│  │ Roads Dept                ││
│  │ suresh.p@mumbai.gov.in   ││
│  │ [EDIT]       [DEACTIVATE] ││
│  └───────────────────────────┘│
│                              │
│  ┌───────────────────────────┐│  ← Inactive user (grayed)
│  │[RK] Raj Kumar         ○  ││    ○ = inactive (grey dot)
│  │ Field Worker  INACTIVE    ││    INACTIVE chip
│  │ Sanitation Dept           ││
│  │ [EDIT]       [REACTIVATE] ││
│  └───────────────────────────┘│
│                              │
│ ─────────────────────────────│
│  📊Oview 📋Issues 📈Stats ⚙Config 👤│
└──────────────────────────────┘

Add/Edit User Bottom Sheet:
┌──────────────────────────────┐
│  ▬▬▬                         │
│  Add Authority User          │
│  ┌──────────────────────────┐│
│  │[person]  Full name       ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│
│  │[email]   Gov't email     ││
│  └──────────────────────────┘│
│  Role:                        │
│  ┌──────────────────────────┐│  ← DropdownMenu
│  │  Field Worker          ▼ ││
│  └──────────────────────────┘│
│  Department:                  │
│  ┌──────────────────────────┐│
│  │  Roads                 ▼ ││
│  └──────────────────────────┘│
│  ┌──────────────────────────┐│
│  │       CREATE USER        ││
│  └──────────────────────────┘│
└──────────────────────────────┘
```

---

### A-08 — Admin Settings Screen

```
┌──────────────────────────────┐
│  [←]  Settings               │
│  Commissioner Krishnaswamy   │  ← name + role subtitle
│  Municipal Admin             │
│                              │
│          ┌──────┐            │  ← Avatar (64dp)
│          │  DK  │            │
│          └──────┘            │
│    D. Krishnaswamy           │  ← titleMedium
│    admin@mumbai.gov.in       │  ← bodySmall
│                              │
│  ── Notifications ─────────  │
│                              │
│  SLA Breach Alerts         [■]│
│  Escalation Alerts         [■]│
│  Daily Summary Email       [■]│
│  Weekly Report Email       [□]│
│                              │
│  ── Scheduled Reports ─────  │
│                              │
│  ┌───────────────────────────┐│  ← Scheduled report tile
│  │ Daily Summary      Active ││    with on/off toggle
│  │ Every day at 8:00 AM  [■] ││
│  └───────────────────────────┘│
│  ┌───────────────────────────┐│
│  │ Weekly Report      Active ││
│  │ Every Monday 9:00 AM  [■] ││
│  └───────────────────────────┘│
│  ┌──────────────────────────┐│
│  │ [+]  Add Schedule        ││
│  └──────────────────────────┘│
│                              │
│  ── Security ───────────────  │
│                              │
│  Multi-Factor Auth         [■]│  ← MFA toggle (can't be disabled
│  Required for admin login     │    by admin — greyed, always on)
│                              │
│  Change Password          [›] │
│                              │
│  ── Appearance ────────────  │
│                              │
│  Theme                   [›] │
│  Language                [›] │
│                              │
│  ── System ────────────────  │
│                              │
│  Audit Log               [›] │  ← view all admin actions
│  API Access              [›] │  ← webhook + API key management
│  App Version: 1.0.0 (42)    │
│                              │
│  ┌──────────────────────────┐│  ← TextButton, error color
│  │          LOG OUT         ││
│  └──────────────────────────┘│
└──────────────────────────────┘
```

---

## 7. Interaction & Animation Specifications

### 7.1 Transitions

```
Route Transition               Type                   Duration
────────────────────────────────────────────────────────────────
Stack push (drill-down)        Slide left + fade      300ms
Stack pop (back)               Slide right + fade     250ms
Bottom sheet open              Slide up               300ms
Bottom sheet close             Slide down             250ms
Modal dialog                   Scale + fade           200ms
Tab switch (bottom nav)        Fade                   200ms
Page in report flow            Slide left             250ms
Onboarding pages               Horizontal slide       350ms
Splash → onboarding/home       Fade                   400ms
```

---

### 7.2 Micro-interactions

```
Component               Interaction             Feedback
────────────────────────────────────────────────────────────────
Category card (step 1)  Tap                     Scale 0.97 + primaryContainer fill
Photo thumbnail [+]     Tap                     Ripple + camera sheet opens
OTP box                 Digit entered           Box border → primary, auto-advance
Status timeline dot     Page load               Stagger animation left to right
Issue card              Tap                     Ink ripple, then navigate
Upvote button           Tap (toggle)            Thumb scale bounce, count +1
Success screen          Load                    Lottie checkmark draw animation
FAB (Report Issue)      Scroll down             Collapse to icon-only FAB
FAB (Report Issue)      Scroll up               Expand back to extended FAB
Map marker              Tap                     Marker bounce + bottom sheet slides up
Summary cards           Load                    Count animates from 0 → value (600ms)
Progress bar (team)     Load                    Bar fills from left (500ms)
SLA chip (overdue)      Display                 Pulse red animation (1.5s loop)
```

---

### 7.3 Form Validation UX

```
Behavior                      Trigger
────────────────────────────────────────────────────────────────
Inline error messages         On field blur (not on type)
Password strength indicator   While typing password field
OTP auto-submit               On 6th digit entered
Button disabled state         Until required fields valid
Shake animation               On submit with errors
Error border color            On invalid field (error token)
Success checkmark in field    On valid input (optional, email/phone)
```

---

### 7.4 Loading & Skeleton Screens

```
Screen              Skeleton Shape
─────────────────────────────────────────────────────────
Home                2×2 stat card boxes + 3 issue card rectangles
My Issues           4 list tile rows with avatar + 2 text lines each
Notifications       4 notification rows with circle + 2 text lines
Map                 Full-screen placeholder with spinner overlay
Analytics           Chart area rectangles + bar row shapes
User list           4 user tile rows
```

---

## 8. Accessibility Specification

```
Requirement                     Implementation
────────────────────────────────────────────────────────────────────
Minimum touch target            48×48dp on all interactive elements
Color contrast                  4.5:1 minimum (text), 3:1 (UI components)
Screen reader labels            All icons have Semantics(label:) set
Focus order                     Logical reading order, no focus traps
Error announcements             ErrorText field auto-announces on screen reader
Image descriptions              All uploaded photos have alt text placeholder
Keyboard navigation             Full tab navigation in Flutter Web (dashboard)
Text scaling                    UI tested at 200% system font scale
No color-only meaning           Status always shown with text + color + icon
Interactive element names       All buttons, chips have explicit accessible labels
```

---

## 9. Responsive Breakpoints

```
Device Class    Width Range     Layout Changes
─────────────────────────────────────────────────────────────────
Phone (S)       < 360dp         Reduce card grid to 1 column
Phone (M)       360–414dp       Default — all wireframes above
Phone (L)       414–480dp       Cards get slightly wider padding
Tablet (S)      600–840dp       2-column layout for issue lists
                                Side-by-side report step + preview
Tablet (L)      840dp+          Navigation rail replaces bottom nav
                                Dashboard uses multi-column layout
```

---

## 10. Dark Mode Considerations

```
Adaptation                      Notes
─────────────────────────────────────────────────────────────────
All color tokens                Automatically invert using dark theme tokens (see §4.2)
Map style                       Switch to dark map style (Google Maps night mode)
Photos                          No change — photos render naturally
Status chip colors              Use dark theme semantic colors (see §4.2)
Illustrations                   SVG illustrations adapt (use currentColor fills)
Skeleton shimmer                Darker shimmer gradient on dark surface
Priority colors                 Same hues, lighter tones for readability on dark bg
```

---

*UI Design Document — CivicConnect Phase 1*
*Status: Awaiting Approval*
*Total screens designed: 36*
*Design system: Material 3 (Flutter)*
*Target: Android 8.0+ · iOS 14+*
