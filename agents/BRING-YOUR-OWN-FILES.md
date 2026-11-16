# Bring your own files

The Graywing data shows what an agent can do. Your own documents show what it can do for **you**. The setup makes an empty **My Uploads** folder in your Google Drive. Your agent already reads Google Drive, so put a few of your files there, tell the agent about the folder, and it can read them next to the Graywing data.

## Before you start

- **Use the lab account, not your own Google account.** The lab account usually starts with `student-`. Check the picture or initial at the top right of Drive or the console before you upload.
- **Your files go away when the lab ends.** The lab project and account are temporary and get deleted, with everything in them. Keep your originals.
- **Don't upload anything confidential.** This is a shared training environment. Use a public document (an annual report, a brochure), an old or redacted version, or a made-up sample.

## Three ways to use your files

### 1. Drag them into My Uploads in Drive (recommended)

1. Open the **My Uploads** link from the setup's green box (or run `cat ~/graywing-lab/links.txt` in Cloud Shell to see it again).
2. Drag your files into the folder, or click **+ New** > **File upload**.
3. Tell your agent about the folder (see below). It can usually find a new file right away; if not, wait a minute and ask again with the file's name.

Google Docs, Sheets and Slides work too, so you can also make a file straight in the folder.

### 2. From Cloud Shell

If your files are on your computer and Cloud Shell is easier:

1. In Cloud Shell, click the **⋮** (More) menu at the top right of the terminal > **Upload** `[VERIFY UI]`. Choose your files and set the destination to the `my-files` folder in your home directory, for example `/home/student_00_abc/my-files` `[VERIFY UI]`.
2. Run:
   ```
   upload-my-files
   ```
   If Cloud Shell says `command not found`, run this instead:
   ```
   bash <(curl -fsSL https://raw.githubusercontent.com/tridorian/YPO-Chicagoland/main/setup/upload-my-files.sh)
   ```
3. It copies the files into the **My Uploads** folder in your Drive (and into the **My uploads** data store, which is only used if your agent runs on the data stores instead of Drive).

It's safe to run again. If `~/my-files` is empty, it creates the folder and shows you how to upload.

### 3. Attach a file in the chat

In the Gemini Enterprise app, click **+** in the chat box `[VERIFY UI]` and choose **Upload files** `[VERIFY UI]`. This is the quickest way to ask about one file once. The attachment only belongs to that conversation; for a file your agent should use every time, put it in My Uploads.

## Point your agent at My Uploads

The Chief of Staff starter prompt tells the agent to read **only** the Graywing folder, so it ignores your files unless you say otherwise. Google Drive is already its data source, so there's no new data source to add. Add a sentence to its instructions:

> Also read the "My Uploads" folder in my Google Drive; it holds my own company's files. When a question is about my files, use them first, mark facts from them as (my upload) and link the file behind every fact.

Naming the file in your question ("the Q3 forecast in My Uploads") also helps the agent find it.

*Running on the data stores instead (Google Drive wouldn't authorize)?* Use `upload-my-files`, add the **My uploads** data store to the agent, and say "the My uploads data store" in the sentence above. Files there take a few minutes to become searchable.

## Try these

1. *Summarize the file I just put in My Uploads and list three questions a board member would ask about it.*
2. *Write a one-page leadership update for my company from the files in My Uploads, in the same format you use for Graywing: bottom line first, one section per area, then next steps with owners.*
3. *Compare the spreadsheet in My Uploads with Graywing's September budget: where are both companies over plan, and what is Graywing doing about it that I could copy?*

## Good to know

- **What works best:** Google Docs, Sheets and Slides, PDF, Word (.docx), PowerPoint (.pptx), Excel (.xlsx) and plain text. A PDF that is a scan or a photo of a page works less well than one with real text. For images, attach them in the chat instead.
- **Keep files reasonably small.** A few files of a few MB, or up to about 100 pages each, work best. Very large spreadsheets may only be partly read.
- **Google Search is off in your agent**, so everything it says about your company comes from your files. For outside context, ask in the main chat.
