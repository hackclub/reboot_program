module Api
  module V1
    module Admin
      class ItemSuggestionsController < ApplicationController
        before_action :require_admin

        def update
          suggestion = ItemSuggestion.find(params[:id])
          new_status = params.dig(:suggestion, :status) || params[:status]

          unless ItemSuggestion::STATUSES.include?(new_status)
            render json: { error: "Invalid status" }, status: :unprocessable_entity
            return
          end

          if suggestion.update(status: new_status)
            render json: { message: "Status updated", suggestion: suggestion.as_json }
          else
            render json: { errors: suggestion.errors.full_messages }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Suggestion not found" }, status: :not_found
        end

        private

        def require_admin
          @current_user = User.find_by(id: session[:user_id]) if session[:user_id]
          unless @current_user&.admin?
            render json: { error: "Admin access required" }, status: :forbidden
          end
        end
      end
    end
  end
end
