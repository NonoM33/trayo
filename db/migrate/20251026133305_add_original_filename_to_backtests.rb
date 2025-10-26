class AddOriginalFilenameToBacktests < ActiveRecord::Migration[8.0]
  def change
    add_column :backtests, :original_filename, :string
  end
end
