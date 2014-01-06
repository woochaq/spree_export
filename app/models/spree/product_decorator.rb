require 'csv'
Spree::Product.instance_eval do

  def self.export_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_headers
      all.each do |product|
        values = product.attributes.values_at(*%w{name permalink}) + [product.price.to_s, product.master.cost_price.to_s, product.master.cost_currency.to_s] +
          [product.available_on, product.sku, product.weight.to_s, product.height.to_s, product.width.to_s, product.depth.to_s, variants(product)] +
           properties_with_empty_values(product) + [stock_count(product)]
        csv << values
      end
    end
  end

  private
    def column_headers
      ["name", "permalink", "master_price", "cost_price", "cost_currency", "available_on", "SKU", "weight",
       "height", "width", "depth", "variants"] + properties_column_names + ["stock"]
    end

    def variants(product)
      product.variants.present? ? product.variants.map{|v| v.options_text}.join(',') : ""
    end

    def properties_column_names
      Spree::Property.all.map{ |p| p.name }
    end

    def properties_with_empty_values(product)
      product_properties(product).map { |p| p.present? ? p : "" }.flatten
    end

    def product_properties(product)
      [].tap do |properties|
        Spree::Property.all.each do |prop|
          properties << product.product_properties.select{ |p| p.property_id == prop.id }.map do |p|
            p.present? ? p.value : ""
          end
        end
      end
    end

    def stock_count(product)
      product.stock_items.sum { |s| s.count_on_hand }
    end

end
