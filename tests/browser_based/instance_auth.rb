require 'lib/popit_watir_test_case'
require 'pry'
require 'net/http'
require 'uri'


class InstanceAuthTests < PopItWatirTestCase

  def test_logging_in_and_out
    delete_instance 'test'
    goto_instance 'test'
    load_test_fixture

    # goto homepage
    goto '/'
    assert_equal 'test', @b.title

    # try signing in with no credentials
    @b.link(:id, "sign_in_as_existing_user").click
    @b.input(:value, "Login").click
    assert_equal 'Missing login', @b.li(:class => 'error').text

    # missing password
    @b.text_field(:name, 'email').set "foo"
    @b.input(:value, "Login").click
    assert_equal 'Missing password', @b.li(:class => 'error').text

    # bad password
    @b.text_field(:name, 'password').set "bad"
    @b.input(:value, "Login").click
    assert_equal 'credentials wrong', @b.li(:class => 'error').text

    # missing email
    @b.text_field(:name, 'email').clear
    @b.text_field(:name, 'password').set "bad"
    @b.input(:value, "Login").click
    assert_equal 'Missing login', @b.li(:class => 'error').text

    # correct login details
    @b.text_field(:name, 'email').set 'owner@example.com'
    @b.text_field(:name, 'password').set 'secret'
    @b.input(:value, "Login").click
    assert_match 'Signed in as owner@example.com', @b.li(:id, 'signed_in').text

    # correct login details (check spaces are stripped)
    @b.link(:text, 'Sign Out').click
    @b.link(:id, "sign_in_as_existing_user").click
    @b.text_field(:name, 'email').set '  owner@example.com  '
    @b.text_field(:name, 'password').set 'secret'
    @b.input(:value, "Login").click
    assert_match 'Signed in as owner@example.com', @b.li(:id, 'signed_in').text

    # check that the flash message is shown
    assert_equal @b.div(:id, 'flash-info').li.text, "You are now logged in."
    @b.div(:id, 'flash-info').link(:class, 'close').click    
    @b.wait_until { ! @b.div(:id, 'flash-info').present? }
    @b.refresh
    assert ! @b.div(:id, 'flash-info').present?

    # check that we can log out too
    @b.link(:text, 'Sign Out').click
    assert_equal 'Sign in using an existing account', @b.li(:id, 'sign_in').text

    # check that trying to go to a page that requires auth leads to you being
    # redirected back to that page after logging in
    goto '/about/edit' # need to be an owner to edit this
    @b.text_field(:name, 'email').set 'owner@example.com'
    @b.text_field(:name, 'password').set 'secret'
    @b.input(:value, "Login").click
    assert_match 'Signed in as owner@example.com', @b.li(:id, 'signed_in').text
    assert_path '/about/edit'

    # check that we redirect back to the page you clicked login on too
    @b.link(:text, 'Sign Out').click
    goto '/persons/george-bush'
    @b.link(:id, "sign_in_as_existing_user").click
    @b.text_field(:name, 'email').set 'owner@example.com'
    @b.text_field(:name, 'password').set 'secret'
    @b.input(:value, "Login").click
    assert_match 'Signed in as owner@example.com', @b.li(:id, 'signed_in').text
    assert_path '/persons/george-bush'
    

  end
  
  def test_enabling_and_disabling_guest_access
    goto_instance 'test'
    delete_instance_database
    load_test_fixture

    # check that the instance starts with guest access turned off
    goto '/'
    assert_equal "Authorised edits only", @b.element(:id => 'instance_guest_status').text
    
    # enable guest access and check again
    enable_guest_access
    goto '/'
    assert_equal "Guest edits allowed", @b.element(:id => 'instance_guest_status').text

    # and off again
    disable_guest_access
    goto '/'
    assert_equal "Authorised edits only", @b.element(:id => 'instance_guest_status').text

  end
  
  def test_logging_in_as_guest
    delete_instance 'test'
    goto_instance 'test'
    load_test_fixture

    # before guest access
    goto '/'
    assert_equal 'Sign in using an existing account', @b.li(:id, 'sign_in').text

    # after guest access enabled
    enable_guest_access
    goto '/'
    assert_equal 'Sign in using an existing account or as a guest', @b.li(:id, 'sign_in').text

    # try signing in with no credentials
    @b.link(:id, "sign_in_as_guest").click
    @b.input(:value, "Login as Guest").click
    assert_equal 'Signed in as a Guest', @b.li(:id, 'signed_in').text

    # check that the flash message is shown
    assert_equal @b.div(:id, 'flash-info').li.text, "You are now logged in."
    @b.div(:id, 'flash-info').link(:class, 'close').click    
    @b.wait_until { ! @b.div(:id, 'flash-info').present? }
    @b.refresh
    assert ! @b.div(:id, 'flash-info').present?

    # check that we can log out too
    @b.link(:text, 'Sign Out').click
    assert_equal 'Sign in using an existing account or as a guest', @b.li(:id, 'sign_in').text
  end

  def test_logging_in_as_guest_when_not_enabled
    delete_instance 'test'
    goto_instance 'test'
    load_test_fixture

    # before guest access
    goto '/'
    assert_equal 'Sign in using an existing account', @b.li(:id, 'sign_in').text

    # use the dew tools to try logging in as a guest
    goto_dev_page
    @b.button(:id, 'login_as_instance_guest').click

    # check that we are not logged in
    goto '/'
    assert_equal 'Sign in using an existing account', @b.li(:id, 'sign_in').text
  end

  def test_guest_sessions_ended_when_not_enabled
    delete_instance 'test'
    goto_instance 'test'
    load_test_fixture

    # get a user logged is as guest and then switch off guest access to the site
    login_as_instance_guest
    disable_guest_access

    # check that the guest session has now ended
    goto '/'
    assert_equal 'Sign in using an existing account', @b.li(:id, 'sign_in').text
  end

end
