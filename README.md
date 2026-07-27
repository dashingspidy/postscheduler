# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
# Postscheduler

## Daily content factory

Configure a project’s **Daily content factory** with its audience, tone, content rules, and a list of content pillars. Once enabled, the production scheduler creates one slideshow per project every day at 12:05 AM, schedules it for the project’s chosen time, and rotates through the pillars. A topic ledger keeps recent titles available to the AI so it can avoid repetition.

Use **Generate now** on a ready project to create that day’s factory slideshow immediately. Each factory run produces a normal slideshow and post, so it follows the same preview, retry, and publishing flow as manually created slideshows.

## TikTok slideshows

Create an Education, Muslim, or other **Project** first. Each project has its own connected TikTok account, reusable JPG/PNG background-image library, and rendering style. Then open **Create slideshow**, choose the project, and describe the carousel you want to create. Gemma generates a title, caption, and the requested number of slide captions; the project photos become the slide backgrounds.

Slideshow text generation uses Google Gemma through Amazon Bedrock Mantle's OpenAI-compatible endpoint in `us-east-1`. Generate a long-term Bedrock API key and add this Rails credential:

```yaml
bedrock:
  api_key: your_bedrock_api_key
```

The application uses `google.gemma-4-26b-a4b` in `us-east-1`; no region or model credential is needed.

Slideshow rendering uses the bundled Python/Pillow renderer. Rails owns jobs, storage, scheduling, and publishing; Pillow creates the slide JPG files. For local development, install Pillow and point Rails at that Python executable with `PILLOW_PYTHON`.

`Video::EndCardConcatenator` appends a two-second project-branded end card to a supplied MP4. It requires FFmpeg with the `drawtext` filter enabled and a project app icon.

## PostForMe

PostForMe is available as a project publishing provider. Add its API key when ready with `bin/rails credentials:edit`:

```yaml
post_for_me:
  api_key: your_api_key
```

After restarting the app, select **Post for me** while creating a project, choose its connected accounts, and publish normally. The adapter uploads the post media to PostForMe, then creates the social post through its API.
