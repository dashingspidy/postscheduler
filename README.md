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

## TikTok slideshows

Create an Education, Muslim, or other **Project** first. Each project has its own connected Zernio TikTok account, reusable JPG/PNG background-image library, and rendering style. Then open **Import slideshows**, choose the project, and upload a CSV. Extra background images are optional and apply only to that import.

Each CSV row creates a slideshow from `Slide1` through `SlideN`. Supported optional fields are `Day`, `Tactic`, `Title`, `Caption`, `Keywords`, `Hashtags`, and `scheduled_at`. A row with `scheduled_at` is sent to Zernio after rendering; rows without it remain drafts for review.

Image rendering requires ImageMagick to be installed on every environment that processes jobs. Slides use the default font available to ImageMagick.

`Video::EndCardConcatenator` appends a two-second project-branded end card to a supplied MP4. It requires FFmpeg with the `drawtext` filter enabled and a project app icon.

## PostForMe

PostForMe is available as a project publishing provider. Add its API key when ready with `bin/rails credentials:edit`:

```yaml
post_for_me:
  api_key: your_api_key
```

After restarting the app, select **Post for me** while creating a project, choose its connected accounts, and publish normally. The adapter uploads the post media to PostForMe, then creates the social post through its API.
