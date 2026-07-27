class SlideshowsController < ApplicationController
  def index
    @slideshows = Current.user.slideshows
      .includes(:project, :zernio_accounts, post: { slides_attachments: :blob })
      .order(created_at: :desc)
  end

  def show
    @slideshow = Current.user.slideshows.find(params[:id])
  end

  def destroy
    slideshow = Current.user.slideshows.find(params[:id])
    post = slideshow.post
    topic = slideshow.content_topic

    slideshow.update!(post: nil, content_topic: nil)
    topic&.destroy!
    post&.tap do |post|
      post.slides.purge
      post.destroy!
    end
    slideshow.destroy!
    redirect_to slideshows_path, notice: "Slideshow deleted.", status: :see_other
  end
end
