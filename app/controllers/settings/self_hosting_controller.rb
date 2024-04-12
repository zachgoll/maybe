class Settings::SelfHostingController < ApplicationController
  def edit
    redirect_to edit_settings_path unless self_hosted?
  end

  def update
    render "settings/edit", status: :forbidden and return unless self_hosted?

    if all_updates_valid?
      self_hosting_params.keys.each do |key|
        Setting.send("#{key}=", self_hosting_params[key].strip)
      end

      redirect_to edit_settings_self_hosting_path, notice: "Settings updated successfully."
    else
      flash.now[:error] = @errors.first.message
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def all_updates_valid?
      @errors = ActiveModel::Errors.new(Setting)
      self_hosting_params.keys.each do |key|
        setting = Setting.new(var: key)
        setting.value = self_hosting_params[key].strip

        unless setting.valid?
          @errors.merge!(setting.errors)
        end
      end

      if self_hosting_params[:auto_upgrades_target] != "none" && self_hosting_params[:render_deploy_hook].blank?
        @errors.add(:render_deploy_hook, "Render deploy hook must be provided to enable auto upgrades")
      end

      @errors.empty?
    end

    def self_hosting_params
      params.require(:setting).permit(:render_deploy_hook, :auto_upgrades_target)
    end
end