# Rake tasks for syncing data to Airtable (unified DB).
namespace :sync do
  desc "Sync all users to Airtable"
  task users: :environment do
    puts "Syncing users to Airtable..."
    count = 0
    User.find_each do |user|
      Airtable::UserSyncJob.new.send(:sync_single_record, user)
      count += 1
      print "." if count % 10 == 0
    end
    puts "\nDone! Synced #{count} users."
  end

  desc "Sync all shop orders to Airtable"
  task shop_orders: :environment do
    puts "Syncing shop orders to Airtable..."
    count = 0
    ShopOrder.find_each do |order|
      Airtable::ShopOrderSyncJob.new.send(:sync_single_record, order)
      count += 1
      print "." if count % 10 == 0
    end
    puts "\nDone! Synced #{count} shop orders."
  end

  desc "Pull shop items from Airtable"
  task shop_items: :environment do
    puts "Pulling shop items from Airtable..."
    Airtable::ShopItemPullJob.perform_now
    puts "Done! Pulled #{ShopItem.count} shop items."
  end

  desc "Run all sync tasks"
  task all: :environment do
    Rake::Task["sync:shop_items"].invoke
    Rake::Task["sync:users"].invoke
    Rake::Task["sync:shop_orders"].invoke
  end

  desc "Run sync in background (enqueues jobs)"
  task enqueue: :environment do
    puts "Enqueueing sync jobs..."
    Airtable::ShopItemPullJob.perform_later
    Airtable::UserSyncJob.perform_later
    Airtable::ShopOrderSyncJob.perform_later
    puts "Jobs enqueued. Check SolidQueue for progress."
  end
end
