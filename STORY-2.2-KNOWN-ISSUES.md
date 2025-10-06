# Story 2.2 - Known Visual Issues

## Issue: Small "Available" Block Border Overflow

**Status:** Deferred for later iteration

**Description:**
Small "Available" blocks (e.g., 9:45 AM - 10:00 AM, 15-minute duration) have dashed borders that slightly overflow their time boundaries, crossing into the next hour line (e.g., crossing the 10 AM line).

**Current Behavior:**
- Border extends ~1-2px beyond the calculated block height
- Most noticeable on very small blocks (<20px height)
- `.clipped()` modifier applied but border strokeBorder renders outside the clip bounds

**Root Cause:**
SwiftUI's `.strokeBorder()` renders the stroke on the edge of the shape, and with corner radius + clipping, some pixels overflow. The overlay border is applied after the frame is set, causing edge cases.

**Attempted Solutions:**
1. ✅ Z-index layering (empty blocks z:1, commitments z:0) - Partial success, borders visible
2. ✅ Reduced padding and min height (20px) - Improved compactness
3. ✅ `.clipped()` modifier - Did not fully resolve overflow
4. ❌ Need to investigate: Inset border, custom shape with stroke inside bounds, or adjusting block height calculation to account for border width

**Potential Solutions to Try:**
- Use `.stroke()` instead of `.strokeBorder()` with manual inset
- Subtract border width from block height calculation
- Custom Shape with `path(in rect:)` that draws border inside bounds
- Use `.padding(-1.5)` before border to create inset effect

**Priority:** Low - Visual polish, does not affect functionality

**Files Affected:**
- `TimelineView.swift` - commitmentBlocksView() method, lines ~110-165

**Testing:**
- Test with 15-minute blocks between commitments
- Verify on various device sizes and zoom levels
