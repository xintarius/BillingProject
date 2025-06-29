class AddOcrStepImagePhaseToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :ocr_image_phase, :string
  end
end
