class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update destroy create_factory_slideshow]

  def index
    @projects = Current.user.projects.includes(:zernio_accounts, background_images_attachments: :blob).order(:name)
  end

  def show
    @account_providers = @project.zernio_accounts.distinct.order(:provider).pluck(:provider)
    @selected_account_provider = params[:provider].presence
    @connected_accounts = @project.zernio_accounts.order(:label)
    @connected_accounts = @connected_accounts.where(provider: @selected_account_provider) if @selected_account_provider.in?(@account_providers)
    @available_provider_accounts = available_provider_accounts
  end
  before_action :load_provider_accounts, only: %i[new create]

  def new
    @project = Current.user.projects.build
  end
  def edit; end

  def create
    @project = Current.user.projects.build(project_params)
    @selected_zernio_account_ids = Array(params[:zernio_account_ids])
    selected_accounts = Publishing::Registry.fetch(@project.publishing_provider).list_accounts.select do |account|
      @selected_zernio_account_ids.include?(account._id) && ZernioAccount::PLATFORMS.include?(account.platform)
    end

    if selected_accounts.empty?
      @project.errors.add(:base, "Select at least one publishing account.")
      render :new, status: :unprocessable_content
      return
    end

    project_accounts = selected_accounts.map do |account|
      @project.zernio_accounts.build(
        account_id: account._id,
        platform: account.platform,
        label: account.display_name.presence || account.username.presence || account._id,
        active: account.is_active && account.enabled != false,
        provider: @project.publishing_provider
      )
    end

    if @project.valid? && project_accounts.all?(&:valid?)
      Project.transaction do
        @project.save!
        project_accounts.each(&:save!)
      end
      redirect_to @project, notice: "Project created and #{project_accounts.size} publishing account#{"s" if project_accounts.size != 1} linked."
    else
      render :new, status: :unprocessable_content
    end
  rescue StandardError => error
    Rails.logger.warn("Unable to load #{@project.publishing_provider} accounts: #{error.message}")
    @project.errors.add(:base, "We couldn't load accounts from the selected provider. Check its API key and try again.")
    render :new, status: :unprocessable_content
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project deleted.", status: :see_other
  end

  def create_factory_slideshow
    slideshows = @project.zernio_accounts.active.tiktok.where(provider: @project.publishing_provider).filter_map do |account|
      next unless account.factory_configured?

      account.factory_posts_per_day.times.map do |index|
        ContentFactory::SlideshowCreator.new(@project, zernio_account: account, factory_slot: index + 1).call
      end
    end.flatten
    redirect_to slideshows_path, notice: "#{slideshows.size} account-specific slideshow drafts are being created."
  rescue ContentFactory::SlideshowCreator::Error, ActiveRecord::RecordInvalid => error
    redirect_to @project, alert: error.message
  end

  private
    def set_project = @project = Current.user.projects.find(params[:id])

    def project_params
      params.expect(project: [ :name, :app_icon, :end_slide_branding, :publishing_provider, :time_zone, :factory_enabled, :factory_time, :default_slide_count, { style: %i[text_color stroke_color font_size tactic_font_size tactic_top_margin] } ])
    end

    def load_provider_accounts
      @provider_accounts = Publishing::Registry.options.to_h do |_label, provider|
        accounts = Publishing::Registry.fetch(provider).list_accounts.select { |account| ZernioAccount::PLATFORMS.include?(account.platform) }
        [ provider, accounts ]
      rescue StandardError => error
        Rails.logger.warn("Unable to load #{provider} accounts: #{error.message}")
        [ provider, [] ]
      end
    end

    def available_provider_accounts
      provider = @project.publishing_provider
      connected_ids = @project.zernio_accounts.where(provider:).pluck(:account_id)
      Publishing::Registry.fetch(provider).list_accounts.select do |account|
        ZernioAccount::PLATFORMS.include?(account.platform) && !connected_ids.include?(account._id)
      end
    rescue StandardError => error
      Rails.logger.warn("Unable to load #{provider} accounts: #{error.message}")
      @available_provider_accounts_error = "We couldn't load available accounts from #{provider.humanize}."
      []
    end
end
