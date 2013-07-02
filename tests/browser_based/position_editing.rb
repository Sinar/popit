# encoding: UTF-8
# coding: UTF-8
# -*- coding: UTF-8 -*-

require 'lib/popit_watir_test_case'
require 'lib/select2_helpers'
require 'pry'
require 'net/http'
require 'uri'


class MembershipEditingTests < PopItWatirTestCase

  include Select2Helpers

  def test_membership_creation
    run_as_all_user_types {
      |user_type|
      goto_instance 'test'
      delete_instance_database
      load_test_fixture
      login_as user_type
      goto '/persons/george-bush'
      
      def membership_form
        return @b.form(:name, "create-new-membership")
      end
      
      
      # click on the create new person link and check that the form has popped up    
      assert ! membership_form.present?
      @b.link(:text, '+ add a new membership').click
      membership_form.wait_until_present
      
      # Submit the form and check that it complains about missing role
      membership_form.submit
      assert_equal @b.ul(:class, 'error').text, "Role is required"
      
      # click on the role and select President
      select2_container('role').link.click
      assert_equal select2_highlighted_option.text, 'President'
      select2_highlighted_option.click
      assert_equal select2_current_value('role'), 'President'
      
      # click on the org and select us gov
      select2_container('organization_id').link.click
      assert_equal select2_highlighted_option.text, "United States Government ← select to use existing entry"
      select2_highlighted_option.click
      assert_equal select2_current_value('organization_id'), "United States Government"
      
      # set the start date, but leave the end date empty
      @b.input(:name, 'start_date').click
      @b.send_keys '2001-01-20'
      assert_equal @b.input(:name, 'start_date').value, '2001-01-20'
      
      # submit the form and check that the new membership is created
      membership_form.submit
      sleep 1 # WAIT UNTIL FORM DISAPPERS
      
      # check that the correct details have been entered
      @b.link(:xpath, "(//a[.='President'])[last()]").click
      assert_equal @b.article.h1.text, "President"
      assert_match @b.text, /Person:\ George\ Bush/
      assert_match @b.text, /Organization:\ United\ States\ Government/
      assert_match @b.text, /Start\ Date:\ 2001-01-20/
      assert_match @b.text, /End\ Date:\ Unknown/
          
      # go back to person page and check that the membership is now listed there
      goto '/persons/george-bush'
      assert_match @b.section(:class, 'memberships').text, /President/
      
      # create a new membership but with new role and organization
      @b.link(:text, '+ add a new membership').click
      membership_form.wait_until_present
      
      select2_container('role').link.click
      @b.send_keys 'Bottle Washer'
      assert_equal select2_highlighted_option.text, 'Bottle Washer'
      select2_highlighted_option.click
      assert_equal select2_current_value('role'), 'Bottle Washer'
      
      select2_container('organization_id').link.click
      @b.send_keys '1600 Penn Hotel'
      assert_equal select2_highlighted_option.text, "1600 Penn Hotel ← select to create new entry"
      select2_highlighted_option.click
      assert_equal select2_current_value('organization_id'), "1600 Penn Hotel (new entry)"
      
      membership_form.submit
      sleep 1 # XXX See above
      @b.link(:xpath, "(//a[.='Bottle Washer'])[last()]").click
      assert_equal @b.article.h1.text, "Bottle Washer"
      assert_match @b.text, /Person:\ George\ Bush/
      assert_match @b.text, /Organization:\ 1600\ Penn\ Hotel/
      
      # check that the new role and org are in the possible options
      goto '/persons/george-bush'
      @b.link(:text, '+ add a new membership').click
      membership_form.wait_until_present
      
      select2_container('role').link.click
      assert_equal select2_options(0).text, 'President'
      assert_equal select2_options(1).text, 'Bottle Washer'
      @b.send_keys :escape
      
      select2_container('organization_id').link.click
      assert_equal select2_options(0).text, "United States Government ← select to use existing entry"
      assert_equal select2_options(1).text, "1600 Penn Hotel ← select to use existing entry"
      @b.send_keys :escape
      
      @b.send_keys :escape
      @b.wait_until { ! membership_form.present? }
    }
  end


end
