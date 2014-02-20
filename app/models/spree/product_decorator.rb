require 'csv'
Spree::Product.instance_eval do

  def self.export_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_headers
      all.each do |product|
        values = [
          product.id, product.sku, product_designer(product), product.available_on, product.name,
          description_tralsnaltion(product, :de), strip_tags(description_tralsnaltion(product, :de)),
          description_tralsnaltion(product, :en), strip_tags(description_tralsnaltion(product, :en)),
          description_tralsnaltion(product, :es), strip_tags(description_tralsnaltion(product, :es)),
          product.mpn, promotion(product), product.master.cost_price.to_s, product.master.cost_currency.to_s,
          count_margin_price(product), product.master.cost_currency, stock_count(product),
          variants(product)] + properties_with_empty_values(product) + [product_path(product),
          product_image_path(product)] + taxons_values(product)
        csv << values
      end
    end
  end

  private
    def count_margin_price(product)
      product.price.to_f - (product.cost_price.to_f * 1.19)
    end

    def promotion(product)
      promotion = product.promotions.select{|p| p.first == product.promotion_id}
      return "" if promotion.empty?
      promotion.flatten.last
    end

    def strip_tags(text)
      ActionController::Base.helpers.strip_tags(text)
    end

    def description_tralsnaltion(product, locale)
      translation = product.translations.select{|t| t.locale == locale}
      return "" if translation.empty?
      translation.first.description
    end

    def product_designer(product)
      property = product.product_properties.select{|p| p.property.name == "Designer"}
      return "" if property.empty?
      property.first.value
    end

    def product_path(product)
      ["/products", product.permalink].join
    end

    def product_image_path(product)
      product.images.first.attachment.url(:large)
    end

    def column_headers
      ["id", "SKU", "Designer", "available_on", "name", "description_html", "description", "description_en_html", "description_en",
        "description_es_html", "description_es", "mpn", "promotion", "master_price", "cost_price", "margin", "cost_currency", "stock",
        "variants"] + properties_column_names + ["permalink_product", "permalink_picture_1"] + taxons_column_names
    end

    def variants(product)
      product.variants.present? ? product.variants.map{|v| v.options_text}.join(',') : ""
    end

    def max_taxons_amount
      ordered = Spree::Product.reorder('spree_products.created_at').joins(:taxons).group('spree_products.id').count('spree_products_taxons.taxon_id').sort{|k,v| v[1]<=>k[1]}
      return 0 if ordered.empty?
      ordered.first.last
    end

    def taxons_column_names
      amount = max_taxons_amount
      return [] if amount == 0
      taxons = []
      amount.times {|n| taxons << "Taxon #{n+1}"}
      taxons
    end

    def taxons_values(product)
      product.taxons.map{|t| t.pretty_name }
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
