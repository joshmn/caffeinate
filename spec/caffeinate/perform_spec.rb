require 'rails_helper'

describe Caffeinate::Perform do
  context 'when config is nil' do
    before do
      Caffeinate.config.enabled_drippers = nil
    end
    let!(:campaign) { create(:caffeinate_campaign, :with_dripper) }
    it 'runs all the drippers' do
      expect_any_instance_of(campaign.to_dripper).to receive(:perform!)

      Caffeinate.perform!
    end
  end

  context 'when config has the dripper' do
    let!(:campaign) { create(:caffeinate_campaign, :with_dripper) }
    before do
      Caffeinate.config.enabled_drippers = [campaign.to_dripper.name]
    end
    it 'runs all the drippers' do
      expect_any_instance_of(campaign.to_dripper).to receive(:perform!)

      Caffeinate.perform!
    end
  end
end
