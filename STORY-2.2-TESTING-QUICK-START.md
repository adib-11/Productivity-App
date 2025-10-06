# Story 2.2 - Quick Testing Guide

## 🚀 Quick Start (5 Minutes)

### 1. Launch App
```
In Xcode:
1. Select iPhone 15 Pro simulator
2. Press Cmd+R to build & run
3. Wait for app to launch
```

### 2. Sign In
- Create test account or use existing credentials
- Navigate to the Schedule/Timeline view

### 3. Quick Visual Check

**Test A: Empty Day (30 seconds)**
- If no commitments exist → Should see ONE gray dashed "Available" block
- Should span 6 AM to midnight

**Test B: Add One Commitment (1 minute)**
- Tap + to add commitment
- Title: "Test Meeting"
- Time: 10:00 AM - 11:00 AM
- Save
- **Expected:** 3 blocks appear:
  1. Gray "Available" 6 AM - 10 AM
  2. Blue "Test Meeting" 10 AM - 11 AM
  3. Gray "Available" 11:15 AM - midnight (note 15-min gap!)

**Test C: Visual Styling (30 seconds)**
- Empty blocks: Gray + dashed border
- Commitment blocks: Blue + solid border
- All text readable

### 4. Quick Pass/Fail Criteria

✅ **PASS if:**
- Gray dashed "Available" blocks appear
- 15-minute gaps are respected after commitments
- Blocks are in chronological order
- No crashes or errors

❌ **FAIL if:**
- No "Available" blocks show up
- Blocks overlap or have gaps
- App crashes when adding commitments
- Visual styling is missing

---

## 📋 Full Testing

For comprehensive testing, see: `STORY-2.2-MANUAL-TESTING-CHECKLIST.md`

---

## 🐛 Found a Bug?

Document in checklist with:
1. Steps to reproduce
2. Expected vs actual behavior
3. Screenshots if possible
4. Device/simulator info

---

**Good luck with testing!** 🎉
