class SlideshowImportsController < ApplicationController
  def index
    @slideshow_imports = Current.user.slideshow_imports.order(created_at: :desc)
  end

  def show
    @slideshow_import = Current.user.slideshow_imports.find(params[:id])
  end

  def new
    @slideshow_import = Current.user.slideshow_imports.build(project_id: params[:project_id])
    @projects = Current.user.projects.order(:name)
  end

  def create
    @slideshow_import = Current.user.slideshow_imports.build(slideshow_import_params)
    @slideshow_import.zernio_accounts = selected_accounts_for(@slideshow_import.project_id)
    if @slideshow_import.save
      redirect_to @slideshow_import, notice: "Slideshow created. Review it, then start processing when you are ready."
    else
      @projects = Current.user.projects.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def start
    @slideshow_import = Current.user.slideshow_imports.find(params[:id])
    unless @slideshow_import.pending? || @slideshow_import.failed?
      redirect_to @slideshow_import, alert: "This import has already started."
      return
    end

    @slideshow_import.update!(status: :processing, error_message: nil)
    TikTok::ProcessSlideshowImportJob.perform_later(@slideshow_import)
    redirect_to @slideshow_import, notice: "Slideshow creation has started."
  end

  def destroy
    slideshow_import = Current.user.slideshow_imports.find(params[:id])
    slideshow_import.slideshow_items.includes(:post).filter_map(&:post).each do |post|
      post.slides.purge
      post.destroy!
    end
    slideshow_import.csv_file.purge if slideshow_import.csv_file.attached?
    slideshow_import.destroy!
    redirect_to slideshow_imports_path, notice: "Slideshow deleted.", status: :see_other
  end

  private
    def slideshow_import_params
      params.expect(slideshow_import: [ :project_id, :csv_file, :delivery_mode ])
    end

    def selected_accounts_for(project_id)
      project = Current.user.projects.find(project_id)
      project.zernio_accounts.active.tiktok.where(provider: project.publishing_provider).to_a
    end
end
