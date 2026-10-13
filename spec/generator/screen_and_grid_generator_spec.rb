# frozen_string_literal: true

require "spec_helper"
require "rails/generators"
require "./lib/generators/wulin_master/screen_and_grid/screen_and_grid_generator"

describe WulinMaster::ScreenAndGridGenerator do
  around do |example|
    Dir.mktmpdir do |root|
      @root = root
      example.run
    end
  end

  def generate(*args)
    capture_output { described_class.start([*args, "--no-routes"], destination_root: @root) }
  end

  def capture_output
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  def migration
    File.read(Dir[File.join(@root, "db/migrate/*_create_members.rb")].first)
  end

  def model
    File.read(File.join(@root, "app/models/member.rb"))
  end

  def grid
    File.read(File.join(@root, "app/grids/member_grid.rb"))
  end

  it "makes a reference a foreign key the model belongs to" do
    generate "Member", "first_name:string", "team:references"

    expect(migration).to include("t.references :team, null: false, foreign_key: true")
    expect(migration).to include("t.string :first_name")
    expect(model).to include("belongs_to :team")
    expect(model).not_to include("optional: true")
    expect(grid).to include("column :team")
  end

  it "lets a reference stay optional" do
    generate "Member", "team:references{optional}"

    expect(migration).to include("t.references :team, foreign_key: true")
    expect(migration).not_to include("null: false")
    expect(model).to include("belongs_to :team, optional: true")
  end

  it "does not add a foreign key for a polymorphic reference" do
    generate "Member", "owner:references{polymorphic}"

    expect(migration).to include("t.references :owner, polymorphic: true, null: false")
    expect(migration).not_to include("foreign_key: true")
    expect(model).to include("belongs_to :owner, polymorphic: true")
  end

  it "starts every Ruby file it writes with the frozen string literal comment" do
    generate "Member", "first_name:string"

    files = Dir[File.join(@root, "{app,db}/**/*.rb")]
    expect(files.size).to eq(5)
    files.each { |file| expect(File.read(file)).to start_with("# frozen_string_literal: true\n") }
  end

  it "writes the migration for the running Rails" do
    generate "Member", "first_name:string"

    expect(migration).to include("ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]")
    expect(model).not_to include("belongs_to")
  end
end
