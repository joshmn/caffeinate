# frozen_string_literal: true

require 'rails_helper'

describe Caffeinate::PeriodicalDrip do
  describe 'options' do
    class SomeFakePeriodicalDripper < ::Caffeinate::Dripper::Base
      default mailer_class: "TestMailer"

      periodical_drip :action_name, every: 2.hours, until: :rapture
    end

    it 'uses the method' do
      SomeFakePeriodicalDripper.drip_collection.for(:action_name)
      expect(SomeFakePeriodicalDripper.drip_collection.for(:action_name).every).to eq(2.hours)
    end
  end

  context 'validations' do

  end
end
