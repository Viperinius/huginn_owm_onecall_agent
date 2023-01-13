require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::OwmOnecallAgent do
  before(:each) do
    @valid_options = Agents::OwmOnecallAgent.new.default_options
    @checker = Agents::OwmOnecallAgent.new(:name => "OwmOnecallAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
