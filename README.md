# Graywing Ag Systems · Gemini Enterprise lab

Everything you need to set up a Gemini Enterprise app over the demo data for **Graywing Ag Systems**, build your own no-code **Chief of Staff** agent, and check its answers. Graywing is a fictional agriculture-equipment company; all names, numbers and documents are made up.

## What's in this repo

| File | What it is |
|---|---|
| `graywing-demo-data.zip` | The demo data: 124 files (spreadsheets, documents, manuals, simulated email and calendar printouts, test photos) in one folder per team. The setup script downloads this file; nothing else in the repo is part of the data. |
| `setup/PASTE-INTO-CLOUD-SHELL.txt` | The setup script, ready to paste into Cloud Shell. |
| `setup/graywing-setup.sh` | The same script as a plain file. |
| `setup/upload-my-files.sh` | Copies your own files from Cloud Shell into the **My Uploads** folder in your Drive, where your agent reads them (and into the **My uploads** data store, the no-sign-in fallback). The setup installs it for you as `upload-my-files`. |
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
   - copies the demo data into your My Drive under **Graywing Ag Systems (Demo Data)**, and makes an empty **My Uploads** folder for your own files. Your agent reads these through Google Drive.
   - connects **Google Drive** to your app (search and file actions), so answers link to the real Drive files
   - also creates two data stores, **Graywing demo data** (Graywing's 111 documents, spreadsheets and slide decks) and **My uploads**. The lab's app needs them linked, and they're the fallback if Google Drive won't authorize; your agent doesn't use them otherwise.
   - turns on Google Search for the main chat, image generation, Canvas, the no-code agent builder and the models your lab can use (the newest Gemini 4 models and Claude are switched off: they don't work in the lab)

   The green box at the end shows your **app link**, your **Drive folder link** and your **My Uploads link**. To see them again later, run `cat ~/graywing-lab/links.txt`.
4. Open the app link, go to **Connectors** and click **Authorize** on **Google Drive**, signed in as your lab account. If it says "Data connector is not ready yet", wait a few minutes, refresh and try again.
5. In the chat, ask *"List three files in my Drive folder Graywing Ag Systems (Demo Data)."* The answer should name Graywing files, each a link to Drive (step 0 of the starter prompts).

It's safe to run the script again: it reuses what's already there and never duplicates files. A full log is in `~/graywing-lab/setup.log`.

## Then

- **Build the Chief of Staff:** follow `agents/STARTER-PROMPTS.md` (Agents > + Create agent > Chat agent), and ask its five test questions.
- **Check the answers:** compare them with `agents/ANSWER-KEY.md`. Wording will differ; check the facts.
- **Put it to work:** ask it to write an email, a meeting invite, a memo or a slide outline for you to copy into Gmail, Calendar, Docs or Slides, or open the memo in Canvas to edit.
- **Bring your own files:** see `agents/BRING-YOUR-OWN-FILES.md`.
- **Go faster:** add the other five agents as subagents (end of the starter prompts).
- **Hunt for the Easter eggs:** see `challenge/EASTER-EGG-HUNT.md`.

## Good to know

- **Your agent reads only Google Drive.** In the agent builder, add Google Drive as its one data source, turn Google Search off and leave the data stores off. Every fact then comes from the Graywing files, with a link to the file.
- **Facts come from the files; you do the sending.** Graywing's email and calendars are files too: the "Gmail (simulated)" and "Calendar (simulated)" folders in the Drive folder. The agent reads them like any other file. It doesn't send email, add calendar events or change files: it writes the email, invite, memo or table in the chat (or in Canvas), and you copy it into Gmail, Calendar, Docs, Slides or Sheets yourself.
- **Google Search** is on in the main chat for outside context (markets, prices, news), and off in your agent.
- The data is set around **Thursday, Oct 15, 2026**. Answers that count days ("41 days to renewal") assume that date.
- Each person's Drive copy belongs to their own lab account, so each agent sees only that person's copy and uploads.
- Your lab account is temporary: anything you upload or create goes away when the lab ends.
- *Facilitators:* `NO_DRIVE=1` skips the Google Drive connector (data stores only, no Authorize step; sources aren't clickable). `WITH_ACTIONS=1` also connects Gmail and Google Calendar (untested in the lab).
