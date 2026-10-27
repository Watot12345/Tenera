# Tenera Main Screen — Senior-Friendly UI/UX Revision Plan

Based on your feedback, this revised UI/UX design is engineered specifically for **older landlords and family managers (parents/non-digital natives)** who need a dead-simple, highly legible, and stress-free interface.

![Tenera Senior-Friendly UI Mockup](/home/your/.gemini/antigravity/brain/59c42e5a-3086-4b80-a1de-032af4da34e7/tenera_senior_friendly_ui_1793081752668.jpg)

---

## 1. What Changed & Why (Senior-Centered UX)

| Previous Design | Senior-Friendly Revision | Why this helps older users |
| :--- | :--- | :--- |
| Complex financial terms (*"Arrears", "Occupancy Ratio"*) | Plain words: **"Collected"** vs **"Still Unpaid"** | No confusing accounting terminology. Answers "Did they pay me yet?" in 1 second. |
| 3 small stacked stat chips | **2 Large High-Contrast Cards** (Green for Paid, Warm Red for Unpaid) | High visual clarity with big fonts (28–32sp) readable without squinting or reading glasses. |
| Smaller action buttons | **Giant Gold Button**: `💰 Record Rent Payment` (*"Tap here when a tenant pays you"*) | Impossible to miss. Massive 56dp touch area designed for single-thumb tapping. |
| Small table rows | **Large Tenant Action Cards** with big 20sp names | Each card shows the tenant, their room, rent amount, and two clear buttons directly on the card. |
| Multi-step menus to remind | Direct **`[ 💬 Send Reminder ]`** button on each overdue card | Pre-fills a polite SMS/WhatsApp text with 1 tap. |

---

## 2. Walkthrough of the Revised Screen

### A. Friendly Greeting & Header
* Displays a calm, personal greeting (*"Good Morning, Maria"* or the landlord's name).
* Reassuring subtitle: *"My Rental Units"*.

### B. Two Big Status Cards (Traffic Light Simplicity)
1. 🟢 **COLLECTED (`₱35,000`)**:
   - Soft green background with a bold checkmark.
   - Tells the landlord their collected money at a glance.
2. 🔴 **STILL UNPAID (`₱9,000` · 2 Tenants)**:
   - Soft red background with a clear alert icon.
   - Instantly shows how many tenants have not paid yet.

### C. The Big "Record Payment" Action
* A giant amber/gold button (`#F2A33A`) centered on the screen:
  * **"💰 Record Rent Payment"**
  * Helpful helper text: *"Tap here when a tenant pays you"*.

### D. "Who Needs to Pay?" (Actionable Tenant Cards)
Instead of a crowded spreadsheet, each tenant who owes rent gets an uncluttered card:
* **Tenant Name**: Big bold text (e.g. **Juan Reyes**).
* **Location & Rent**: *"Room 3B · Rent: ₱5,000"*.
* **Status Badge**: Bright, high-contrast tag: `OVERDUE 3 DAYS` or `DUE TOMORROW`.
* **Two Big Action Buttons**:
  1. `[ 💬 Send Reminder ]`: Opens SMS/messenger with a polite message.
  2. `[ ✓ Received Payment ]`: Marks the rent as collected in one tap.

### E. Simplified 4-Tab Bottom Navigation
Keeps navigation dead-simple with large icons and clear text:
1. **Home** *(Today's collections & alerts)*
2. **My Tenants** *(Big searchable tenant list)*
3. **Payment Records** *(History of paid receipts)*
4. **App Settings** *(Backup database & privacy terms)*

---

## 3. Interaction & Accessibility Features
* **Minimum Touch Target**: 56dp (well above the 48dp standard) to prevent accidental taps.
* **Large Font Scale Support**: Built to dynamically scale up to 200% without breaking card layouts.
* **Zero Jargon**: Plain conversational language used everywhere.
