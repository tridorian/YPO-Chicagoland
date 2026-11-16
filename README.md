# Graywing Ag Systems · Gemini Enterprise lab

Everything you need to set up a Gemini Enterprise app over the demo data for **Graywing Ag Systems**, build your own no-code **Chief of Staff** agent, and check its answers. Graywing is a fictional agriculture-equipment company; all names, numbers and documents are made up.

## What's in this repo

| File | What it is |
|---|---|
| `graywing-demo-data.zip` | The demo data: 124 files (spreadsheets, documents, manuals, simulated email and calendar printouts, test photos) in one folder per team. The setup script downloads this file; nothing else in the repo is part of the data. |
| `setup/PASTE-INTO-CLOUD-SHELL.txt` | The setup script, ready to paste into Cloud Shell. |
| `setup/graywing-setup.sh` | The same script as a plain file. |
| `setup/upload-my-files.sh` | Copies your own files from Cloud Shell into the **My Uploads** folder in your Drive. The setup installs it for you as `upload-my-files`. |
| `agents/STARTER-PROMPTS.md` | Build the Chief of Staff: the starter prompt, five test questions, rounds 2-3 to improve it, and a "go faster" section that adds the other five agents as subagents. |
| `agents/ANSWER-KEY.md` | Each test question, what a good answer roughly says, and what makes it wrong. |
| `agents/BRING-YOUR-OWN-FILES.md` | How to use your own documents with your agent. |
| `challenge/EASTER-EGG-HUNT.md` | Five movie references hidden in Graywing's files, answers at the bottom. |

## Get started (about 5 minutes)

**Lab link:** *(your facilitator will share the Qwiklabs link on the day)*

Your lab project already has a Gemini Enterprise app. The setup connects it to the Graywing data and turns on the tools you'll use.

1. Open the Google Cloud console, select your lab project, and click **Activate Cloud Shell** (the `>_` icon at the top).
2. Run the setup, using either option:
   - **One line:**
     ```
     bash <(curl -fsSL https://raw.githubusercontent.com/tridorian/YPO-Chicagoland/main/setup/graywing-setup.sh)
     ```
   - **Paste:** copy the whole of `setup/PASTE-INTO-CLOUD-SHELL.txt` into Cloud Shell and press Enter.
3. Watch the steps finish. The script:
   - connects Google Drive to your app (and links an empty helper data store, which the lab's app needs; ignore it)
   - turns on Google Search, image generation, Canvas, every model your lab can use (it tests each one and switches off any the free trial doesn't include), and the no-code agent builder
   - copies the demo data into your My Drive under **Graywing Ag Systems (Demo Data)**, and makes an empty **My Uploads** folder for your own files

   The green box at the end shows your **app link**, your **Drive folder link** and your **My Uploads link**. To see them again later, run `cat ~/graywing-lab/links.txt`.
4. Open the app link, click **Connectors**, and **Authorize** Google Drive. Then, in the chat, ask *"List three files in my Drive folder Graywing Ag Systems (Demo Data)"* and click **Authorize** if it asks (step 0 of the starter prompts).
5. Ask: *"What does Graywing Ag Systems sell, and who are its biggest customers?"*

It's safe to run the script again: it reuses what's already there and never duplicates files. A full log is in `~/graywing-lab/setup.log`.

## Then

- **Build the Chief of Staff:** follow `agents/STARTER-PROMPTS.md` (Agents > + Create agent > Chat agent), and ask its five test questions.
- **Check the answers:** compare them with `agents/ANSWER-KEY.md`. Wording will differ; check the facts.
- **Put it to work:** ask it to write an email, a meeting invite, a memo or a slide outline for you to copy into Gmail, Calendar, Docs or Slides, or open the memo in Canvas to edit.
- **Bring your own files:** see `agents/BRING-YOUR-OWN-FILES.md`.
- **Go faster:** add the other five agents as subagents (end of the starter prompts).
- **Hunt for the Easter eggs:** see `challenge/EASTER-EGG-HUNT.md`.

## Good to know

- **Facts come from the files; you do the sending.** Graywing's email and calendars are files in the "Gmail (simulated)" and "Calendar (simulated)" folders in Drive. The agent reads them like any other file. It can't send email, save drafts, add calendar events or create files: it writes the email, invite, memo or table in the chat (or in Canvas), and you copy it into Gmail, Calendar, Docs, Slides or Sheets yourself.
- **Google Search is on** for outside context (markets, prices, news). Company facts should always come from the Graywing files; ask the agent to say which is which.
- The data is set around **Thursday, Oct 15, 2026**. Answers that count days ("41 days to renewal") assume that date.
- The Google Drive connector only searches your own Drive, so each person sees only their own copy of the data and their own uploads.
- Your lab account is temporary: anything you upload or create goes away when the lab ends.
- *Facilitators:* running the setup with `WITH_ACTIONS=1` also connects Gmail and Calendar with actions. Their Authorize step failed in our Qwiklabs test, so leave it off for participants.
