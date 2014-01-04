Spree::Admin::OrdersController.class_eval do
  def export_csv
    created_at_gt = Time.zone.parse(params[:created_at_gt]).beginning_of_day rescue ""
    created_at_lt = Time.zone.parse(params[:created_at_lt]).end_of_day rescue ""

    if created_at_gt.present? and created_at_lt.present?
      @orders = Spree::Order.paid_and_ready_to_ship.completed_between(created_at_gt, created_at_lt).order("created_at")
    else
      @orders = Spree::Order.order("created_at")
    end
    send_data @orders.export_csv, filename: "orders.csv"
  end
end
