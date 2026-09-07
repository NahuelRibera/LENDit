# Encapsulates the marketplace browse/search query: PostgreSQL full-text
# search with a pg_trgm fuzzy fallback, filters, and sorting. Kept out of
# ListingsController so the controller action stays a one-liner and this
# logic is independently testable.
class ListingSearch
  def initialize(params, current_user: nil)
    @params = params
    @query = params[:q].to_s.strip
    @current_user = current_user
  end

  attr_reader :query

  def results
    scope = base_scope
    scope = apply_text_search(scope)
    scope = apply_filters(scope)
    apply_sort(scope)
  end

  def relevance_available?
    @relevance_available || false
  end

  private

  attr_reader :params, :current_user

  def base_scope
    Listing.published.available_to(current_user)
      .includes(:user, :category, listing_images: { file_attachment: :blob })
  end

  def apply_text_search(scope)
    return scope if query.blank?

    tsquery = ActiveRecord::Base.sanitize_sql_array(["plainto_tsquery('simple', ?)", query])
    fts_scope = scope.where("listings.search_vector @@ #{tsquery}")

    if fts_scope.exists?
      @relevance_available = true
      fts_scope.select("listings.*, ts_rank(listings.search_vector, #{tsquery}) AS search_rank")
    else
      # word_similarity (not similarity) so a typo in one word of a longer,
      # multi-word title still matches — similarity() alone compares the
      # whole strings and is diluted by the other words in the title.
      quoted = ActiveRecord::Base.connection.quote(query)
      @relevance_available = true
      scope.where("word_similarity(#{quoted}, listings.title) > 0.3")
        .select("listings.*, word_similarity(#{quoted}, listings.title) AS search_rank")
    end
  end

  def apply_filters(scope)
    scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
    scope = scope.where(condition: params[:condition]) if params[:condition].present?
    scope = scope.where("listings.city ILIKE ?", "%#{params[:city]}%") if params[:city].present?
    scope = scope.where("listings.price_cents >= ?", cents(params[:price_min])) if params[:price_min].present?
    scope = scope.where("listings.price_cents <= ?", cents(params[:price_max])) if params[:price_max].present?

    if params[:min_owner_rating].present?
      scope = scope.left_joins(:user).where("users.ratings_avg >= ?", params[:min_owner_rating].to_f)
    end

    scope
  end

  def apply_sort(scope)
    case params[:sort]
    when "price_asc" then scope.reorder(price_cents: :asc)
    when "price_desc" then scope.reorder(price_cents: :desc)
    when "rating_desc" then scope.left_joins(:user).reorder(Arel.sql("users.ratings_avg DESC NULLS LAST"))
    when "newest" then scope.reorder(created_at: :desc, id: :desc)
    else
      relevance_available? ? scope.reorder(Arel.sql("search_rank DESC")) : scope.reorder(created_at: :desc, id: :desc)
    end
  end

  def cents(value)
    (value.to_f * 100).round
  end
end
