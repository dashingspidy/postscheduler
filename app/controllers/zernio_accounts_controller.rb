class ZernioAccountsController < ApplicationController
  before_action :set_account, only: %i[edit update destroy]

  def create
    @project = Current.user.projects.find(params.expect(:project_id))
    provider = params[:provider].presence || @project.publishing_provider
    selected_ids = Array(params[:provider_account_ids]).compact_blank
    selected_accounts = Publishing::Registry.fetch(provider).list_accounts.select do |account|
      selected_ids.include?(account._id) && ZernioAccount::PLATFORMS.include?(account.platform)
    end
    existing_ids = @project.zernio_accounts.where(provider:).pluck(:account_id)
    accounts_to_add = selected_accounts.reject { |account| existing_ids.include?(account._id) }
    raise ArgumentError, "Select at least one available account." if accounts_to_add.empty?

    ZernioAccount.transaction do
      accounts_to_add.each do |account|
        @project.zernio_accounts.create!(
          account_id: account._id,
          platform: account.platform,
          label: account.display_name.presence || account.username.presence || account._id,
          active: account.is_active && account.enabled != false,
          provider:
        )
      end
    end
    redirect_to @project, notice: "#{accounts_to_add.size} provider accounts connected."
  rescue StandardError => error
    Rails.logger.warn("Unable to connect provider accounts: #{error.message}")
    redirect_to @project, alert: error.message
  end

  def edit; end

  def update
    if @zernio_account.update(zernio_account_params)
      redirect_to @zernio_account.project, notice: "Content profile updated for #{@zernio_account.label}."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    project = @zernio_account.project
    @zernio_account.destroy
    redirect_to project, notice: "Zernio account removed."
  end

  private
    def zernio_account_params
      params.expect(zernio_account: [ :factory_enabled, :factory_posts_per_day, :content_strategy, :content_pillars_text ])
    end

    def set_account = @zernio_account = ZernioAccount.joins(:project).merge(Current.user.projects).find(params[:id])
end
