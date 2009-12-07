class AddHtmlPageTitleToMifFile < ActiveRecord::Migration
  def self.up
    add_column :mif_files, :html_page_title, :string
  end

  def self.down
    remove_column :mif_files, :html_page_title
  end
end
