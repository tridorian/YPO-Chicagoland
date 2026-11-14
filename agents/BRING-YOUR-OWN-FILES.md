# Bring your own files

The Graywing data shows what an agent can do. Your own documents show what it can do for **you**. The setup makes an empty folder called **My Uploads** in your lab account's My Drive. Put a few of your files in it, and your Chief of Staff agent (or any agent you build) can read them next to the Graywing data.

## Before you start

- **Sign in as the lab user, not your own Google account.** The lab account usually starts with `student-`. Check the picture or initial at the top right of Drive before you upload.
- **Your files go away when the lab ends.** The lab account is temporary and gets deleted, with everything in its Drive. Keep your originals.
- **Don't upload anything confidential.** This is a shared training environment. Use a public document (an annual report, a brochure), an old or redacted version, or a made-up sample.

## Three ways to add files

### 1. Drag and drop into My Uploads (recommended)

1. Open the **My Uploads** link from the green box at the end of the setup. To see it again, run `cat ~/graywing-lab/links.txt` in Cloud Shell. Or go to [drive.google.com](https://drive.google.com) > **My Drive** > **My Uploads**.
2. Drag your files from your computer onto the folder. (Or click **+ New** > **File upload**.)
3. Optional but worth it: turn Word, Excel and PowerPoint files into Google Docs, Sheets and Slides, so the agent reads tables more reliably. Before you upload, turn on Drive's **Settings** (gear icon) > **General** > **Convert uploads** `[VERIFY UI]`. For a file already uploaded, open it and choose **File** > **Save as Google Sheets** (or Docs, or Slides).

### 2. From Cloud Shell

Use this if you're already in Cloud Shell, or you have a whole folder of files.

1. In Cloud Shell, click the **⋮** (More) menu at the top right of the terminal > **Upload** `[VERIFY UI]`. Choose your files (or a folder) and set the destination to the `my-files` folder in your home directory, for example `/home/student_00_abc/my-files` `[VERIFY UI]`.
2. Run:
   ```
   upload-my-files
   ```
   If Cloud Shell says `command not found`, run this instead:
   ```
   bash <(curl -fsSL https://raw.githubusercontent.com/tridorian/YPO-Chicagoland/main/setup/upload-my-files.sh)
   ```
3. It copies everything into **My Uploads** and keeps your subfolders. Word, Excel, PowerPoint and CSV files become Google Docs, Sheets and Slides. It prints the folder link at the end.

It's safe to run again: files already in My Uploads with the same name are skipped. If `~/my-files` is empty, it creates the folder and shows you how to upload.

### 3. Attach a file in the chat

In the Gemini Enterprise app, click **+** in the chat box `[VERIFY UI]` and choose **Upload files** (from your computer) or the Google Drive option (from Drive) `[VERIFY UI]`. This is the quickest way to ask about one file once. The attachment only belongs to that conversation, so if you want an agent to use a file every time, put it in My Uploads.

## Point your agent at My Uploads

The Chief of Staff starter prompt tells the agent to use **only** the Graywing folder, so it ignores My Uploads unless you say otherwise. Do one of these:

- **Add the folder to the agent:** open your agent (**Agents** > your agent > **Edit** `[VERIFY UI]`) and add the **My Uploads** folder next to the Graywing folder where you picked Google Drive as a source `[VERIFY UI]`.
- **Add a sentence to its instructions:**
  > Also use the folder "My Uploads" in My Drive; it holds my own company's files. When a question is about my files, use them first and name the file behind every fact.
- **Just ask in the chat:** "Also use the files in my My Uploads folder."

Naming the file in your question ("the Q3 forecast in My Uploads") also helps the agent find it.

## Try these

1. *Summarize the file I just uploaded to My Uploads and list three questions a board member would ask about it.*
2. *Write a one-page leadership update for my company from the files in My Uploads, in the same format you use for Graywing: bottom line first, one section per area, then next steps with owners.*
3. *Compare the spreadsheet in My Uploads with Graywing's September budget: where are both companies over plan, and what is Graywing doing about it that I could copy?*

## Good to know

- **No waiting for indexing.** The Google Drive connector searches your Drive live, so the agent can usually use a file as soon as it's uploaded. If it can't find a brand-new file, wait a minute and name the file in your question.
- **Google formats work best.** Agents read Google Sheets tables more reliably than Excel files, and Google Docs more reliably than scanned PDFs.
- **What works:** PDFs, Google Docs, Sheets and Slides, Word, Excel and PowerPoint files, images (JPG, PNG), and plain text or CSV files. A PDF that is a scan or a photo of a page works less well than one with real text.
- **Keep files reasonably small.** A few files of a few MB, or up to about 100 pages each, work best. Very large spreadsheets may only be partly read. `upload-my-files` skips anything over 100 MB.
- **Google Search is off** in the app, so answers come only from the files: yours and Graywing's.
