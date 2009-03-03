class ConfirmationsController < ApplicationController
  
  def confirm_email
    if validation = PendingValidation.find_by_key(params[:key]) #deliberately = not == :)
      validation.destroy
    else
      render :template => "confirmations/not_found"
    end
  end
end
