class CategoriesController < ApplicationController
  def index
    @categories = Category.active.ordered
  end

  def show
    @category = Category.active.find_by!(slug: params[:slug])
    @listings = @category.listings.published.available_to(current_user).recent
  end
end
