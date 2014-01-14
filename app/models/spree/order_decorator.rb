require 'csv'
Spree::Order.instance_eval do

  def self.completed_between(start_date, end_date)
    where(completed_at: start_date..end_date)
  end

  def self.paid_and_ready_to_ship
    where(payment_state: 'paid', shipment_state: 'ready')
  end


  def self.export_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_headers
      all.each do |order|
        values = [order.number] + ship_address_values(order, address_column_names.values) + [order.email] +
          bill_values(order, billing_column_names.values) + [order.total] + [order.created_at] + products(order)
        csv << values
      end
    end
  end

  private
    def column_headers
      ["number"] + address_column_names.keys + ["email"] + billing_column_names.keys +
        ["order_amount_total"] + ["created_at"] + products_column_names
    end

    def address_column_names
      { "shipping_firstname" => "firstname", "shipping_lastname" => "lastname",
       "shipping_address" => "address1", "shipping_zipcode" => "zipcode",
       "shipping_city" => "city", "shipping_phone" => "phone"}
    end

    def billing_column_names
      {"billing_firstname" => "firstname", "billing_lastname" => "lastname",
       "billing_address" => "address1", "billing_zipcode" => "zipcode",
       "billing_city" => "city", "billing_phone" => "phone"}
    end

    def products_column_names
      Array.new(6) {|p| c = p+1; ["product_#{c}","product#{c}_quantity", "product#{c}_costprice", "product#{c}_masterprice"]}.flatten
    end

    def products(order)
      order.line_items.map{|i| [product_name(i), i.quantity, i.cost_price.to_s, i.price.to_s]}.flatten
    end

    def product_name(variant)
      variant.product.present? ? variant.product.name : "not exists"
    end

    def ship_address_values(order, address_column_names)
      if order.ship_address.present?
        order.ship_address.attributes.values_at(*address_column_names)
      else
        address_column_names.map{|i| ""}
      end
    end

    def bill_values(order, billing_column_names)
      if order.bill_address.present?
        order.bill_address.attributes.values_at(*billing_column_names)
      else
        billing_column_names.map{|i| ""}
      end
    end

end
