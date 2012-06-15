module TransactionHistoryHelper
  def row_class(order_detail)
    needs_reconcile_warning?(order_detail) ? 'reconcile-warning' : ''
    # if @warning_method
      # @warning_method.call(self, order_detail) ? 'reconcile-warning' : ''
    # else
      # ''
    # end
  end
  
  def product_options(products, search_fields)
    search_fields.map! { |i| i.to_s } if search_fields
    options = []
    products.each do |product|
      options << [product.name, product.id, { :"data-facility" => product.facility.id, 
                                              :"data-restricted" => product.requires_approval ? false : true, # Ruby 1.8 outputs 0/1 instead of true/false
                                              :"data-product-type" => product.type.downcase}]
    end
    options_for_select options, :selected => search_fields
  end
  
  def chosen_field(field, label, value_field = "id", label_field = "name", from_collection_method = nil)
    var = instance_variable_get("@#{field}")
    enabled = var && var.size > 1
    @search_fields[field] = [var.first.send(value_field.to_sym)] if value_field and var.size == 1
    html = "<li class=\"#{enabled ? '' : 'disabled'}\">"
    html << (label_tag field, label.pluralize)
    from_collection = from_collection_method ? self.send(from_collection_method, var, @search_fields[field]) : options_from_collection_for_select(var, value_field, label_field, @search_fields[field])
    options = {:multiple => true, :"data-placeholder" => "Select #{label.pluralize.downcase}"}
    options.merge!({:disabled => :disabled}) unless enabled
    html << (select_tag field, from_collection, options)
    html << "</li>"
    html.html_safe
  end
  
end
