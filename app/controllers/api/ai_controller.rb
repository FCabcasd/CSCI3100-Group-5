module Api
  class AiController < BaseController
    def ask
      result = ai_service.answer_question(
        question: params[:question],
        user_context: {
          name: @current_user.full_name || @current_user.username,
          points: @current_user.points,
          role: @current_user.role
        }
      )
      render json: result
    end

    def recommend_venues
      result = ai_service.recommend_venues(
        requirements: params[:requirements],
        tenant_id: @current_user.tenant_id
      )
      render json: result
    end

    def check_conflicts
      venue = Venue.find_by(id: params[:venue_id])
      if venue && venue.tenant_id != @current_user.tenant_id
        render json: { error: "Access denied" }, status: :forbidden
        return
      end

      result = ai_service.check_booking_conflicts(
        venue_id: params[:venue_id],
        start_time: params[:start_time],
        end_time: params[:end_time]
      )
      render json: result
    end

    def status
      render json: {
        available: ai_service.available?,
        message: ai_service.available? ? "AI consultant is ready" : "Please configure GEMINI_API_KEY"
      }
    end

    private

    def ai_service
      @ai_service ||= AiConsultantService.new
    end
  end
end
