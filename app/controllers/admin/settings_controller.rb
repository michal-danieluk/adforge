module Admin
  class SettingsController < BaseController
    def show
      @app_config = AppConfig.current
    end

    def update
      @app_config = AppConfig.current
      if @app_config.save
        if @app_config.update(settings_params)
          redirect_to admin_settings_path, notice: "Settings updated successfully."
        else
          render :show, status: :unprocessable_entity
        end
      else
         render :show, status: :unprocessable_entity
      end
    end

    private

    def settings_params
      params.require(:app_config).permit(:gemini_api_key, :ai_model)
    end
  end
end
