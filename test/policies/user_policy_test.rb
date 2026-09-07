require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  test "anyone, including a guest, can view a profile" do
    assert UserPolicy.new(nil, users(:marti)).show?
    assert UserPolicy.new(users(:elena), users(:marti)).show?
  end

  test "only the user themself can edit their profile" do
    assert UserPolicy.new(users(:marti), users(:marti)).edit?
    assert_not UserPolicy.new(users(:elena), users(:marti)).edit?
  end
end
