class DashboardController < ApplicationController
  def index
    @month = parse_month
    @posts_by_date = Current.user.posts.scheduled
      .where(scheduled_at: @month.beginning_of_month..@month.end_of_month.end_of_day)
      .order(:scheduled_at)
      .group_by { |post| post.scheduled_at.to_date }
  end

  private
    def parse_month
      Date.strptime(params.fetch(:month, Date.current.strftime("%Y-%m")), "%Y-%m").beginning_of_month
    rescue ArgumentError
      Date.current.beginning_of_month
    end
end
