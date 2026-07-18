class VideoCreationsController < ApplicationController
  before_action :load_form_data, only: %i[new create]
  def index
    @video_creations = Current.user.video_creations.includes(:project).order(created_at: :desc)
  end

  def show
    @video_creation = Current.user.video_creations.find(params[:id])
  end

  def new
    @video_creation = Current.user.video_creations.build(call_to_action: "Download the app")
    @post = Current.user.posts.build
  end

  def create
    @video_creation = Current.user.video_creations.build(video_creation_params)
    @post = Current.user.posts.build(video_post_params.merge(status: "draft", delivery_mode: "auto_publish"))
    assign_selected_accounts

    if @video_creation.valid? && @post.errors.empty? && @post.valid?
      VideoCreation.transaction do
        @post.save!
        @video_creation.post = @post
        @video_creation.save!
      end
      Video::ProcessVideoCreationJob.perform_later(@video_creation)
      redirect_to @video_creation, notice: "Video creation started."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

    def video_creation_params
      params.expect(video_creation: %i[project_id input_video call_to_action])
    end

    def video_post_params
      details = params.expect(video_creation: %i[project_id title content])
      { project: Current.user.projects.find(details[:project_id]), title: details[:title], content: details[:content] }
    end

    def load_form_data
      @projects = Current.user.projects.order(:name)
      @zernio_accounts = Current.user.projects.includes(:zernio_accounts).flat_map(&:zernio_accounts).select(&:active?)
    end

    def assign_selected_accounts
      @selected_zernio_account_ids = Array(params.dig(:video_creation, :zernio_account_ids)).reject(&:blank?)
      selected_accounts = @post.project.zernio_accounts.active.where(provider: @post.project.publishing_provider, id: @selected_zernio_account_ids)
      if selected_accounts.empty?
        @post.errors.add(:zernio_accounts, "select at least one account from the selected project")
        return
      end

      @post.platforms = selected_accounts.map(&:platform).uniq
      @post.account_ids = selected_accounts.group_by(&:platform).transform_values { |accounts| accounts.map(&:account_id) }
      @post.publishing_provider = @post.project.publishing_provider
    end
end
