# Bring your own files

The Graywing data shows what an agent can do. Your own documents show what it can do for **you**. The setup makes an empty data store called **My uploads** in your lab project. Load a few of your files into it, add it to your Chief of Staff agent (or any agent you build), and the agent can read them next to the Graywing data.

## Before you start

- **Use the lab account, not your own Google account.** The lab account usually starts with `student-`. Check the picture or initial at the top right of the console before you upload.
- **Your files go away when the lab ends.** The lab project and account are temporary and get deleted, with everything in them. Keep your originals.
- **Don't upload anything confidential.** This is a shared training environment. Use a public document (an annual report, a brochure), an old or redacted version, or a made-up sample.

## Two ways to use your files

### 1. From Cloud Shell into My uploads (recommended)

Use this when you want your agent to use the files every time.

1. In Cloud Shell, click the **⋮** (More) menu at the top right of the terminal > **Upload** `[VERIFY UI]`. Choose your files (or a folder) and set the destination to the `my-files` folder in your home directory, for example `/home/student_00_abc/my-files` `[VERIFY UI]`.
2. Run:
   ```
   upload-my-files
   ```
   If Cloud Shell says `command not found`, run this instead:
   ```
   bash <(curl -fsSL https://raw.githubusercontent.com/tridorian/YPO-Chicagoland/main/setup/upload-my-files.sh)
   ```
3. It loads the files into the **My uploads** data store. It also copies them to the **My Uploads** folder in your Drive, so you can open them there; the agent doesn't read that folder.
4. Wait a few minutes. New files take a few minutes before the agent can find them.
5. Add **My uploads** to your agent (see below).

It's safe to run again. If `~/my-files` is empty, it creates the folder and shows you how to upload.

Dragging files into the My Uploads folder in Drive doesn't make them visible to the agent. Use `upload-my-files` instead.

### 2. Attach a file in the chat

In the Gemini Enterprise app, click **+** in the chat box `[VERIFY UI]` and choose **Upload files** `[VERIFY UI]`. This is the quickest way to ask about one file once, with no waiting. The attachment only belongs to that conversation, so if you want an agent to use a file every time, use `upload-my-files`.

## Point your agent at My uploads

The Chief of Staff starter prompt tells the agent to use **only** the Graywing demo data, so it ignores your files unless you say otherwise. Do both:

- **Add the data store to the agent:** open your agent (**Agents** > your agent > **Edit** `[VERIFY UI]`), go to **Add data sources & tools** and add **My uploads** next to **Graywing demo data** `[VERIFY UI]`.
- **Add a sentence to its instructions:**
  > Also use the "My uploads" data store; it holds my own company's files. When a question is about my files, use them first and name the file behind every fact.

Naming the file in your question ("the Q3 forecast in My uploads") also helps the agent find it.

## Try these

1. *Summarize the file I just uploaded to My uploads and list three questions a board member would ask about it.*
2. *Write a one-page leadership update for my company from the files in My uploads, in the same format you use for Graywing: bottom line first, one section per area, then next steps with owners.*
3. *Compare the spreadsheet in My uploads with Graywing's September budget: where are both companies over plan, and what is Graywing doing about it that I could copy?*

## Good to know

- **Wait a few minutes after uploading.** Files loaded with `upload-my-files` take a few minutes to become searchable. If the agent can't find a brand-new file, wait, then ask again and name the file in your question.
- **What the agent can read from My uploads:** PDF, Word (.docx), PowerPoint (.pptx), Excel (.xlsx), HTML and plain text (.txt). Stick to these. For a Google Doc, Sheet or Slides file, download it as Word, Excel or PowerPoint first. For other types, such as images, attach them in the chat instead. A PDF that is a scan or a photo of a page works less well than one with real text.
- **Keep files reasonably small.** A few files of a few MB, or up to about 100 pages each, work best. Very large spreadsheets may only be partly read. `upload-my-files` skips anything over 100 MB.
- **Google Search is on** for outside context, so ask the agent to say which facts came from your files and which from the web.
