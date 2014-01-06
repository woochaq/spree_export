Spree::Admin::ProductsController.class_eval do
  def export_csv
    @products = Spree::Product.order('created_at')
    send_data @products.export_csv({col_sep: '|'}), filename: "products_#{Date.today}.csv"
  end
end
