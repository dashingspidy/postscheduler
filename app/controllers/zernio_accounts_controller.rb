class ZernioAccountsController < ApplicationController
  def create
    @project = Current.user.projects.find(params.expect(:project_id))
    @zernio_account = @project.zernio_accounts.build(zernio_account_params)
    if @zernio_account.save
      redirect_to @project, notice: "Zernio account added."
    else
      redirect_to @project, alert: @zernio_account.errors.full_messages.to_sentence
    end
  end

  def destroy
    account = ZernioAccount.joins(:project).merge(Current.user.projects).find(params[:id])
    project = account.project
    account.destroy
    redirect_to project, notice: "Zernio account removed."
  end

  private
    def zernio_account_params
      params.expect(zernio_account: [ :platform, :account_id, :label ])
    end
end
