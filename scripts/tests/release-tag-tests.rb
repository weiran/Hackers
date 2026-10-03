# Offline regression coverage; the Fastlane DSL records lanes without running them.
require 'minitest/autorun'
require 'open3'

module UI
  def self.user_error!(message) = raise(ArgumentError, message)
  def self.success(*) = nil
end

LANES = {}
def default_platform(*) = nil
def platform(*) = yield
def desc(*) = nil
def lane(name, &block) = LANES[name] = block
load File.expand_path('../../fastlane/Fastfile', __dir__)

class ReleaseTagTests < Minitest::Test
  TAG = 'v5.5.0+166'

  def setup
    @release_environment = %w[TESTFLIGHT_GROUPS BUILD_NUMBER CANCEL_PENDING_VERSION].to_h do |key|
      [key, ENV[key]]
    end
    ENV.delete('BUILD_NUMBER')
    ENV.delete('CANCEL_PENDING_VERSION')
    @uploads = []
    uploads = @uploads
    Object.send(:define_method, :app_store_connect_key) { :offline_key }
    Object.send(:define_method, :release_notes) { 'Improves comment reliability.' }
    Object.send(:define_method, :log_app_store_versions) { |_| }
    Object.send(:define_method, :upload_to_testflight) { |**options| uploads << options }
    Object.send(:define_method, :upload_to_app_store) { |**options| uploads << options }
    # Simulate master having moved to the next marketing version.
    Object.send(:define_method, :marketing_version) { '9.9.9' }
    ENV['TESTFLIGHT_GROUPS'] = 'External Testers'
  end

  def teardown
    @release_environment.each { |key, value| ENV[key] = value }
  end

  def test_existing_distribution_uses_tag_version
    LANES[:distribute_existing_testflight].call(release_tag: TAG)
    assert_equal '5.5.0', @uploads.fetch(0)[:app_version]
    assert_equal '166', @uploads.fetch(0)[:build_number]
  end

  def test_app_review_uses_tag_version
    LANES[:submit_app_review].call(release_tag: TAG)
    assert_equal '5.5.0', @uploads.fetch(0)[:app_version]
    assert_equal '166', @uploads.fetch(0)[:build_number]
  end

  def test_new_archive_still_requires_checkout_version
    assert_raises(ArgumentError) { validate_release_tag!(TAG) }
  end

  def test_tag_metadata_mismatch_is_rejected
    assert_raises(ArgumentError) { validate_release_tag!('v9.9.9+999999', source: :tag) }
  end

  def test_existing_tag_with_mismatched_target_metadata_is_rejected
    source, = Open3.capture2('git', 'show', "refs/tags/#{TAG}:Hackers.xcodeproj/project.pbxproj", chdir: REPO_ROOT)
    changed = source.gsub('MARKETING_VERSION = 5.5.0', 'MARKETING_VERSION = 9.9.9')
    refute_equal source, changed
    original = Object.instance_method(:release_tag_project)
    Object.send(:define_method, :release_tag_project) { |_| changed }
    assert_raises(ArgumentError) { validate_release_tag!(TAG, source: :tag) }
  ensure
    Object.send(:define_method, :release_tag_project, original) if original
  end

  def test_requested_build_cannot_override_tag
    assert_raises(ArgumentError) do
      LANES[:submit_app_review].call(release_tag: TAG, build_number: 999)
    end
    assert_empty @uploads
  end
end
