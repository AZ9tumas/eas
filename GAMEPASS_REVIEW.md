# 🎮 Gamepass Code Review Report

A thorough code audit of all 8 gamepasses — definitions, purchase handlers, gameplay integration, and client UI.

---

## Summary Table

| # | Gamepass | ID | Status | Severity |
|---|---------|-----|--------|----------|
| 1 | Starter Pack | `1676865684` | 🔴 **BUG** — Missing 100k cash reward | High |
| 2 | VIP Status | `1674447450` | ✅ Working | — |
| 3 | Unbreakable Button | `1673944119` | ✅ Working | — |
| 4 | Auto-Collect | `1674209886` | ⚠️ Minor concern | Low |
| 5 | Index Reader | `1683271610` | ✅ Working | — |
| 6 | Triple Hatch | `1674161903` | ⚠️ Partially disabled | Medium |
| 7 | Lucky Clover | `1674560397` | ✅ Working | — |
| 8 | Magic Shield (Perm) | `1674301793` | 🔴 **BUG** — Server-side protection disabled | High |

---

## Detailed Analysis

### 1. 🔴 Starter Pack (`1676865684`)

**Expected behavior:** Give the player an **Arcane Block** and **100,000 cash**.

**Current behavior:** Only gives the Arcane Block. **No cash is awarded.**

**File:** `src/ServerStorage/PurchaseHandlers/GamepassPurchaseHandlers.luau` (lines 31–35)

```lua
GamepassPurchaseHandlers["Starter Pack"] = function(player: Player, OnPurchase: boolean?)
    if OnPurchase then
        DataPlots.GiveEgg(player, "Arcane Block", "Pass")
    end
end
```

**Issue:** The handler calls `DataPlots.GiveEgg()` to give the Arcane Block, but there is no call to `DataCash.giveCash(player, 100000)` to grant the 100,000 cash component of the Starter Pack.

**Fix required:** Import `DataCash` and add `DataCash.giveCash(player, 100000, true)` inside the `if OnPurchase` block (using `true` for the `not_affected_by_multiplier` parameter so the starter pack gives exactly 100k, not a multiplied amount).

---

### 2. ✅ VIP Status (`1674447450`)

**Expected behavior:** Permanent boost to cash earnings and luck.

**Current behavior:** Working correctly.

**How it works:**
- **Cash multiplier:** In `DataCash.getCashMultiplier()` (line 36), adds `+0.5` (50%) to the cash multiplier when owned.
- **Luck multiplier:** In `DataPlots` (line 1664), adds `+0.5` to egg luck when owned.
- **Purchase handler:** Empty function (correct — the gamepass is checked by reading `profileData.Gamepasses["VIP Status"]` in gameplay code, no on-purchase action needed).

**No issues found.**

---

### 3. ✅ Unbreakable Button (`1673944119`)

**Expected behavior:** Prevents the spin button from breaking.

**Current behavior:** Working correctly.

**How it works:** In `DataPlots` (line 2856), when the button's break trigger fires, it checks `profileData.Gamepasses["Unbreakable Button"]`. If owned, the button does not break. If not owned, it applies the cooldown and marks the button as broken.

**Purchase handler:** Empty function (correct — checked at spin time).

**No issues found.**

---

### 4. ⚠️ Auto-Collect (`1674209886`)

**Expected behavior:** Automatically collects cash from slots without player interaction.

**Current behavior:** Functionally working, but collection interval is very long.

**How it works:** In `DataPlots` (line 888–894), a loop runs every **60 seconds**. If the player owns Auto-Collect, it calls `CollectCash()` for each Labubu slot.

```lua
while task.wait(60) do
    if profileData.Gamepasses["Auto-Collect"] then
        CollectCash()
    end
end
```

**Minor concern:** The 60-second interval is quite long. Players may still feel the need to manually collect between auto-collection cycles. This is a design choice rather than a bug. Also, a first-time collection only happens after 60s, not immediately upon joining.

**No blocking issues found.**

---

### 5. ✅ Index Reader (`1683271610`)

**Expected behavior:** Permanent income/CPS multiplier.

**Current behavior:** Working correctly.

**How it works:** In `DataPlots` (lines 869–870), the CPS calculation multiplies by `GlobalSettings.IndexReaderMultiplier` (set to `2` in `GlobalSettings.luau`) when the player owns this gamepass.

```lua
profileSlotData.Cash += PlotUtil.CalculateCPS(LabubuPlacement,
    profileData.CashMulti *
        (profileData.Gamepasses["Index Reader"] and
            GlobalSettings.IndexReaderMultiplier or 1)
)
```

**Purchase handler:** Empty function (correct — checked during CPS calculation).

**No issues found.**

---

### 6. ⚠️ Triple Hatch (`1674161903`)

**Expected behavior:** Reduces egg hatch time by 3x (hatch 3x faster).

**Current behavior:** Partially working — the hatch time is divided by 3 **only at initial placement** (line 3096–3099), but the **ongoing countdown tick does NOT use the Triple Hatch multiplier** (it is commented out at lines 710–717).

**At placement time (WORKING):** `DataPlots` lines 3096–3099:

```lua
local TripleHatchMultiplier = profileData.Gamepasses["Triple Hatch"]
    and 3 or 1
CloneEggData.HatchTimeLeft = math.floor(CloneEggData.HatchTimeLeft / TripleHatchMultiplier)
```

**During countdown tick (COMMENTED OUT):** `DataPlots` lines 710–717:

```lua
--local TripleHatchMultiplier = profileData.Gamepasses["Triple Hatch"]
--  and 3 or 1
-- ...
--* TripleHatchMultiplier)
```

**Assessment:** The initial HatchTimeLeft is divided by 3, which means the total time is correctly reduced. The tick code reduces `HatchTimeLeft` by 1 each second (or 2 with SuperSpeed). Since the starting time is already divided by 3, the **end result is correct** — hatching finishes in 1/3 of the normal time.

However, the commented-out code in the tick loop and the `⚠️⚠️⚠️⚠️⚠️⚠️` warning in the purchase handler suggest this gamepass may have had issues in the past or is flagged for review. The purchase handler is also empty (no on-purchase action), which is fine since the check happens at placement time.

**Recommendation:** Remove the ⚠️ warning comment or add a clarifying comment that Triple Hatch is handled at placement time, not tick time, to prevent future confusion.

---

### 7. ✅ Lucky Clover (`1674560397`)

**Expected behavior:** Permanent luck boost.

**Current behavior:** Working correctly.

**How it works:**
- **Server-side:** In `DataPlots` (line 1668), adds `+1` to egg luck multiplier when owned (or when `x2Luck` attribute is active).
- **Client-side:** `BoostsUI.luau` correctly tracks and displays the Lucky Clover boost icon when the gamepass is owned.

**Purchase handler:** Empty function (correct — checked at egg hatch/reward time).

**No issues found.**

---

### 8. 🔴 Magic Shield (Perm) (`1674301793`)

**Expected behavior:** Permanently protects the player's Labubus from being stolen/cloned by others.

**Current behavior:** **Server-side steal protection is COMMENTED OUT.** Only client-side UI prevention is active.

**Client-side (partially working):** In `Plots.luau` (line 202), the steal prompt is hidden when `MagicShield` attribute is set:

```lua
prompt.Enabled = not model:GetAttribute("IsMutating")
    and model:GetAttribute("IsStealable") and not player:GetAttribute("MagicShield")
```

**However**, this only prevents the *prompt from showing* on the client. It does NOT prevent an exploiter from firing the steal remote directly.

**Server-side (DISABLED):** In `DataPlots.HandleStealing()` (lines 1557–1559), the server-side Magic Shield check is **fully commented out**:

```lua
--if TargetProfileData.Gamepasses["Magic Shield (Perm)"] then
--    NotifyError:FireClient(player, "Can't steal, target has Magic Shield!", 8)
--    return
--end
```

**This means an exploiter can bypass the client-side prompt check and steal Labubus from a player who owns Magic Shield (Perm).** This is a security vulnerability.

**Purchase handler (working):** Sets `player:SetAttribute("MagicShield", true)` which is also periodically refreshed by the trait loop in `ProductPurchaseHandlers.luau` (lines 465–488). The attribute management is correct.

**Fix required:** Uncomment the server-side check in `DataPlots.HandleStealing()` to enforce Magic Shield protection server-side. Additionally, the check should also account for the temporary "Magic Shield (24h)" product by checking the `MagicShield` attribute:

```lua
local hasMagicShield = TargetBaseOwner:GetAttribute("MagicShield")
if hasMagicShield then
    NotifyError:FireClient(player, "Can't steal, target has Magic Shield!", 8)
    return
end
```

---

## Additional Observations

### Naming Inconsistency

- The problem statement refers to "**Tripple Hatch**" but the code uses "**Triple Hatch**" (correct spelling). No code issue here, just noting the discrepancy for clarity.

### Gifting Integration

- All 8 gamepasses are correctly registered in `Products/init.luau` as gifting products (`"Gifting | Pass | <name>"`)
- The gifting handler in `ProductPurchaseHandlers.luau` correctly calls `DataGamepasses.grantGamepass()` for gifted passes.

### Data Storage

- All gamepasses are correctly registered in:
  - `Types.luau` — `Types.Gamepasses` table (for profile data schema)
  - `Gamepasses/init.luau` — gamepass ID mapping
  - `DefaultData.luau` — references `Types.Gamepasses` for default `false` values
  - `DataGamepasses.luau` — validates all gamepasses have handlers and type entries on init

### Store UI

- The Store tab (`Store.luau`) only maps a subset of gamepasses to UI buttons. The `PURCHASE_MAP` includes:
  - `StarterPack` → Starter Pack
  - `Passes1/AutoCollect` → Auto-Collect
  - `Passes2/AutoCollect` → Lucky Clover
- Other gamepasses (VIP Status, Unbreakable Button, Index Reader, Triple Hatch, Magic Shield) are **not mapped** in the Store UI's `PURCHASE_MAP`. They may be purchasable through other UI elements (like the `GamepassButton` component) or may be missing from the store.

---

### Group Chest Reward (Fixed)

- The `GroupChestPrompt.luau` proximity prompt handler was **fully commented out** — the prompt on the GroupChestPart in each base's Floor1 did nothing.
- **Fixed:** Enabled the handler with group ID `784444031`. When triggered, it checks `player:IsInGroup(784444031)` and then calls `DataGroupRewards.claimGroupReward(player)`, which does an authoritative `IsInGroupAsync` check and rewards an exclusive Labubu via `DataPlots.GiveLabubuByRarity(player, "Exclusive", 1, "GroupReward")`.
- The UI-based claim path (GroupReward tab → "Verify" button → `Network.GroupRewards.Claimed` remote) was already working and uses `ReplicatedStorage.GroupID.Value` for the group ID.
- **Note:** Roblox does not provide a server-side API to verify whether a player has "liked" (favorited) the game. The `FavoritePrompt` system in `DataPrompts.luau` can prompt the player to favorite, but cannot verify completion. The game like requirement would need to be enforced through external means or treated as a soft/UI-only check.

---

## Bugs Summary — Action Items

| Priority | Gamepass | Issue | Fix |
|----------|---------|-------|-----|
| 🔴 High | **Starter Pack** | Missing 100k cash reward on purchase | Add `DataCash.giveCash(player, 100000, true)` in the purchase handler |
| 🔴 High | **Magic Shield** | Server-side steal protection is commented out — exploitable | Uncomment the server-side check in `DataPlots.HandleStealing()` using `TargetBaseOwner:GetAttribute("MagicShield")` |
| ✅ Fixed | **Group Chest Prompt** | Proximity prompt handler was commented out — group reward unreachable via prompt | Enabled with group ID `784444031` |
| ⚠️ Low | **Triple Hatch** | Warning emojis in handler suggest unresolved concern; code logic is correct | Clean up comments and remove ⚠️ warning |
| ℹ️ Info | **Auto-Collect** | 60s collection interval; first collection delayed | Consider reducing interval or adding immediate first collection |
