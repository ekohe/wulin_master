# WulinExcel
MAXIMUM_NUMBER_OF_ROWS = 65535

if !Object.const_defined?(:WulinMaster)
  raise "WulinExcel needs WulinMaster. Make sure WulinExcel is loaded after WulinMaster configuring config.plugins properly in application.rb"
end

# Add default export excel button to every grid
WulinMaster::Grid.add_to_default_toolbar "Excel", :class => 'excel_export', :icon => 'excel'

# Load excel javascript
WulinMaster::add_javascript "excel/excel.js"

# Register xls mime type
Mime::Type.register "application/vnd.ms-excel", :xls

module WulinMaster
  module Actions
    def render_xls
      @excel_columns = []
      params[:columns].each do |column|
        @excel_columns << grid.columns.find{|col| col.name.to_s == column["name"].to_s }
      end
      @excel_columns.compact! # In case there's a column passed in the params[:column] that doesn't exist
      
      # Create initial query object
      @query = grid.model

      # Add the necessary where statements to the query
      construct_filters

      fire_callbacks :query_filters_ready

      # Always add a limit and offset
      @query = @query.limit(MAXIMUM_NUMBER_OF_ROWS).offset(0)

      # Add order
      parse_ordering
      
      # Add select
      add_select
      
      fire_callbacks :query_ready

      # Get all the objects
      @objects = @query.all
      
      filename = File.join(Rails.root, 'tmp', "export-#{ Time.now.strftime("%Y-%m-%d-at-%H-%M-%S") }.xls")
      workbook = WriteExcel.new(filename)
      worksheet  = workbook.add_worksheet

      header_format = workbook.add_format
      header_format.set_bold
      header_format.set_align('top')
      worksheet.set_row(0, 16, header_format)

      params[:columns].each_with_index do |column, index|
        column_from_grid = grid.columns.find{|col| col.name.to_s == column["name"].to_s}
        label_text = column_from_grid.nil? ? column["name"] : column_from_grid.label

        worksheet.write_string(0, index, label_text)
        worksheet.set_column(index, index,  column["width"].to_i/6)
      end

      i = 1
      
      @objects.each do |object|
        j = 0
        worksheet.set_row(i, 16)
        @excel_columns.each do |column|
          value = column.format(object.read_attribute(column.name.to_s)).to_s
          value.gsub!("\r", "") # Multiline fix
          worksheet.write_string(i, j, value)
          j += 1
        end
        i += 1
      end
      workbook.close
      send_data File.read(filename)
    end
  end
end
