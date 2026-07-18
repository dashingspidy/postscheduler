class ProjectPhotosController < ApplicationController
  def new
    @projects = Current.user.projects.order(:name)
    @selected_project_id = params[:project_id]
  end

  def create
    project = Current.user.projects.find(project_photo_params[:project_id])
    photos = project_photo_params[:photos].compact_blank

    if photos.any?
      project.background_images.attach(photos)
      redirect_to project, notice: "#{photos.size} photo#{"s" if photos.size != 1} uploaded to #{project.name}."
    else
      @projects = Current.user.projects.order(:name)
      flash.now[:alert] = "Choose at least one photo to upload."
      render :new, status: :unprocessable_content
    end
  end

  private

    def project_photo_params
      params.expect(project_photo: [ :project_id, { photos: [] } ])
    end
end
