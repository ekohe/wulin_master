# wulin_queue -- Solid Queue's job tables plus screens over them.
#
# Its migration IS Solid Queue's schema, so never run solid_queue:install
# alongside it, and never mount WulinQueue::Engine -- config/routes.rb draws
# into the host app directly.

wulin_vendor "wulin_queue", "develop"

wulin_js "../../vendor/gems/wulin_queue/app/assets/javascripts/wulin_queue.esm.js"

# Run the Solid Queue supervisor inside puma — no separate jobs process.
file "config/puma.rb", <<~RB, force: true
  threads_count = ENV.fetch("RAILS_MAX_THREADS", 2)
  threads threads_count, threads_count

  port ENV.fetch("PORT", 3000)

  plugin :solid_queue
RB

wulin_menu <<~RB
  submenu "Background Jobs" do
    item SolidQueueJobScreen, icon: :work
    item SolidQueueQueueScreen, icon: :layers
    item SolidQueueProcessScreen, icon: :memory
    item SolidQueueRecurringTaskScreen, icon: :repeat
  end
RB

wulin_note "wulin_queue: its migration creates Solid Queue's tables, so do not run solid_queue:install -- that generator would write a competing schema"
