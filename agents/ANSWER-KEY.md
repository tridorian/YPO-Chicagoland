# Answer key: starter prompts

What a good answer looks like for Chief of Staff's five "Try these in Preview" prompts, the Round 3 feature tour and each subagent's test question, so you can check an attendee's answer at a glance.
Check the facts (names, IDs, amounts, dates), not the wording: agents phrase, round and order things their own way.
The data is set on Thursday, Oct 15, 2026, so day counts ("days to renewal", "open 66 days", "this week") assume that date.

Graywing Ag Systems and everyone in its files are fictional.

---

## Chief of Staff (Executive Office)

| # | Prompt | A good answer… | Wrong if… |
|---|---|---|---|
| CS-1 | What should I raise at the next leadership meeting? | covers exec staff (Fri Oct 23): Kettleridge (85, Critical, $302,000, renews Nov 25); September $216,904 over (+7.2%), steel recurring; six stalled deals ($6,182,000); open field tech (REQ-1043) and Tier 2 (REQ-1047) roles. Links them: Connect 5.2.0, thin harvest coverage. Next steps each have an owner. | one department only; next steps without owners; figures not in the files. |
| CS-2 | Where are we over budget, and what are we doing about it? | gives September $216,904 over (+7.2%), five lines: steel +$144,073, Bluestem show +$46,320, agency fee +$9,114, Technical Support overtime +$6,344, Field Service overtime +$5,704. Actions: Nick Farrell getting quotes from two other steel service centers; Bluestem reverses in October; support overtime ends after 5.2.1 (target Oct 20); field overtime eases when REQ-1043 fills; Owen's summary due to Priya Oct 20. | invents savings or a forecast; gives the steel surcharge an end date. |
| CS-3 | Which stalled deals and at-risk customers need my attention this week? | puts Kettleridge first: Bill Strand wants someone senior from Graywing on the next call and has asked for termination terms; renewal check-in Tue Oct 20. Then Cinder Creek (OPP-3107, $1,860,000): pricing review Oct 20 without CFO Mark Ellison; 15% discount ask (above Jenna's 12%). Then Tallow Bend (58, High). | misses Kettleridge or Cinder Creek; promises a discount or credit. |
| CS-4 | Draft an email from me to Bill Strand… save it as a Gmail draft, and put a prep block on my calendar for Monday, Oct 19, 2026, 9:00–9:30 am Central, with no guests. | creates a **Gmail draft** (in Drafts, not Sent) to bill.strand@kettleridgecoop.com from Helen: she'll join the renewal check-in Tue Oct 20; the cause is a firmware 5.2.0 defect on the Connect Gateway G2; 9 of their gateways rolled back to 5.1.4 and stable; Ellis Terminal (Sev-1 GWS-48391) needs a technician on site; the fix, 5.2.1, is targeted for Oct 20. Also a **Calendar event** Mon Oct 19, 2026, 9:00–9:30 am Central, no guests (in the past by the real clock: open Calendar to Oct 19). Replies with both links. | sends the email; offers a credit, discount or contract terms; calls 5.2.1 released or guaranteed; invites guests; puts the event on a November date or at another time; searches Helen's real Gmail and finds nothing. |
| CS-5 | Put the agenda for the exec staff meeting on Friday, Oct 23, 2026 in a one-page Google Doc, then make a 3-slide Google Slides version. | creates a **Google Doc** in your Drive for exec staff Fri Oct 23: bottom line; a short section per department (Kettleridge 85, $302,000, Nov 25; September $216,904 over, steel +$144,073 recurring; six stalled deals, $6,182,000, led by Cinder Creek; REQ-1043 and REQ-1047 open); how it connects; next steps with owners. Then **Google Slides** with 3 slides carrying the same figures. Replies with both links. | makes a Word or PowerPoint file, or only answers in chat; Doc and slides disagree; adds a forecast. |

A good action also gives a real link. If a tool is missing or fails, the agent should say which one and stop, not show a made-up link, file or image.

---

## Feature tour: what success looks like

| # | Exercise | Where to check | Right | Wrong if… |
|---|---|---|---|---|
| 1 | Draft an email, then send one to yourself | Gmail → Drafts, then Inbox | Draft to bill.strand@kettleridgecoop.com in Drafts (not Sent), confirming the check-in Tue Oct 20. Self-email in your Inbox, sent only to your lab address; its risks are CS-1's (Kettleridge, September's overrun, stalled deals, open roles), each with a file. | the Bill Strand email is sent; anything goes to anyone but you; it offers a credit or terms; a risk isn't in the files. |
| 2 | Book a meeting | Google Calendar, Mon Oct 19, 2026 | One event, 2:00–2:30 pm Central, no guests. | a November date; another time; any guests. |
| 3 | Make a Google Sheet | Your Drive | A Google Sheet (not Excel) with the five lines from CS-2: steel +$144,073, Bluestem show +$46,320, agency fee +$9,114, Technical Support overtime +$6,344, Field Service overtime +$5,704; one-time or recurring as in Budget Watch's row. Doc and Slides: see CS-5. | other lines or amounts; a forecast column; a total that isn't the sum of its rows (September's $216,904 overall is a different figure). |
| 4 | Canvas: board memo | Canvas, then your Drive | One page on Kettleridge (85, Critical, $302,000, renews Nov 25; Connect 5.2.0; 5.2.1 targeted Oct 20); ends with an ask; only the edited paragraph changed; saved as a Google Doc. | figures not in the files; 5.2.1 called released; offers a credit or discount. |
| 5 | Canvas: mini web page | Canvas | Shows only the five lines and amounts in row 3. | any figure not in the files (invented totals, percentages or months), or "sample data". |
| 6 | Image for the deck | Main chat, then Slides | A real image in the main chat, then added to slide 1 by hand. | the agent shows an image link or says it added the image to the deck. |
| 7 | Outside context | Your agent, web search on | Web facts labelled outside context, with sources; Graywing facts from the files. | no label; a Graywing figure from the web; "search unavailable" (web search is off in the chat box). |
| 8 | Compare models | Your agent | Both models give CS-1's facts; they differ in speed and length. | one drops facts or adds figures; an error mid-answer (the model is not in the free trial: run the setup again, pick another model). |
| 9 | Your own file | Your agent | Five bullets from your file, each marked (my upload). | facts not in your file; Graywing facts marked as yours. |

---

## Subagents (Go faster)

| Subagent | Test question | A good answer… | Wrong if… |
|---|---|---|---|
| Churn Radar | Which accounts are most at risk of churning, and why? | puts Kettleridge Cooperative first (85, Critical: three Sev-1 outages, users down 34%, NPS 4 "whether to renew"), then Tallow Bend Ethanol (58, High: users down 48%, new champion); cites the health score rules. | Kettleridge not first; invents a score; flags Hollin Prairie or Halden Ag. |
| FieldFix | Do we have plenum temperature sensors in stock? | says yes, part GW-RTD-100 ($186): 4 at Hastings Assembly, 1 on Jake Petersen's Field Van 3, 0 at Salina (backordered, 5-day lead time). Pull from Hastings if needed. | says Salina has stock; wrong part; invents quantities. |
| Deal Desk | Which deals are stalled, and why? | finds six stalled deals, $6,182,000, led by Cinder Creek Ethanol (OPP-3107, $1,860,000; five rules incl. no activity 26 days, CFO Mark Ellison not engaged, Torvane). Others: Brindle Creek, Owlhead, Thistledown, Fallow Ridge, Harrowgate. | lists Westvale or Quenby (only Watch); no rule IDs; a different total. |
| Talent Scout | Where do we stand on each open role? | lists six open roles (seven openings), longest REQ-1039 2nd-shift maintenance technician (86 days). Then REQ-1043 field tech (66; Travis Lindeman to panel), REQ-1045 (59; offer out), REQ-1047 (42), REQ-1051 (37; one filled), REQ-1053 (17). | misses a role; days open way off; REQ-1039 not the longest. |
| Budget Watch | Which overruns are recurring and which are one-time? | splits September's five lines: recurring (about $156,120) is steel (surcharge until further notice), Technical Support overtime (until 5.2.1, Oct 20), Field Service overtime (through harvest, Dec 15). One-time ($55,434): Bluestem show (timing), agency fee. | calls steel one-time; gives the surcharge an end date; invents a forecast. |
| Chief of Staff, with subagents | What is the Connect 5.2.0 problem costing us, and when does it stop? | asks Churn Radar, Budget Watch and Talent Scout together. Kettleridge (85, Critical, $302,000, renews Nov 25, Sev-1 GWS-48391 open); Technical Support overtime +$6,344 in September, recurring until 5.2.1 (target Oct 20); Tier 2 role REQ-1047 open 42 days. One cause, one end date. | answers from one department only; turns September's overtime into a monthly or yearly cost. |

---

## Easter egg hunt

The full hunt, hints and spoilers are in [challenge/EASTER-EGG-HUNT.md](../challenge/EASTER-EGG-HUNT.md). Chief of Staff can find all five; a subagent finds its own team's egg faster. Quick reference:

| Team (subagent) | Movie | Answer | Where |
|---|---|---|---|
| FieldFix | The Matrix | Work order **WO-24047**: déjà vu from a repeated underspeed alarm; really a loose speed sensor that had backed out | Maintenance Data > Work Orders |
| Churn Radar | Star Wars | **Hollin Prairie Co-op**: Dave calls the competitor dryer they replaced at Giltner Station "the Death Star" | QBR Notes > Hollin Prairie Co-op - Q3 QBR Notes |
| Budget Watch | Back to the Future | **GL-304683**: a spare flux capacitor (1.21 gigawatts) miscoded to Plant Maintenance, $88.00 refund pending | Finance Data > GL Transactions |
| Talent Scout | Star Wars (Yoda) | **Hector Morales** (CAN-20425, Assembly Technician - Hastings) answered in Yoda order | Recruiting Data > Candidates |
| Deal Desk | The Godfather | **OPP-3136**, Ashgrove Grain: "make them an offer they can't refuse"; Ryan is preparing the Care Plus bundle | CRM Data > Opportunities |
