# Build Your Own Chief of Staff · Starter Prompts

**GRAYWING AG SYSTEMS · GEMINI ENTERPRISE WORKSHOP**

| | |
|---|---|
| Agent | Chief of Staff, plus five optional subagents |
| Platform | Gemini Enterprise, no-code agent builder |
| Data | Google Drive (read) · Gmail, Calendar, Docs, Slides, Sheets (act) |
| Date | November 16, 2026 |

## Overview

Build a Chief of Staff agent for Helen Marsh, CEO of Graywing Ag Systems, a made-up maker of grain dryers and elevators. It reads every department's files, tells Helen what matters across the company, and does the follow-up work: drafts the email, books the time, writes the brief. Get a first version working in about 10 minutes with the starter prompt, then spend the rest of the time making it better.

### Everything is in Google Drive

> All the data lives in one Drive folder, Graywing Ag Systems (Demo Data), in your My Drive, with one folder per department.
>
> The email and calendars are files in that folder too: each "Gmail (simulated)" folder holds the email threads as PDFs plus a Mailbox Index sheet, and each "Calendar (simulated)" folder holds a calendar sheet.
>
> Your own Gmail and Calendar are empty lab accounts, so the agent never reads Graywing facts from them. It uses them only to act: save a draft, add an event.
>
> Assume today is **Thursday, Oct 15, 2026**. Helen's exec staff meeting is Friday, Oct 23.

### Read from Drive, act with the real tools

| When you ask for… | The agent… |
|---|---|
| Facts, figures, emails, meetings | reads only the Graywing Ag Systems (Demo Data) folder in Drive |
| An email | saves a **Gmail draft** (it never sends unless you say "send") |
| A meeting or time block | creates a **Google Calendar** event |
| A memo or brief | creates a **Google Doc** |
| A deck | creates **Google Slides** |
| A tracker or table | creates a **Google Sheet** |
| Market, price or news context | uses **Google Search**, and says which facts came from the web and which from the files |

### Build it

1. In Gemini Enterprise: Agents → + New agent → Chat agent.
2. Paste the starter prompt below and send it. The builder drafts the name, description and instructions.
3. Data: Add data sources & tools → Google Drive. If you can pick a folder, pick Graywing Ag Systems (Demo Data). [VERIFY UI]
4. Actions: in the same place, add Gmail, Google Calendar, Google Docs, Google Slides and Google Sheets, and allow them when asked. [VERIFY UI] These are for actions only; the starter prompt keeps all facts coming from Drive.
5. Open Preview and ask the five questions below. For the last two, check your Gmail Drafts, your Calendar and your Drive for what the agent made.
6. Improve the answers with round 2 below, re-testing after each change.
7. Keep it as a draft unless your facilitator says to publish.

## Chief of Staff

**One answer across every department, for the CEO**
Works for: Helen Marsh, CEO · Folder: Graywing Ag Systems (Demo Data), every department folder

**STARTER PROMPT**

> Create an executive agent called Chief of Staff for Helen Marsh, CEO of Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read facts only from Google Drive, in the folder "Graywing Ag Systems (Demo Data)": the customer success, maintenance, sales, recruiting and finance folders inside it, including each team's email in "Gmail (simulated)" (thread PDFs and the Mailbox Index sheet) and calendars in "Calendar (simulated)". Never search my Gmail or Google Calendar for Graywing facts; they are empty. Use the other tools only to act when I ask: an email becomes a Gmail draft (never send unless I say "send"), a meeting becomes a Google Calendar event, a memo or brief becomes a Google Doc, a deck becomes Google Slides, a tracker or table becomes a Google Sheet; never Word or Excel. Use Google Search only for outside context such as markets, prices or news, and label it as outside context. Answer questions that cross departments: start with the bottom line in two sentences, then one short section per department, then how the departments' issues connect, then three to five next steps, each with an owner. Name the file behind every fact and never add figures the files don't contain.

Try these in Preview:

1. What should I raise at the next leadership meeting?
2. Where are we over budget, and what are we doing about it?
3. Which stalled deals and at-risk customers need my attention this week?
4. Draft an email from me to Bill Strand at Kettleridge Cooperative: I'll join Tuesday's renewal check-in myself, and here's where the Connect fix stands. Save it as a Gmail draft, and put a 30-minute prep block on my calendar for Monday, Oct 19, with no guests.
5. Put the agenda for Friday's exec staff meeting in a one-page Google Doc, then make a 3-slide Google Slides version.

A good first answer connects the Kettleridge renewal risk, September's budget overruns and the open field technician role. A good action leaves a draft in Gmail Drafts (not Sent) and a new Doc and deck in your Drive, and gives you the links.

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

## Round 3, if you have time

Google Search, image generation, Canvas and the model picker are turned on in the app for this lab. If one of them doesn't show inside your agent's Preview, try it in the main chat. [VERIFY UI]

1. **Outside context.** Ask: "What outside factors this fall bear on our steel surcharge and our harvest service load? Use Google Search for the market and the files for Graywing, and label which is which." Check that every Graywing number still comes from the files.
2. **A picture for the deck.** Ask for an image for the title slide of your exec staff deck: "a tower grain dryer at harvest dusk, no text or logos". Then put it on the first slide (from the chat if it offers that, otherwise download it and insert it in Slides). [VERIFY UI]
3. **Canvas.** Open Canvas [VERIFY UI] and ask for a one-page board memo on the Kettleridge renewal risk. Edit it there: shorter, plainer, a clear ask at the end. Then export it to Google Docs. [VERIFY UI]
4. **Compare models.** Pick a different model in the model picker [VERIFY UI] and ask question 1 again. Compare speed, length and accuracy against the answer key.
5. **Bring your own file.** Upload one of your own files to the My Uploads folder in your Drive (see the upload guide; use nothing confidential). Add My Uploads to the agent's Drive source [VERIFY UI] and add this line to its instructions: "Also read the folder My Uploads, and mark facts from it as (my upload)." Then ask: "Summarize my file in My Uploads in five bullets, then tell me which Graywing issue it most resembles and why."
6. **Swap Graywing for your business.** Rewrite the starter prompt for your own chief of staff: your folders, your meetings, the one cross-team question you wish you could answer on Monday morning.

## Go faster: add subagents

Chief of Staff can do everything on its own. Subagents make it faster and sharper: each one knows one department's folder well, and Chief of Staff asks the right ones in parallel and puts their answers together. Subagents only read; Chief of Staff does the actions.

**How:**

1. Create each subagent the same way as Chief of Staff (+ New agent), paste its prompt, and add Google Drive pointed at its one folder. No Gmail, Calendar or other tools.
2. Ask it its test question in Preview.
3. Open Chief of Staff and add the five as its subagents. [VERIFY UI]
4. Add this line to Chief of Staff's instructions: "For department facts, ask the matching subagents first, all in the same step, then combine their answers and name which subagent each fact came from."
5. Ask Chief of Staff: **"What is the Connect 5.2.0 problem costing us, and when does it stop?"** It should ask Churn Radar, Budget Watch and Talent Scout together and come back with one cause and one end date.

*CUSTOMER SUCCESS*

### Churn Radar

**Spots customers likely to leave, and why** · Rachel Kim, VP Customer Success · Folder: Churn Radar - Customer Success

> Create a customer success agent called Churn Radar for Rachel Kim, VP Customer Success at Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read only the Google Drive folder "Churn Radar - Customer Success" inside "Graywing Ag Systems (Demo Data)": the Customer Success Data sheet, the playbook, release notes and QBR notes in Documents, "Gmail (simulated)" and "Calendar (simulated)". Rank accounts by churn risk using the playbook's health score rules and give the evidence. Lead with the answer, name the file behind every fact, and never invent numbers.

Test: *Which accounts are most at risk of churning, and why?*

*OPERATIONS & MAINTENANCE*

### FieldFix

**Gets technicians to the safe fix fast** · Dale Hoffman, Maintenance & Field Service Supervisor · Folder: FieldFix - Operations & Maintenance

> Create a maintenance agent called FieldFix for Dale Hoffman, Maintenance & Field Service Supervisor at Graywing Ag Systems. Read only the Google Drive folder "FieldFix - Operations & Maintenance" inside "Graywing Ag Systems (Demo Data)": the Maintenance Data sheet, the Equipment Manuals and Safety & SOPs folders, and "Gmail (simulated)". Give safety steps first, then the procedure from the manual with the page number, the repair history and whether the parts are in stock. Never guess a procedure that isn't in the manuals.

Test: *Do we have plenum temperature sensors in stock?*

*REVENUE OPERATIONS*

### Deal Desk

**Shows why big deals stall** · Ryan Caldwell, Senior Account Executive · Folder: Deal Desk - Revenue Operations

> Create a sales agent called Deal Desk for Ryan Caldwell, Senior Account Executive at Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read only the Google Drive folder "Deal Desk - Revenue Operations" inside "Graywing Ag Systems (Demo Data)": the CRM Data sheet, the competitive landscape and pricing guide in Documents, the Call Notes, "Gmail (simulated)" and "Calendar (simulated)". Flag stalled deals using the stall rules and say which rules fired and why. Cite opportunity IDs, and never invent numbers or promise discounts.

Test: *Which deals are stalled, and why?*

*HUMAN RESOURCES*

### Talent Scout

**Screens applicants fairly and fast** · Erin Castillo, Talent Acquisition Manager · Folder: Talent Scout - Human Resources

> Create a recruiting agent called Talent Scout for Erin Castillo, Talent Acquisition Manager at Graywing Ag Systems. Assume today is Thursday, Oct 15, 2026. Read only the Google Drive folder "Talent Scout - Human Resources" inside "Graywing Ag Systems (Demo Data)": the Recruiting Data sheet, the Resumes and Job Descriptions folders, the hiring guidelines in Documents, "Gmail (simulated)" and "Calendar (simulated)". Report each open role's status and check candidates against the role's must-haves and location rule. Use job-related criteria only; you recommend and a person decides.

Test: *Where do we stand on each open role?*

*FINANCE*

### Budget Watch

**Explains where spending went over, and why** · Owen Mercer, FP&A Manager · Folder: Budget Watch - Finance

> Create a finance agent called Budget Watch for Owen Mercer, FP&A Manager at Graywing Ag Systems. Read only the Google Drive folder "Budget Watch - Finance" inside "Graywing Ag Systems (Demo Data)": the Finance Data sheet, the variance reporting policy in Documents, Variance Reports, Invoices & Notices, and "Gmail (simulated)". For a month, list every line more than 10% and more than $5,000 over budget, explain each with the transactions behind it, and say whether it is one-time or recurring and why. Lead with the bottom line and never estimate numbers.

Test: *Which overruns are recurring and which are one-time?*

*Graywing Ag Systems is a fictional company. All names, figures and documents are illustrative.*
