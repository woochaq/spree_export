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
      address_column_names = ["address1", "firstname", "lastname", "zipcode", "city", "phone"]
      order_column_names = ["number", "email", "created_at", "total"]
      products_column_names = ["products", "product count"]
      billing_column_names = ["address1", "firstname", "lastname", "zipcode", "city", "phone"]
      column_headers = order_column_names + products_column_names + address_column_names + billing_column_names
      csv << column_headers
      all.each do |order|
        values = order.attributes.values_at(*order_column_names) + products(order) + products_quantity(order) +
          ship_address_values(order, address_column_names) + bill_values(order, billing_column_names)
        csv << values
      end
    end
  end

  private
    def products(order)
      [order.products.map{ |p| p.name }.join(',')]
    end

    def products_quantity(order)
      [order.line_items.map{ |p| p.quantity }.join(',')]
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
