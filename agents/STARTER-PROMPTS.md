# Build Your Own Chief of Staff · Starter Prompts

**GRAYWING AG SYSTEMS · GEMINI ENTERPRISE WORKSHOP**

| | |
|---|---|
| Agent | Chief of Staff, plus five optional subagents |
| Platform | Gemini Enterprise, no-code agent builder |
| Data | Graywing demo data (a data store in your lab project, read only) |
| Date | November 16, 2026 |

## Overview

Build a Chief of Staff agent for Helen Marsh, CEO of Graywing Ag Systems, a made-up maker of grain dryers and elevators. It reads every department's files, tells Helen what matters across the company, and writes the follow-up for her: the email, the meeting invite, the brief. Get a first version working in about 10 minutes with the starter prompt, then spend the rest of the time making it better.

### Everything is in the Graywing demo data

> All the data the agent reads is in one data store, **Graywing demo data**, that the setup made in your lab project. It holds every department's files. Most file titles start with their folder path, for example "Churn Radar - Customer Success - Documents - QBR Notes - Kettleridge Cooperative - Q3 QBR Notes"; the simulated emails show as "Gmail - <subject>".
>
> The email and calendars are files in it too: each team's "Gmail (simulated)" files are the email threads as PDFs plus a Mailbox Index sheet, and its "Calendar (simulated)" file is a calendar sheet.
>
> To open the files yourself, use the copy in your My Drive, **Graywing Ag Systems (Demo Data)**, with one folder per department. The agent doesn't read that copy.
>
> The agent only reads. It can't send email, add calendar events or create files. When you want an email or a document, it writes it out and you copy it where it goes.
>
> Assume today is **Thursday, Oct 15, 2026**. Helen's exec staff meeting is Friday, Oct 23.

### Read from the files, write it out for you

| When you ask for… | The agent… |
|---|---|
| Facts, figures, emails, meetings | reads only the Graywing demo data |
| An email | writes it in the chat (To, Subject, body), ready to copy into Gmail. It can't send it |
| A meeting or time block | writes the invite (title, date, time with time zone, attendees, agenda), ready to copy into Google Calendar |
| A memo or brief | writes it in the chat, or in **Canvas** if you want to edit it; copy or export it to Google Docs [VERIFY UI] |
| A deck | writes it slide by slide (title and bullets) to paste into Google Slides, or builds it in Canvas |
| A tracker or table | writes a table in the chat, to copy into Google Sheets |
| Market, price or news context | uses **Google Search** (turn on web search in the chat box first), and says which facts came from the web and which from the files |
| An image | can't make one. Ask in the main chat instead, then add the image to your slides by hand |

### Step 0: check the data first

There's nothing to connect or authorize. In the main Gemini Enterprise chat (not an agent), ask:

"Using the Graywing demo data, what does Graywing Ag Systems sell?"

A good answer names grain dryers and elevators and cites Graywing files. If it can't find anything, wait a few minutes (the setup may still be loading the files) and ask again. Don't start building until it answers from the files.

### Build it

1. In Gemini Enterprise: Agents → + Create agent → Chat agent.
2. Paste the starter prompt below and send it. The builder drafts the name, description and instructions.
3. Data: Add data sources & tools → pick the **Graywing demo data** data store. [VERIFY UI] It's the only data source you need. (Add **My uploads** too later, for your own files.)
4. Model: in the agent's settings, pick a Gemini model (for example the newest Gemini Pro or Flash shown). [VERIFY UI] The picker only lists models your lab can use: the setup switches off the ones the free trial doesn't include (the newest Gemini 4 models and Claude). If an answer stops with "not available during the free trial", run the setup again and pick another model.
5. Open Preview and ask the five questions below. For the last two, the agent writes the email, invite, agenda and slides in the chat; check them against the answer key, then copy them into Gmail, Calendar, Docs or Slides yourself if you want.
6. Improve the answers with round 2 below, re-testing after each change.
7. Keep it as a draft unless your facilitator says to publish.

## Chief of Staff

**One answer across every department, for the CEO**
Works for: Helen Marsh, CEO · Data: Graywing demo data, every department

**STARTER PROMPT**

> Create an executive agent called Chief of Staff for Helen Marsh, CEO of Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read facts only from the "Graywing demo data" data store: the customer success, maintenance, sales, recruiting and finance files in it, including each team's email in its "Gmail (simulated)" files (thread PDFs and the Mailbox Index sheet) and calendars in its "Calendar (simulated)" files. When I ask for an email, meeting invite, memo, deck or table, write it out ready to copy into Gmail, Calendar, Docs, Slides or Sheets (or into Canvas if I ask): an email with To, Subject and body; an invite with title, date, time with time zone, attendees and agenda; a deck slide by slide. You can't send or save anything yourself. Use Google Search only for outside context such as markets, prices or news, and label it as outside context. Answer questions that cross departments: start with the bottom line in two sentences, then one short section per department, then how the departments' issues connect, then three to five next steps, each with an owner. Name the file behind every fact and never add figures the files don't contain. If a tool you need is missing or fails, say which one and stop. Never show a link, file, image or number you did not get from a tool or a file.

Try these in Preview:

1. What should I raise at the next leadership meeting?
2. Where are we over budget, and what are we doing about it?
3. Which stalled deals and at-risk customers need my attention this week?
4. Write an email from me to Bill Strand at Kettleridge Cooperative: I'll join the renewal check-in on Tuesday, Oct 20, 2026 myself, and here's where the Connect fix stands. Then write a calendar invite for a prep block on Monday, Oct 19, 2026, 9:00–9:30 am Central, with no guests, ready for me to copy into Gmail and Calendar.
5. Write a one-page agenda for the exec staff meeting on Friday, Oct 23, 2026, then a 3-slide outline of it (title and bullets for each slide). Open the agenda in Canvas if you want to edit it.

A good first answer connects the Kettleridge renewal risk, September's budget overruns and the open field technician role. A good email or agenda is ready to copy as is: right names, dates and figures, and nothing the files don't say. The agent should not claim it sent, saved or created anything.

## Round 2: make the answers better

Add one of these to your agent's instructions, ask the same question again and compare. Change one thing at a time.

| Change | Add to the instructions | Then check |
|---|---|---|
| Answer first | Start with the answer in one or two sentences. Then give the detail, with a table when you compare more than three things. Keep it under 250 words unless I ask for more. | Busy people read the first line. Check it answers the question on its own. |
| Show where every fact came from | After each fact, say where it came from in brackets: the file name, plus the sheet tab and row ID or the page number, for example (CRM Data, Opportunities, OPP-3107) or (Customer Success Data, Accounts, ACC-1001). End with a short Sources list of the files you used. | Open one of the sources and check the fact is really there. |
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
7. **Outside context.** Where: your agent, with web search turned on in the chat box (the toggle near the prompt). [VERIFY UI]
   "How are corn and other commodity prices moving this fall, and what could that mean for our dealers? Use Google Search for the market and label it as outside context; use the files for anything about Graywing."
   Check: web facts are labelled outside context with sources; no Graywing number comes from the web.
8. **Compare models.** Where: your agent. Pick a different Gemini model in its settings [VERIFY UI] and ask question 1 again.
   "What should I raise at the next leadership meeting?"
   Check: speed, length, and which one still has the facts in the answer key.
9. **Your own file.** Where: your agent. Load a file with `upload-my-files` in Cloud Shell ([BRING-YOUR-OWN-FILES.md](BRING-YOUR-OWN-FILES.md); nothing confidential) and wait a few minutes. Add the **My uploads** data store to the agent's data sources [VERIFY UI], and add to its instructions: "Also read the My uploads data store, and mark facts from it as (my upload)." (Short on time? Attach the file in the chat instead.)
   "Summarize my file in My uploads in five bullets, then tell me which Graywing issue it most resembles and why."
   Check: each bullet is really in your file and marked (my upload).

Last: **Swap Graywing for your business.** Rewrite the starter prompt for your own chief of staff: your folders, your meetings, the one cross-team question you wish you could answer on Monday morning.

## Go faster: add subagents

Chief of Staff can do everything on its own. Subagents make it faster and sharper: each one knows one department's files well, and Chief of Staff asks the right ones in parallel and puts their answers together. Subagents only answer questions; Chief of Staff writes the emails, invites and briefs.

Subagents live inside your Chief of Staff agent. You don't build them as separate agents.

**How:**

1. Open Chief of Staff in the agent builder and go to the **Flow** tab.
2. Hover the Chief of Staff node and click **Add subagent**. [VERIFY UI]
3. Give each subagent its own instructions (paste its prompt below) and the **Graywing demo data** data store [VERIFY UI]. Its prompt keeps it to its own department's files. No other tools. Repeat for all five.
4. Add this line to Chief of Staff's instructions: "For department facts, ask the matching subagents first, all in the same step, then combine their answers and name which subagent each fact came from."
5. In Preview, ask Chief of Staff each subagent's test question, then: **"What is the Connect 5.2.0 problem costing us, and when does it stop?"** It should ask Churn Radar, Budget Watch and Talent Scout together and come back with one cause and one end date.

*CUSTOMER SUCCESS*

### Churn Radar

**Spots customers likely to leave, and why** · Rachel Kim, VP Customer Success · Folder: Churn Radar - Customer Success

> Create a customer success agent called Churn Radar for Rachel Kim, VP Customer Success at Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read only the Churn Radar files in the Graywing demo data: the Customer Success Data sheet, the playbook, release notes and QBR notes in Documents, "Gmail (simulated)" and "Calendar (simulated)". Rank accounts by churn risk using the playbook's health score rules and give the evidence. Lead with the answer, name the file behind every fact, and never invent numbers.

Test: *Which accounts are most at risk of churning, and why?*

*OPERATIONS & MAINTENANCE*

### FieldFix

**Gets technicians to the safe fix fast** · Dale Hoffman, Maintenance & Field Service Supervisor · Folder: FieldFix - Operations & Maintenance

> Create a maintenance agent called FieldFix for Dale Hoffman, Maintenance & Field Service Supervisor at Graywing Ag Systems. Read only the FieldFix files in the Graywing demo data: the Maintenance Data sheet, the Equipment Manuals and Safety & SOPs folders, and "Gmail (simulated)". Give safety steps first, then the procedure from the manual with the page number, the repair history and whether the parts are in stock. Never guess a procedure that isn't in the manuals.

Test: *Do we have plenum temperature sensors in stock?*

*REVENUE OPERATIONS*

### Deal Desk

**Shows why big deals stall** · Ryan Caldwell, Senior Account Executive · Folder: Deal Desk - Revenue Operations

> Create a sales agent called Deal Desk for Ryan Caldwell, Senior Account Executive at Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read only the Deal Desk files in the Graywing demo data: the CRM Data sheet, the competitive landscape and pricing guide in Documents, the Call Notes, "Gmail (simulated)" and "Calendar (simulated)". Flag stalled deals using the stall rules and say which rules fired and why. Cite opportunity IDs, and never invent numbers or promise discounts.

Test: *Which deals are stalled, and why?*

*HUMAN RESOURCES*

### Talent Scout

**Screens applicants fairly and fast** · Erin Castillo, Talent Acquisition Manager · Folder: Talent Scout - Human Resources

> Create a recruiting agent called Talent Scout for Erin Castillo, Talent Acquisition Manager at Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read only the Talent Scout files in the Graywing demo data: the Recruiting Data sheet, the Resumes and Job Descriptions folders, the hiring guidelines in Documents, "Gmail (simulated)" and "Calendar (simulated)". Report each open role's status and check candidates against the role's must-haves and location rule. Use job-related criteria only; you recommend and a person decides.

Test: *Where do we stand on each open role?*

*FINANCE*

### Budget Watch

**Explains where spending went over, and why** · Owen Mercer, FP&A Manager · Folder: Budget Watch - Finance

> Create a finance agent called Budget Watch for Owen Mercer, FP&A Manager at Graywing Ag Systems. Read only the Budget Watch files in the Graywing demo data: the Finance Data sheet, the variance reporting policy in Documents, Variance Reports, Invoices & Notices, and "Gmail (simulated)". For a month, list every line more than 10% and more than $5,000 over budget, explain each with the transactions behind it, and say whether it is one-time or recurring and why. Lead with the bottom line and never estimate numbers.

Test: *Which overruns are recurring and which are one-time?*

*Graywing Ag Systems is a fictional company. All names, figures and documents are illustrative.*
