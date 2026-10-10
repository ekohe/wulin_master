# frozen_string_literal: true

module WulinMaster
  # Is there a signed-in user? An app that installs no auth gem does not define `current_user` at
  # all, so asking for it raises NameError rather than answering nil.
  #
  # NOT the same question as a bare `respond_to?(:current_user)`, which Authorization#require_authorization
  # and FetchOptionsController#authorized? ask to find out whether this app enforces authorization
  # at all. Those two mean "no auth layer, let everything through", and must keep answering that for
  # a logged-out user of an app that has one.
  module HostUser
    def current_user?
      respond_to?(:current_user) && !current_user.nil?
    end
  end
end
