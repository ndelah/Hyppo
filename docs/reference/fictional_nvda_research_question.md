# Research Question: ASML's Monopoly & High-NA EUV Adoption
**Asset**: ASML (Advanced Semiconductor Materials Lithography)

## Core Details
- **Research Question**: Will the transition to High-NA EUV lithography secure ASML's dominance and 20%+ earnings CAGR through 2030?
- **Context**: ASML is the sole provider of EUV (Extreme Ultraviolet) lithography machines. The next generation, High-NA (High Numerical Aperture), is significantly more expensive ($350M+ per unit) and complex. Success depends on TSMC, Intel, and Samsung finding it economically viable for 2nm nodes and beyond.
- **Thesis Statement**: ASML's High-NA EUV is the only viable path for Moore's Law progression. Despite high costs, the yield improvements and reduction in multi-patterning steps will make it the "standard" for leading-edge logic and DRAM, maintaining ASML's 100% market share in the most profitable segment of the WFE (Wafer Fab Equipment) market.
- **Confidence Level**: High (4/5)
- **Status**: Active

---

## 1. Main Assumptions (Top-Level Drivers)

### Driver 1: Technological Moat & High-NA Dominance
*   **Description**: Competitors (Nikon/Canon) are 10+ years behind in EUV technology. High-NA is the only way to achieve <2nm features without prohibitive multi-patterning costs.
*   **Validation Question**: Are there any emerging non-lithography technologies (e.g., directed self-assembly) that could bypass the need for High-NA?
*   **Data Sources**: Technical journals, patent filings, SPIE Advanced Lithography conference notes.
*   **Proof Threshold**: No viable alternative technology reaching pilot production for 2nm logic by 2026.

### Driver 2: Customer ROI & Adoption Velocity
*   **Description**: TSMC and Intel must see a clear cost-per-transistor benefit to justify the $380M price tag per High-NA machine.
*   **Validation Question**: Does High-NA reduce the number of masks/steps enough to offset its capital cost?
*   **Data Sources**: Intel "IDM 2.0" updates, TSMC earnings calls (specifically Capex guidance).
*   **Proof Threshold**: TSMC confirms High-NA insertion for their "A14" (1.4nm) node by 2027.

---

## 2. Sub-Assumptions (Sub-Drivers)

### Sub-Driver 1.1: Supply Chain Robustness (Under Driver 1)
*   **Description**: ASML depends on Zeiss for optics and TRUMPF for lasers. Any bottleneck here stalls the whole thesis.
*   **Validation Question**: Is Zeiss increasing lens production capacity fast enough for the 2025/26 ramp?
*   **Data Sources**: Zeiss annual reports, local German industrial news.
*   **Proof Threshold**: Zeiss confirms completion of "Werk 5" expansion on schedule.

### Sub-Driver 2.1: Service & Software Revenue Growth (Under Driver 2)
*   **Description**: As the installed base grows, high-margin service revenue should become a larger % of the mix.
*   **Validation Question**: Is service revenue growing faster than system sales?
*   **Data Sources**: ASML Quarterly Financials (Segment Reporting).
*   **Proof Threshold**: Service revenue CAGR > 12% over the next 3 years.

---

## 3. Kill Criteria (Invalidation Rules)

1.  **Condition**: TSMC officially delays High-NA adoption indefinitely in favor of "Double Patterning" with standard EUV.
    *   **Threshold**: Official announcement of "No High-NA for 2nm or 1.4nm".
    *   **Data Source**: TSMC Analyst Day / Quarterly Earnings.
2.  **Condition**: Gross Margin compression due to High-NA manufacturing complexity.
    *   **Threshold**: Overall Gross Margin drops below 49% for two consecutive quarters.
    *   **Data Source**: ASML Income Statement.
3.  **Condition**: Geopolitical Export Restrictions.
    *   **Threshold**: Dutch or US government bans the export of *standard* DUV immersion (not just EUV) to China, impacting >15% of total revenue.
    *   **Data Source**: Regulatory filings / Reuters.

---

## 4. Scenarios

- **Bull Case**: High-NA becomes the "gold standard" faster than expected; Intel regains process leadership using ASML tech; ASML hits €40B revenue by 2027.
- **Base Case**: Steady adoption of High-NA; China revenue remains stable despite restrictions; 15-18% EPS growth.
- **Bear Case**: High-NA is "too expensive"; customers stick to standard EUV for longer; chip glut leads to major capex cuts by 2026.

---

## 5. Driver Status Timeline

> Tracks how each driver's status evolves over the research lifecycle.
> Use this to verify the Conviction Health view renders correctly at each point in time.

| Date | Driver | Status Change | Trigger |
|---|---|---|---|
| Jan 25 | Driver 1 (Tech Moat) | → Pending | Initial setup |
| Jan 25 | Driver 2 (Customer ROI) | → Pending | Initial setup |
| Jan 25 | Sub-Driver 1.1 (Supply Chain) | → Pending | Initial setup |
| Jan 25 | Sub-Driver 2.1 (Service Revenue) | → Pending | Initial setup |
| Mar 15 | Sub-Driver 1.1 (Supply Chain) | → Needs Revision | Zeiss "Werk 5" delay report |
| Apr 15 | Driver 1 (Tech Moat) | → Confirmed | SPIE conference: no viable alt tech |
| May 15 | Sub-Driver 2.1 (Service Revenue) | → Confirmed | Q1 segment data shows 14% CAGR |
| Oct 15 | Sub-Driver 1.1 (Supply Chain) | → Discarded | Zeiss confirms 6-month delay |
| Nov 10 | Driver 2 (Customer ROI) | → Confirmed | TSMC confirms High-NA for A14 node |

---

## 6. Log Entries (Chronological Journal)

---

### Log Entry 1
- **Date**: Jan 25, 2026
- **Title**: Research Initiated — ASML High-NA Thesis
- **Type**: Observation
- **Confidence**: 4 (High)
- **Sentiment**: —
- **Source Type**: Note
- **Pinned**: Yes
- **Linked Driver**: —
- **Body**: Started the research case today. Initial focus is on the "High-NA ROI" driver. Reading Intel's latest whitepaper on their "18A" node which claims they are the first to receive a High-NA machine in Oregon. This is a strong supporting signal for Driver 2. Setting confidence at 4/5 given ASML's unassailable monopoly position — the key question is whether the economics work for customers, not whether the tech works.

---

### Log Entry 2
- **Date**: Feb 3, 2026
- **Title**: Intel "18A" Fab Tour Notes — Oregon
- **Type**: Observation
- **Confidence**: 4 (High)
- **Sentiment**: Supporting
- **Source Type**: Industry Report
- **Source URL**: https://example.com/intel-18a-fab-tour
- **Pinned**: No
- **Linked Driver**: Driver 2 (Customer ROI)
- **Body**: Attended a virtual presentation from Intel's Oregon fab. Key takeaway: Intel claims the High-NA machine reduces patterning steps from 5 to 2 for critical metal layers. If true, this dramatically changes the cost-per-transistor math. They also mentioned a target of 95%+ tool utilization within 6 months of install. This would be best-in-class. Filed under Driver 2 as supporting evidence — the ROI argument is getting stronger with every Intel update.

---

### Log Entry 3
- **Date**: Feb 10, 2026
- **Title**: ASML Q4 2025 Earnings Analysis
- **Type**: Update
- **Confidence**: 4 (High)
- **Sentiment**: Neutral
- **Source Type**: Earnings Call
- **Pinned**: No
- **Linked Driver**: Sub-Driver 2.1 (Service Revenue)
- **Body**: Listened to the full Q4 2025 earnings call. Revenue slightly beat at €7.2B. Gross margin came in at 51.8%, within guidance. Management reiterated their 2025–2030 outlook of €44–60B cumulative revenue. Notably, the service and management segment grew 11% YoY — tracking close to our 12% CAGR threshold but not yet exceeding it. The installed base management revenue is growing but needs another quarter or two of data to confirm the trend. No change in confidence.

---

### Log Entry 4
- **Date**: Feb 18, 2026
- **Title**: Intel IDM 2.0 Strategy Update — High-NA Commitment
- **Type**: Catalyst
- **Confidence**: 4 (High)
- **Sentiment**: Supporting
- **Source Type**: Management
- **Source URL**: https://example.com/intel-idm-2-strategy
- **Pinned**: Yes
- **Linked Driver**: Driver 2 (Customer ROI)
- **Body**: Intel's Pat Gelsinger reaffirmed at an investor event that Intel will order a second High-NA system for deployment at the Magdeburg fab (Germany) in 2027. He called it "the cornerstone of our 14A process." This is the first time Intel publicly committed to a *second* High-NA unit. Important because it signals the tool is meeting internal yield benchmarks — you don't order $380M machines for science experiments. Upgraded my internal view of Driver 2 from "plausible" to "likely."

---

### Log Entry 5
- **Date**: Mar 1, 2026
- **Title**: Export Control Risk — Dutch Government Consultation
- **Type**: Risk
- **Confidence**: 3 (Medium)
- **Sentiment**: Contradicting
- **Source Type**: News Article
- **Source URL**: https://example.com/dutch-export-controls-2026
- **Pinned**: No
- **Linked Driver**: — (Kill Criteria #3)
- **Body**: Reuters reports that the Dutch government is in "advanced consultation" with the US Commerce Department about potentially expanding export restrictions to include certain DUV immersion systems — not just EUV. If this materializes, it could impact ASML's China revenue which was ~27% of total in 2024. This is directly relevant to Kill Criteria #3 (threshold: >15% revenue impact). Downgrading confidence to 3/5 until we get more clarity. The technology thesis is intact but the geopolitical tail risk just got fatter.

---

### Log Entry 6
- **Date**: Mar 15, 2026
- **Title**: Zeiss Capacity Bottleneck — "Werk 5" Behind Schedule
- **Type**: Risk
- **Confidence**: 3 (Medium)
- **Sentiment**: Contradicting
- **Source Type**: News Article
- **Source URL**: https://example.com/zeiss-werk-5-delay
- **Pinned**: No
- **Linked Driver**: Sub-Driver 1.1 (Supply Chain)
- **Body**: German industrial trade publication Handelsblatt reports that Zeiss's "Werk 5" lens facility expansion is running approximately 3 months behind schedule due to cleanroom certification issues. This directly threatens the 2026 High-NA ramp timeline. ASML can build frames and lasers, but without Zeiss optics, machines don't ship. Marking Sub-Driver 1.1 as "Needs Revision" — the supply chain is not as robust as initially assumed. Need to monitor whether this is a 3-month blip or a structural constraint.

---

### Log Entry 7 (System-Generated)
- **Date**: Mar 15, 2026
- **Title**: Driver Status Changed: Supply Chain Robustness → Needs Revision
- **Type**: Update
- **System Generated**: Yes
- **Body**: Sub-Driver 1.1 (Supply Chain Robustness) status changed from Pending to Needs Revision. Previous evidence suggested on-schedule progress; new reporting indicates delays at Zeiss "Werk 5" facility.
- **Review Decision**: Hold / Revise (do not pass or buy)
- **Rationale**: The new evidence of a delay at Zeiss's "Werk 5" directly undermines the supply chain robustness assumption required for a greenlight decision. Based on the smoke test and review process, status should change to "Revise" and the case cannot be advanced or actioned (buy) at this step.
- **Reason for Change**: The previously documented on-schedule progress has been contradicted by credible industry reporting, introducing a material risk for the 2026 High-NA ramp. This must be reflected in the driver status and blocks the research question from being marked as "pass."
- **Review Notes**: Maintain watch; do not abandon unless the delay proves structural. Document and monitor for next check-in, but update the plan to require follow-up evidence on supply chain remediation before considering a positive decision.
---

### Log Entry 8
- **Date**: Mar 22, 2026
- **Title**: Periodic Review — Q1 Check-In
- **Type**: Review
- **Confidence**: 3 (Medium)
- **Sentiment**: —
- **Source Type**: Note
- **Pinned**: No
- **Linked Driver**: —
- **Body**: Q1 review of the thesis. Status: Mixed signals. Technology moat remains strong (Driver 1 unthreatened), but two concerns have emerged: (1) Zeiss supply chain delay creates a near-term execution risk, and (2) the Dutch export control consultations add a material tail risk. On the positive side, Intel's second High-NA order is a major supporting signal for Driver 2. Net effect: confidence reduced from 4 to 3. Action: Continue watching but do NOT enter a position until at least one of the risk factors resolves. Set next review for end of April.
- **Review Outcome**: Revise

---

### Log Entry 9
- **Date**: Apr 2, 2026
- **Title**: TSMC Q1 2026 Earnings — Massive Capex Guidance
- **Type**: Catalyst
- **Confidence**: 4 (High)
- **Sentiment**: Supporting
- **Source Type**: Earnings Call
- **Pinned**: Yes
- **Linked Driver**: Driver 2 (Customer ROI)
- **Body**: TSMC's Q1 earnings call was a game-changer. They guided capex of $38–42B for 2026, up from $32B in 2025. When asked directly about High-NA, C.C. Wei said: "We are evaluating High-NA for our N2P and A14 process nodes. The preliminary yield data is encouraging." This is the closest TSMC has ever come to confirming High-NA adoption. It's not the definitive "A14 will use High-NA" statement we need for Driver 2's proof threshold, but it's a strong directional signal. Confidence back up to 4/5.

---

### Log Entry 10
- **Date**: Apr 10, 2026
- **Title**: SPIE Advanced Lithography — No Viable EUV Alternatives
- **Type**: Observation
- **Confidence**: 4 (High)
- **Sentiment**: Supporting
- **Source Type**: Industry Report
- **Source URL**: https://example.com/spie-2026-litho-summary
- **Pinned**: No
- **Linked Driver**: Driver 1 (Tech Moat)
- **Body**: Reviewed proceedings from the 2026 SPIE Advanced Lithography & Patterning conference. Key finding: directed self-assembly (DSA) — the most promising non-lithography alternative — is still stuck at defect densities 100x too high for production. Nikon and Canon had zero papers on EUV development. The conference essentially confirmed that High-NA EUV is the *only game in town* for sub-2nm features. Marking Driver 1 as ready for confirmation — the proof threshold (no viable alt tech for 2nm by 2026) has been met.

---

### Log Entry 11 (System-Generated)
- **Date**: Apr 15, 2026
- **Title**: Driver Status Changed: Technological Moat → Confirmed
- **Type**: Update
- **System Generated**: Yes
- **Body**: Driver 1 (Technological Moat & High-NA Dominance) status changed from Pending to Confirmed. SPIE 2026 confirmed no alternative technology is viable for 2nm logic production. Nikon/Canon remain 10+ years behind in EUV.

---

### Log Entry 12
- **Date**: Apr 20, 2026
- **Title**: Export Control Update — DUV Restrictions Narrower Than Feared
- **Type**: Update
- **Confidence**: 4 (High)
- **Sentiment**: Supporting
- **Source Type**: News Article
- **Source URL**: https://example.com/dutch-export-update-april
- **Pinned**: No
- **Linked Driver**: — (Kill Criteria #3)
- **Body**: Breaking news: the Dutch government announced its new export control framework, and it is *narrower* than feared. Only the most advanced DUV immersion tools (TWINSCAN NXT:2100 and newer) are restricted. Older DUV systems — which make up the bulk of China orders — remain exportable. ASML's IR team estimates the impact at ~8% of 2026 revenue, well below our 15% kill threshold. Crisis averted for now, though the regulatory environment remains dynamic. Kill Criteria #3 not triggered.

---

### Log Entry 13
- **Date**: May 5, 2026
- **Title**: ASML Q1 2026 Earnings — High-NA Shipments Begin
- **Type**: Catalyst
- **Confidence**: 4 (High)
- **Sentiment**: Supporting
- **Source Type**: Earnings Call
- **Pinned**: No
- **Linked Driver**: Driver 2 (Customer ROI)
- **Body**: ASML reported Q1 2026 revenue of €7.8B, beating consensus by 4%. The headline: they shipped their second High-NA system (to Intel) and recognized revenue on it. Gross margin was 52.3% — *above* the standard EUV margin, which is a very bullish data point against Kill Criteria #2 (GM compression below 49%). Backlog remains at €39B. CEO Christophe Fouquet said: "Customer feedback on High-NA yield performance has exceeded our internal projections." This is the strongest signal yet.

---

### Log Entry 14
- **Date**: May 15, 2026
- **Title**: Service Revenue Deep Dive — Sub-Driver 2.1 Confirmed
- **Type**: Observation
- **Confidence**: 4 (High)
- **Sentiment**: Supporting
- **Source Type**: SEC Filing
- **Source URL**: https://example.com/asml-20f-2025-service
- **Pinned**: No
- **Linked Driver**: Sub-Driver 2.1 (Service Revenue)
- **Body**: Pulled the segment data from ASML's 20-F filing. Installed Base Management revenue for FY2025 was €6.1B, up from €5.4B in FY2024 — a 13% increase. Combined with Q1 2026 run-rate data suggesting continued acceleration, the 3-year CAGR is now tracking at ~14%, comfortably above our 12% threshold. Marking Sub-Driver 2.1 as Confirmed. The installed base flywheel is working.

---

### Log Entry 15 (System-Generated)
- **Date**: May 15, 2026
- **Title**: Driver Status Changed: Service Revenue Growth → Confirmed
- **Type**: Update
- **System Generated**: Yes
- **Body**: Sub-Driver 2.1 (Service & Software Revenue Growth) status changed from Pending to Confirmed. Service revenue CAGR of ~14% exceeds the 12% proof threshold.

---

### Log Entry 16
- **Date**: Jun 1, 2026
- **Title**: Samsung Foundry Pullback — Demand Concentration Risk
- **Type**: Risk
- **Confidence**: 4 (High)
- **Sentiment**: Contradicting
- **Source Type**: Analyst Report
- **Source URL**: https://example.com/samsung-foundry-pullback
- **Pinned**: No
- **Linked Driver**: Driver 2 (Customer ROI)
- **Body**: Bernstein published a note suggesting Samsung Foundry may delay its own High-NA tool order from 2027 to 2028 due to persistent yield issues on their 3nm GAA process. If Samsung pulls back, that leaves only TSMC and Intel as High-NA customers in the near term — increasing customer concentration risk. This doesn't invalidate the thesis (two customers is enough) but it narrows the adoption curve. Something to monitor but not thesis-breaking.

---

### Log Entry 17
- **Date**: Jun 10, 2026
- **Title**: Mid-Year Review — Thesis Strengthening
- **Type**: Review
- **Confidence**: 4 (High)
- **Sentiment**: —
- **Source Type**: Note
- **Pinned**: No
- **Linked Driver**: —
- **Body**: Mid-year review. The thesis is in the strongest shape since inception. Score: Driver 1 Confirmed, Driver 2 Pending but with very strong signals, Sub-Driver 2.1 Confirmed, Sub-Driver 1.1 still Needs Revision (Zeiss). No kill criteria triggered — export controls narrower than feared, gross margins *above* threshold, and TSMC has not rejected High-NA. The only drag is the Zeiss supply chain risk and Samsung's potential delay. Overall confidence: 4/5. I'm comfortable entering a position at current levels (~€750/share).
- **Review Outcome**: Reinforce

---

### Log Entry 18
- **Date**: Jul 5, 2026
- **Title**: Q2 Gross Margin Dip — Kill Criteria #2 Watch
- **Type**: Risk
- **Confidence**: 3 (Medium)
- **Sentiment**: Contradicting
- **Source Type**: Earnings Call
- **Pinned**: No
- **Linked Driver**: — (Kill Criteria #2)
- **Body**: ASML's Q2 preliminary results show gross margin of 49.5% — just barely above our 49% kill criteria threshold. The compression is attributed to High-NA learning curve costs and a mix shift toward China DUV (lower margin). Management guided for margin recovery in Q3 as High-NA production ramps. This is a yellow flag, not a red one, but it warrants close monitoring. If Q3 also comes in below 50%, the bull case for earnings growth gets much harder to make. Dropping confidence to 3/5 temporarily.

---

### Log Entry 19
- **Date**: Jul 15, 2026
- **Title**: Quarterly Review — Margin Concern
- **Type**: Review
- **Confidence**: 3 (Medium)
- **Sentiment**: —
- **Source Type**: Note
- **Pinned**: No
- **Linked Driver**: —
- **Body**: Review triggered by the margin dip. The technology thesis is rock-solid (Driver 1 confirmed), and customer adoption signals remain strong. But the near-term margin story is wobbly. High-NA learning curve costs and DUV mix shift to China are creating a temporary headwind. I need to see Q3 margins recover above 51% before I'm comfortable adding to the position. Current stance: HOLD, do not add. Next review after Q3 results.
- **Review Outcome**: Revise

---

### Log Entry 20
- **Date**: Aug 1, 2026
- **Title**: Zeiss Update — Partial Recovery
- **Type**: Update
- **Confidence**: 3 (Medium)
- **Sentiment**: Neutral
- **Source Type**: News Article
- **Source URL**: https://example.com/zeiss-update-august
- **Pinned**: No
- **Linked Driver**: Sub-Driver 1.1 (Supply Chain)
- **Body**: Zeiss provided an update at their investor day: the "Werk 5" facility is now 3 months delayed (down from an original 6-month feared delay). They expect to achieve full production capacity by Q1 2027. This is a slight improvement from March but still not on the original timeline. ASML has partially mitigated the bottleneck by sourcing some components from Zeiss's Oberkochen facility. Sub-Driver 1.1 remains in "Needs Revision" — better, but not resolved.

---

### Log Entry 21
- **Date**: Sep 5, 2026
- **Title**: US-Netherlands Joint Statement on Semiconductor Export Controls
- **Type**: Risk
- **Confidence**: 3 (Medium)
- **Sentiment**: Contradicting
- **Source Type**: News Article
- **Source URL**: https://example.com/us-nl-export-sept
- **Pinned**: Yes
- **Linked Driver**: — (Kill Criteria #3)
- **Body**: The US and Netherlands released a joint statement indicating they will "harmonize semiconductor equipment export controls" starting January 2027. The details are vague but the language is more aggressive than April's framework. Some analysts interpret this as a potential expansion to cover ALL DUV immersion systems. If that happens, ASML's China revenue could drop from ~22% to ~10% of total. This is within the 15% kill threshold range but uncomfortably close. The thesis is now under significant geopolitical pressure again.

---

### Log Entry 22
- **Date**: Oct 1, 2026
- **Title**: Q3 Margin Recovery — Kill Criteria #2 Cleared
- **Type**: Catalyst
- **Confidence**: 4 (High)
- **Sentiment**: Supporting
- **Source Type**: Earnings Call
- **Pinned**: No
- **Linked Driver**: — (Kill Criteria #2)
- **Body**: ASML Q3 results: Gross margin bounced back to 52.7%, well above the 49% kill criteria threshold. Management attributed the recovery to improved High-NA manufacturing yields and a better product mix (more EUV, less China DUV). The Q2 dip was indeed transitory. Kill Criteria #2 is firmly NOT triggered (would need two consecutive quarters below 49%; we had one at 49.5% and then a rebound). Confidence restored to 4/5.

---

### Log Entry 23
- **Date**: Oct 15, 2026
- **Title**: Zeiss Confirms 6-Month Delay — Sub-Driver 1.1 Discarded
- **Type**: Update
- **Confidence**: 4 (High)
- **Sentiment**: Contradicting
- **Source Type**: News Article
- **Source URL**: https://example.com/zeiss-6mo-delay-confirmed
- **Pinned**: No
- **Linked Driver**: Sub-Driver 1.1 (Supply Chain)
- **Body**: Zeiss's Q3 report confirms the "Werk 5" facility won't reach full capacity until mid-2027 — a full 6 months behind the original schedule. This means ASML will face lens supply constraints throughout 2027, potentially limiting High-NA shipments to 8–10 units vs. the 12–15 originally planned. I'm marking Sub-Driver 1.1 as Discarded — the supply chain is NOT robust enough for the 2025/26 ramp. However, this is a *timing* issue, not a *thesis* issue. The technology and demand are there; supply will catch up by 2028.

---

### Log Entry 24 (System-Generated)
- **Date**: Oct 15, 2026
- **Title**: Driver Status Changed: Supply Chain Robustness → Discarded
- **Type**: Update
- **System Generated**: Yes
- **Body**: Sub-Driver 1.1 (Supply Chain Robustness) status changed from Needs Revision to Discarded. Zeiss confirmed "Werk 5" will not achieve full capacity until mid-2027, a 6-month delay from original timeline.

---

### Log Entry 25
- **Date**: Nov 1, 2026
- **Title**: TSMC Confirms High-NA for A14 Node!
- **Type**: Catalyst
- **Confidence**: 5 (Very High)
- **Sentiment**: Supporting
- **Source Type**: Earnings Call
- **Pinned**: Yes
- **Linked Driver**: Driver 2 (Customer ROI)
- **Body**: The moment we've been waiting for. At TSMC's Q3 earnings call, C.C. Wei explicitly stated: "We have committed to inserting High-NA EUV lithography for our A14 process node, with volume production targeted for 2028." This is the definitive confirmation that meets Driver 2's proof threshold. The world's largest foundry has validated the economics of High-NA. Combined with Intel's already-committed orders, the adoption runway is now firmly established. Confidence upgraded to 5/5 — the highest since inception.

---

### Log Entry 26 (System-Generated)
- **Date**: Nov 10, 2026
- **Title**: Driver Status Changed: Customer ROI & Adoption → Confirmed
- **Type**: Update
- **System Generated**: Yes
- **Body**: Driver 2 (Customer ROI & Adoption Velocity) status changed from Pending to Confirmed. TSMC confirmed High-NA insertion for A14 node (1.4nm) targeting 2028 volume production, meeting the defined proof threshold.

---

### Log Entry 27
- **Date**: Nov 20, 2026
- **Title**: Annual Review — Thesis Validated
- **Type**: Review
- **Confidence**: 5 (Very High)
- **Sentiment**: —
- **Source Type**: Note
- **Pinned**: Yes
- **Linked Driver**: —
- **Body**: End-of-year review. The thesis has been substantially validated. Both top-level drivers are now Confirmed. Sub-Driver 2.1 (Service Revenue) Confirmed. Only Sub-Driver 1.1 (Supply Chain) was Discarded — a timing drag, not a thesis breaker. No kill criteria have been triggered. The Bear Case scenario (High-NA "too expensive") has been effectively ruled out by TSMC's commitment. Current trajectory points to the Base-to-Bull Case range.

**Summary of driver states:**
- Driver 1 (Tech Moat): Confirmed
- Driver 2 (Customer ROI): Confirmed
- Sub-Driver 1.1 (Supply Chain): Discarded
- Sub-Driver 2.1 (Service Revenue): Confirmed

**Kill Criteria Status:**
1. TSMC delay: NOT triggered (opposite occurred — TSMC confirmed)
2. Gross margin <49% for 2Q: NOT triggered (one quarter of 49.5%, then recovery)
3. Export controls >15%: NOT triggered (currently ~8% impact)

Confidence: 5/5. Thesis health: Strong.
- **Review Outcome**: Reinforce

---

### Log Entry 28
- **Date**: Jan 10, 2027
- **Title**: Export Controls Expanded — Reassessing Position
- **Type**: Risk
- **Confidence**: 3 (Medium)
- **Sentiment**: Contradicting
- **Source Type**: News Article
- **Source URL**: https://example.com/export-controls-jan-2027
- **Pinned**: No
- **Linked Driver**: — (Kill Criteria #3)
- **Body**: The January 2027 export control harmonization went into effect. The new rules restrict export of ALL DUV immersion systems manufactured after 2020. ASML's IR team estimates this will reduce China revenue from ~22% to ~8% of total — a ~14% revenue impact. This is just barely below our 15% kill criteria threshold, but the direction of travel is concerning. If the rules tighten further (and there's political pressure to do so), we could breach the threshold. Combined with the Zeiss supply delay limiting near-term High-NA shipments, the short-term outlook is cloudier even though the long-term thesis remains intact.

---

## 7. Decisions (Action Points)

---

### Decision 1 — Pass
- **Date**: Mar 7, 2026
- **Action**: Pass
- **Investment Phase**: Watching → Watching
- **Rationale**: The thesis has merit but two unresolved risks make it premature to enter: (1) the Dutch export control consultations create a material tail risk to China revenue, and (2) the Zeiss supply chain delay threatens the 2026 ramp timeline. Want to see at least one of these risks resolve before committing capital.
- **Confidence at Decision**: 3 (Medium)
- **Driver Snapshot**: 0 Confirmed, 4 Pending, 0 Discarded
- **What Would Change My Mind**: Dutch export controls finalized with <10% revenue impact AND/OR Zeiss confirms "Werk 5" back on track.

---

### Decision 2 — Buy
- **Date**: Jun 15, 2026
- **Action**: Buy
- **Investment Phase**: Watching → Entered
- **Rationale**: The thesis has strengthened materially since March. Driver 1 (Tech Moat) is Confirmed — no viable alternative exists. Export controls are narrower than feared (~8% revenue impact, below kill threshold). TSMC's capex guidance is a strong bullish signal for Driver 2. The remaining risks (Zeiss delay, Samsung pullback) are timing issues, not thesis breakers. Entering at €750/share.
- **Confidence at Decision**: 4 (High)
- **Driver Snapshot**: 1 Confirmed, 2 Pending, 0 Discarded (+ 1 Needs Revision)
- **Price at Decision**: €750
- **Expected Outcome**: ASML reaches €900–1000/share within 12 months as High-NA revenue ramp accelerates and TSMC formally commits to adoption.
- **Expected Timeframe**: 12 months
- **Exit Plan**: Exit if (a) any kill criteria triggered, (b) gross margin drops below 49% for two consecutive quarters, or (c) TSMC explicitly rejects High-NA.

---

### Decision 3 — Hold
- **Date**: Aug 20, 2026
- **Action**: Hold
- **Investment Phase**: Entered → Entered
- **Rationale**: Q2 margin dip to 49.5% was concerning but management guided for recovery. The thesis fundamentals haven't changed — still believe in the 12-month target. Not adding because of near-term uncertainty (margin + export controls), but not trimming because the technology thesis is confirmed and TSMC signals remain positive.
- **Confidence at Decision**: 3 (Medium)
- **Driver Snapshot**: 1 Confirmed, 1 Pending, 0 Discarded (+ 1 Needs Revision, + 1 Confirmed sub-driver)
- **Price at Decision**: €710

---

### Decision 4 — Add
- **Date**: Oct 5, 2026
- **Action**: Add
- **Investment Phase**: Entered → Entered
- **Rationale**: Q3 gross margin bounced back to 52.7%, clearing the margin concern. Kill Criteria #2 is definitively not triggered. The share price pulled back to €720 on general market weakness — this is a buying opportunity. Adding 30% to the existing position.
- **Confidence at Decision**: 4 (High)
- **Driver Snapshot**: 1 Confirmed, 1 Pending, 0 Discarded (+ 1 Needs Revision, + 1 Confirmed sub-driver)
- **Price at Decision**: €720
- **Expected Outcome**: Expect a re-rating once TSMC formally confirms High-NA adoption (our Driver 2 proof threshold).
- **Expected Timeframe**: 3–6 months

---

### Decision 5 — Trim
- **Date**: Jan 15, 2027
- **Action**: Trim
- **Investment Phase**: Entered → Entered
- **Rationale**: The expanded export controls (Jan 2027) pushed China revenue impact to ~14%, uncomfortably close to our 15% kill threshold. While the long-term thesis remains intact (all top-level drivers confirmed), the geopolitical risk is now structurally higher. Trimming 25% of position to reduce exposure while maintaining core holding.
- **Confidence at Decision**: 3 (Medium)
- **Driver Snapshot**: 2 Confirmed, 0 Pending, 1 Discarded (+ 1 Confirmed sub-driver)
- **Price at Decision**: €810

---

## 8. Confidence Timeline

> Tracks the overall confidence level over time. Use this to verify the confidence trend visualization.

| Date | Confidence | Direction | Trigger |
|---|---|---|---|
| Jan 25, 2026 | 4 (High) | — | Initial assessment |
| Mar 1 | 3 (Medium) | ↓ | Export control risk + Zeiss delay |
| Apr 2 | 4 (High) | ↑ | TSMC capex guidance |
| Jul 5 | 3 (Medium) | ↓ | Q2 margin dip |
| Oct 1 | 4 (High) | ↑ | Q3 margin recovery |
| Nov 1 | 5 (Very High) | ↑ | TSMC confirms High-NA for A14 |
| Jan 10, 2027 | 3 (Medium) | ↓ | Export controls expanded |

---

## 9. Kill Criteria Monitoring Log

> Tracks how close each kill criteria came to being triggered.

### Kill Criteria #1: TSMC Delays High-NA Indefinitely
- **Status**: NOT TRIGGERED
- **Closest Call**: Never — TSMC consistently signaled interest and ultimately confirmed.
- **Final Resolution**: Opposite occurred. TSMC committed to High-NA for A14 (Nov 2026).

### Kill Criteria #2: Gross Margin Below 49% for 2 Consecutive Quarters
- **Status**: NOT TRIGGERED
- **Closest Call**: Q2 2026 gross margin was 49.5% — only 50bps above threshold.
- **Q3 Recovery**: Margin bounced to 52.7%.
- **Peak Risk Date**: Jul 5, 2026.

### Kill Criteria #3: Export Controls Impact >15% of Revenue
- **Status**: NOT TRIGGERED (but close)
- **Closest Call**: January 2027 expansion pushed impact to ~14% — just 1% below threshold.
- **Trajectory**: Worsening. If further restrictions come, this could be triggered.
- **Peak Risk Date**: Jan 10, 2027.

---

## 10. Scenario Outcome Tracking

> Maps which scenario the thesis appears to be tracking toward.

| Date | Likely Scenario | Rationale |
|---|---|---|
| Jan 25, 2026 | Base Case | Starting position — steady adoption assumed |
| Apr 15 | Base → Bull | Driver 1 confirmed, Intel doubling down |
| Jun 15 | Bull Case | TSMC capex + Intel orders accelerate timeline |
| Jul 5 | Bull → Base | Margin dip clouds near-term earnings growth |
| Nov 1 | Bull Case | TSMC confirms; all drivers validated |
| Jan 10, 2027 | Bull → Base | Export controls add structural revenue drag |