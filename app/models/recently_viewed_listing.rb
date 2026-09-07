class RecentlyViewedListing < ApplicationRecord
  belongs_to :user
  belongs_to :listing
end
