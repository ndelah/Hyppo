## Testing Checklist
### 3. Markdown Export (Verify Still Working)
**From Research Question Detail:**
- [ ] Click Export button (square with arrow) in toolbar
- [ ] File save dialog appears with .md extension
- [ ] Saved file contains research question details, drivers, invalidation rules, scenarios
- [ ] If Pre-Mortem text exists, it should be included in export

### 4. Review Wizard (Verify Still Working)

**Access:**
- [ ] From Scenario Detail → Click "Review" (wand icon) in toolbar
- [ ] Review wizard opens

**Flow:**
- [ ] Overview step shows scenario summary
- [ ] Key Drivers step allows marking drivers as valid/invalid
- [ ] Invalidation Rules step allows marking rules as triggered
- [ ] Outcome step suggests appropriate outcome based on assessments
- [ ] Summary step shows preview of review log
- [ ] Complete creates a review log entry

### 5. Edge Cases to Test

- [ ] Global Search with no data in app → Shows empty state gracefully
- [ ] Global Search with special characters in search text
- [ ] Pre-Mortem with very long text (500+ characters)
- [ ] Multiple scenarios with same title → Both appear in search
- [ ] Archived assets → Should they appear in Global Search? (Current: yes)

---



- [  ] How should we manage research confidence? Right now we add confidence to logs and to the research question. This doesn’t make a whole lot of sene.
