require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  def setup
    @comment = Comment.new(commentable: posts(:one), user_id: users(:frank).id, body: "comment")
  end

  test "should be valid" do
    assert @comment.valid?, @comment.errors.messages
  end

  test "should have a body" do
    @comment.body = " "
    assert_not @comment.valid?
  end

  test "should have associated post" do
    @comment.commentable_id = nil
    assert_not @comment.valid?
  end

  test "should have associated user" do
    @comment.user_id = nil
    assert_not @comment.valid?
  end
end
