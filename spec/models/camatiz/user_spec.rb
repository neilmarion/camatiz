require "rails_helper"

module Camatiz
  describe User do
    specify do
      user = User.create(name: "Neil", slack_id: "UDZZ")
      channel = user.created_channels.create

      user.reload
      expect(user.created_channels.first.name).to eq "Neil's channel 1"
      expect(user.subscribed_channel.name).to eq "Neil's channel 1"
      expect(channel.subscribers).to eq [user]
    end
  end
end
