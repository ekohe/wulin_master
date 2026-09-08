# wulin_queue -- Solid Queue's job tables plus nine screens over them.
#
# Its migration IS Solid Queue's schema, so never run solid_queue:install
# alongside it, and never mount WulinQueue::Engine -- config/routes.rb draws
# into the host app directly.

wulin_vendor "wulin_queue", "develop"

# app/assets/javascripts/wulin_queue.js is a Sprockets manifest (//= require
# plus require_tree), which esbuild cannot read, so the files it names are
# imported directly. action_helpers first: every action builds on it.
queue_js = "../../vendor/gems/wulin_queue/app/assets/javascripts/wulin_queue"
wulin_js "#{queue_js}/action_helpers.js",
  *%w[clear discard discard_all pause resume retry retry_all run_now show_error]
    .map { |action| "#{queue_js}/actions/#{action}.js" }

wulin_menu <<~RB
  submenu "Background Jobs" do
    item SolidQueuePendingJobScreen, icon: :hourglass_empty
    item SolidQueueInProgressJobScreen, icon: :autorenew
    item SolidQueueBlockedJobScreen, icon: :block
    item SolidQueueFailedJobScreen, icon: :error_outline
    item SolidQueueScheduledJobScreen, icon: :schedule
    item SolidQueueFinishedJobScreen, icon: :done_all
    item SolidQueueProcessScreen, icon: :memory
    item SolidQueueRecurringTaskScreen, icon: :repeat
    item SolidQueueQueueScreen, icon: :layers
  end
RB

wulin_note "wulin_queue: its migration creates Solid Queue's tables, so do not run solid_queue:install -- that generator would write a competing schema"
