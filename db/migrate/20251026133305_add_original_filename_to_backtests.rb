class AddOriginalFilenameToBacktests < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:backtests, :original_filename)
      add_column :backtests, :original_filename, :string
    end
  end
end
