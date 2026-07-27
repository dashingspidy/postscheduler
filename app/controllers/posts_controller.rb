class PostsController < ApplicationController
  before_action :set_post, only: %i[show edit update destroy]
  before_action :load_post_form_data, only: %i[new create edit update]

  def index
    @posts = Current.user.posts
      .includes(project: :zernio_accounts, slides_attachments: :blob)
      .order(scheduled_at: :asc, created_at: :desc)
  end

  def show; end

  def new
    @post = Current.user.posts.build(scheduled_at: Time.current.change(min: 0))
  end

  def edit; end

  def create
    @post = Current.user.posts.build(post_params)
    assign_selected_accounts
    if @post.errors.empty? && @post.save
      redirect_to @post, notice: "Post created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @post.assign_attributes(post_params)
    assign_selected_accounts
    if @post.errors.empty? && @post.save
      redirect_to @post, notice: "Post updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post deleted.", status: :see_other
  end

  private
    def set_post
      @post = Current.user.posts.find(params[:id])
    end

    def post_params
      permitted = params.expect(post: [ :title, :content, :scheduled_at, :project_id ])
      permitted[:status] = permitted[:scheduled_at].present? ? "scheduled" : "draft"
      permitted
    end

    def load_post_form_data
      @projects = Current.user.projects.order(:name)
      @zernio_accounts = Current.user.projects.includes(:zernio_accounts).flat_map(&:zernio_accounts).select(&:active?)
    end

    def assign_selected_accounts
      @selected_zernio_account_ids = Array(params.dig(:post, :zernio_account_ids)).reject(&:blank?)
      selected_accounts = @post.project&.zernio_accounts&.active&.where(provider: @post.project.publishing_provider, id: @selected_zernio_account_ids)&.to_a || []

      if @post.project.blank?
        @post.errors.add(:project, "must be selected")
      elsif selected_accounts.empty?
        @post.errors.add(:zernio_accounts, "select at least one account from the selected project")
      else
      @post.platforms = selected_accounts.map(&:platform).uniq
      @post.account_ids = selected_accounts.group_by(&:platform).transform_values { |accounts| accounts.map(&:account_id) }
      @post.publishing_provider = @post.project.publishing_provider
      end
    end
end
