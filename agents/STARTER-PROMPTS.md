# Build Your Own Chief of Staff · Starter Prompts

**GRAYWING AG SYSTEMS · GEMINI ENTERPRISE WORKSHOP**

| | |
|---|---|
| Agent | Chief of Staff, plus five optional subagents |
| Platform | Gemini Enterprise, no-code agent builder |
| Data | Your Google Drive: the **Graywing Ag Systems (Demo Data)** folder the setup copied there (the agent reads only) |
| Date | November 16, 2026 |

## Overview

Build a Chief of Staff agent for Helen Marsh, CEO of Graywing Ag Systems, a made-up maker of grain dryers and elevators. It reads every department's files, tells Helen what matters across the company, and writes the follow-up for her: the email, the meeting invite, the brief. Get a first version working in about 10 minutes with the starter prompt, then spend the rest of the time making it better.

### Everything is in your Google Drive

> All the data the agent reads is in one Drive folder, **Graywing Ag Systems (Demo Data)**, that the setup copied into your My Drive. It has one folder per department, for example "Churn Radar - Customer Success". Every answer links to the Drive file it came from, so you can click through and check.
>
> The email and calendars are files there too: each team's "Gmail (simulated)" folder holds the email threads as PDFs plus a Mailbox Index sheet, and its "Calendar (simulated)" folder holds a calendar sheet.
>
> The agent's only data source is **Google Drive**. Google Search and the lab's data stores stay off, so every fact comes from the Graywing files.
>
> The agent only reads. It doesn't send email, add calendar events, or create or change files. When you want an email or a document, it writes it out and you copy it where it goes.
>
> Assume today is **Thursday, Oct 15, 2026**. Helen's exec staff meeting is Friday, Oct 23.

### Read from the files, write it out for you

| When you ask for… | The agent… |
|---|---|
| Facts, figures, emails, meetings | reads only the Graywing folder in your Drive, and links to each file it used |
| An email | writes it in the chat (To, Subject, body), ready to copy into Gmail. It can't send it |
| A meeting or time block | writes the invite (title, date, time with time zone, attendees, agenda), ready to copy into Google Calendar |
| A memo or brief | writes it in the chat, or in **Canvas** if you want to edit it; copy or export it to Google Docs [VERIFY UI] |
| A deck | writes it slide by slide (title and bullets) to paste into Google Slides, or builds it in Canvas |
| A tracker or table | writes a table in the chat, to copy into Google Sheets |
| Market, price or news context | can't look it up: Google Search is off for the agent. Ask in the main chat instead (round 3, exercise 7) |
| An image | can't make one. Ask in the main chat instead, then add the image to your slides by hand |

### Step 0: connect Google Drive and check the data

1. In the Gemini Enterprise app, open **Connectors** and click **Authorize** on **Google Drive** [VERIFY UI]. Sign in with your lab account (it starts with `student-`) and allow access. If it says "Data connector is not ready yet", wait a few minutes, refresh the page and try again.
2. In the main chat (not an agent), ask: "List three files in my Drive folder Graywing Ag Systems (Demo Data)."

A good answer names three Graywing files, each a link that opens it in Drive. Don't start building until this works.

**Authorize won't work?** Use the **Graywing demo data** data store instead: the same files, with no sign-in, but its sources aren't clickable links. Give the agent that data store in place of Google Drive, and in every prompt below replace `the "Graywing Ag Systems (Demo Data)" folder in my Google Drive` with `the "Graywing demo data" data store`.

### Build it

1. In Gemini Enterprise: Agents → + Create agent → Chat agent.
2. Paste the starter prompt below and send it. The builder drafts the name, description and instructions.
3. Data: Add data sources & tools → add **Google Drive**. [VERIFY UI] It's the agent's only data source:
   - turn **Google Search** off [VERIFY UI];
   - leave the data stores (**Graywing demo data**, **My uploads**) off. Your own files go in Drive too (exercise 9).
4. Model: in the agent's settings, pick a Gemini model (for example the newest Gemini Pro or Flash shown). [VERIFY UI] The picker only lists models your lab can use: the setup switches off the ones the free trial doesn't include (the newest Gemini 4 models and Claude). If an answer stops with "not available during the free trial", run the setup again and pick another model.
5. Open Preview and ask the five questions below. For the last two, the agent writes the email, invite, agenda and slides in the chat; check them against the answer key, then copy them into Gmail, Calendar, Docs or Slides yourself if you want.
6. Improve the answers with round 2 below, re-testing after each change.
7. Keep it as a draft unless your facilitator says to publish.

## Chief of Staff

**One answer across every department, for the CEO**
Works for: Helen Marsh, CEO · Data: Google Drive, the Graywing folder, every department

**STARTER PROMPT**

> Create an executive agent called Chief of Staff for Helen Marsh, CEO of Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read facts only from the "Graywing Ag Systems (Demo Data)" folder in my Google Drive: the customer success, maintenance, sales, recruiting and finance folders in it, including each team's email in its "Gmail (simulated)" folder (thread PDFs and the Mailbox Index sheet) and calendar in its "Calendar (simulated)" folder. Only read Drive: never create, change, move, share or delete a file. When I ask for an email, meeting invite, memo, deck or table, write it out ready to copy into Gmail, Calendar, Docs, Slides or Sheets (or into Canvas if I ask): an email with To, Subject and body; an invite with title, date, time with time zone, attendees and agenda; a deck slide by slide. You can't send or save anything yourself. Don't use the web. Answer questions that cross departments: start with the bottom line in two sentences, then one short section per department, then how the departments' issues connect, then three to five next steps, each with an owner. Back every fact with a clickable link to the Drive file it came from, and end each answer with a Sources list of those links. Never add figures the files don't contain. If a tool you need is missing or fails, say which one and stop. Never show a link, file, image or number you did not get from a tool or a file.

Try these in Preview:

1. What should I raise at the next leadership meeting?
2. Where are we over budget, and what are we doing about it?
3. Which stalled deals and at-risk customers need my attention this week?
4. Write an email from me to Bill Strand at Kettleridge Cooperative: I'll join the renewal check-in on Tuesday, Oct 20, 2026 myself, and here's where the Connect fix stands. Then write a calendar invite for a prep block on Monday, Oct 19, 2026, 9:00–9:30 am Central, with no guests, ready for me to copy into Gmail and Calendar.
5. Write a one-page agenda for the exec staff meeting on Friday, Oct 23, 2026, then a 3-slide outline of it (title and bullets for each slide). Open the agenda in Canvas if you want to edit it.

A good first answer connects the Kettleridge renewal risk, September's budget overruns and the open field technician role, and every fact has a link you can click to open its file in Drive. A good email or agenda is ready to copy as is: right names, dates and figures, and nothing the files don't say. The agent should not claim it sent, saved or created anything.

## Round 2: make the answers better

Add one of these to your agent's instructions, ask the same question again and compare. Change one thing at a time.

| Change | Add to the instructions | Then check |
|---|---|---|
| Answer first | Start with the answer in one or two sentences. Then give the detail, with a table when you compare more than three things. Keep it under 250 words unless I ask for more. | Busy people read the first line. Check it answers the question on its own. |
| Show where every fact came from | After each fact, say where it came from in brackets: the file name linked to the file in Drive, plus the sheet tab and row ID or the page number, for example (CRM Data, Opportunities, OPP-3107) or (Customer Success Data, Accounts, ACC-1001). End with a short Sources list of the files you used. | Open one of the sources and check the fact is really there. |
| Say when the files don't know | If the files don't answer the question, say "Not in the files" and what information would answer it. Never estimate or invent a number, name or date. | Ask something the files can't answer and see what it does. |
| Show the working | When you give a total or percentage, show the parts that add up to it and the rule you used. | Recalculate one by hand. Does it match? |
| End with a next step | End every answer with one recommended next step: who should do what, and by when if the files give a date. | Is it something a person could act on today? |
| Put your own rule in | Use this rule: [write your business rule with a number, for example "treat any customer renewing within 60 days with a health score of 55 or more as a CEO issue" or "flag any deal over $1,000,000 with no activity in 14 days"]. | Ask again. Does the answer follow your rule instead of the old one? |

## Round 3: feature tour

One prompt each. **Where** says where to paste it; **Check** says what to look for. Dates are written out in full because the real clock (November) and the data's "today" (Oct 15, 2026) differ. Right answers are in the answer key.

1. **Write an email, then send one to yourself.** Where: your Chief of Staff agent.
   "Write a short email from me to Bill Strand at Kettleridge Cooperative confirming I'll join the renewal check-in on Tuesday, Oct 20, 2026. Give me the To, Subject and body."
   Then: "Write an email to me listing the three biggest risks across Graywing this week, one line each with the file behind it."
   Check: both have To, Subject and body, and the agent doesn't claim it sent anything. Copy the second into Gmail and send it to your own lab address only.
2. **Write a meeting invite.** Where: your agent.
   "Write a calendar invite for a Cinder Creek pricing review prep on Monday, Oct 19, 2026, 2:00–2:30 pm Central, with no guests: title, date, time with time zone, and a three-line agenda."
   Check: exactly that date and time, Central time, no guests, and the agenda facts are in the files. Copy it into Google Calendar if you want (open Calendar to Oct 19, 2026; the real clock is in November).
3. **Make a table for Sheets.** Where: your agent.
   "Make a table of September's over-budget lines: the line, the amount over budget, one-time or recurring, and the file behind it. I'll copy it into Google Sheets."
   Check: the five lines and amounts match the files. Copy it into a new Google Sheet if you want. (Agenda and slides: that's question 5.)
4. **Canvas: board memo.** Where: Canvas, opened from the chat box. [VERIFY UI]
   "Draft a one-page board memo on the Kettleridge renewal risk, using only facts from the Graywing files. End with a clear ask."
   Then edit one paragraph there (shorter, plainer) and export or copy it to Google Docs. [VERIFY UI]
   Check: every figure is in the files; only your paragraph changed; it lands in your Drive as a Doc.
5. **Canvas: a mini web page.** Where: Canvas. First copy the over-budget table your agent gave you (question 2 or exercise 3).
   "Build a one-page web dashboard of September's five over-budget lines, using only the figures from the files. Use only these numbers: [paste the table]."
   Check: every number against the answer key. Without the table, the builder makes numbers up.
6. **An image for the deck.** Where: the main chat, not your agent (the agent can't make images and may invent a link).
   "Make an image for a title slide: a tower grain dryer at harvest dusk, no text or logos."
   Check: a real image shows in the chat. Download it; if you pasted question 5's slides into Google Slides, add it to the first slide by hand.
7. **Outside context.** Where: the main chat, not your agent (Google Search is off in the agent, so its answers stay in the files). Turn on web search in the chat box (the toggle near the prompt). [VERIFY UI]
   "How are corn and other commodity prices moving this fall, and what could that mean for grain-equipment dealers in the Midwest? Label every fact with its web source."
   Check: each fact has a web source. Bring anything useful back to your agent yourself; the agent never mixes web facts into Graywing figures.
8. **Compare models.** Where: your agent. Pick a different Gemini model in its settings [VERIFY UI] and ask question 1 again.
   "What should I raise at the next leadership meeting?"
   Check: speed, length, and which one still has the facts in the answer key.
9. **Your own file.** Where: your agent. Drag a file into the **My Uploads** folder in your Drive (the link is in the setup's green box; see [BRING-YOUR-OWN-FILES.md](BRING-YOUR-OWN-FILES.md); nothing confidential). Add to the agent's instructions: "Also read the My Uploads folder in my Drive, and mark facts from it as (my upload)." No new data source is needed: it's already Google Drive. (Short on time? Attach the file in the chat instead.)
   "Summarize my file in the My Uploads folder in five bullets, then tell me which Graywing issue it most resembles and why."
   Check: each bullet is really in your file, marked (my upload), with a link to your file.

Last: **Swap Graywing for your business.** Rewrite the starter prompt for your own chief of staff: your folders, your meetings, the one cross-team question you wish you could answer on Monday morning.

## Go faster: add subagents

Chief of Staff can do everything on its own. Subagents make it faster and sharper: each one knows one department's files well, and Chief of Staff asks the right ones in parallel and puts their answers together. Subagents only answer questions; Chief of Staff writes the emails, invites and briefs.

Subagents live inside your Chief of Staff agent. You don't build them as separate agents.

**How:**

1. Open Chief of Staff in the agent builder and go to the **Flow** tab.
2. Hover the Chief of Staff node and click **Add subagent**. [VERIFY UI]
3. Give each subagent its own instructions (paste its prompt below) and **Google Drive** as its only data source, with Google Search off [VERIFY UI]. Its prompt keeps it to its own department's folder. No other tools. Repeat for all five.
4. Add this line to Chief of Staff's instructions: "For department facts, ask the matching subagents first, all in the same step, then combine their answers, name which subagent each fact came from and keep its Drive link."
5. In Preview, ask Chief of Staff each subagent's test question, then: **"What is the Connect 5.2.0 problem costing us, and when does it stop?"** It should ask Churn Radar, Budget Watch and Talent Scout together and come back with one cause and one end date.

*CUSTOMER SUCCESS*

### Churn Radar

**Spots customers likely to leave, and why** · Rachel Kim, VP Customer Success · Folder: Churn Radar - Customer Success

> Create a customer success agent called Churn Radar for Rachel Kim, VP Customer Success at Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read only the "Churn Radar - Customer Success" folder inside "Graywing Ag Systems (Demo Data)" in my Google Drive, and never change a file: the Customer Success Data sheet, the playbook, release notes and QBR notes in Documents, "Gmail (simulated)" and "Calendar (simulated)". Rank accounts by churn risk using the playbook's health score rules and give the evidence. Lead with the answer, link the Drive file behind every fact, and never invent numbers.

Test: *Which accounts are most at risk of churning, and why?*

*OPERATIONS & MAINTENANCE*

### FieldFix

**Gets technicians to the safe fix fast** · Dale Hoffman, Maintenance & Field Service Supervisor · Folder: FieldFix - Operations & Maintenance

> Create a maintenance agent called FieldFix for Dale Hoffman, Maintenance & Field Service Supervisor at Graywing Ag Systems. Read only the "FieldFix - Operations & Maintenance" folder inside "Graywing Ag Systems (Demo Data)" in my Google Drive, and never change a file: the Maintenance Data sheet, the Equipment Manuals and Safety & SOPs folders, and "Gmail (simulated)". Give safety steps first, then the procedure from the manual with the page number, the repair history and whether the parts are in stock. Link the Drive file behind every fact, and never guess a procedure that isn't in the manuals.

Test: *Do we have plenum temperature sensors in stock?*

*REVENUE OPERATIONS*

### Deal Desk

**Shows why big deals stall** · Ryan Caldwell, Senior Account Executive · Folder: Deal Desk - Revenue Operations

> Create a sales agent called Deal Desk for Ryan Caldwell, Senior Account Executive at Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read only the "Deal Desk - Revenue Operations" folder inside "Graywing Ag Systems (Demo Data)" in my Google Drive, and never change a file: the CRM Data sheet, the competitive landscape and pricing guide in Documents, the Call Notes, "Gmail (simulated)" and "Calendar (simulated)". Flag stalled deals using the stall rules and say which rules fired and why. Cite opportunity IDs, link the Drive file behind every fact, and never invent numbers or promise discounts.

Test: *Which deals are stalled, and why?*

*HUMAN RESOURCES*

### Talent Scout

**Screens applicants fairly and fast** · Erin Castillo, Talent Acquisition Manager · Folder: Talent Scout - Human Resources

> Create a recruiting agent called Talent Scout for Erin Castillo, Talent Acquisition Manager at Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read only the "Talent Scout - Human Resources" folder inside "Graywing Ag Systems (Demo Data)" in my Google Drive, and never change a file: the Recruiting Data sheet, the Resumes and Job Descriptions folders, the hiring guidelines in Documents, "Gmail (simulated)" and "Calendar (simulated)". Report each open role's status and check candidates against the role's must-haves and location rule. Link the Drive file behind every fact. Use job-related criteria only; you recommend and a person decides.

Test: *Where do we stand on each open role?*

*FINANCE*

### Budget Watch

**Explains where spending went over, and why** · Owen Mercer, FP&A Manager · Folder: Budget Watch - Finance

> Create a finance agent called Budget Watch for Owen Mercer, FP&A Manager at Graywing Ag Systems. Read only the "Budget Watch - Finance" folder inside "Graywing Ag Systems (Demo Data)" in my Google Drive, and never change a file: the Finance Data sheet, the variance reporting policy in Documents, Variance Reports, Invoices & Notices, and "Gmail (simulated)". For a month, list every line more than 10% and more than $5,000 over budget, explain each with the transactions behind it, and say whether it is one-time or recurring and why. Lead with the bottom line, link the Drive file behind every fact, and never estimate numbers.

Test: *Which overruns are recurring and which are one-time?*

*Graywing Ag Systems is a fictional company. All names, figures and documents are illustrative.*
