class BrandsController < ApplicationController
  before_action :set_brand, only: %i[ show edit update destroy ]

  # GET /brands or /brands.json
  def index
    @brands = Brand.includes(:brand_colors).all
  end

  # GET /brands/1 or /brands/1.json
  def show
  end

  # GET /brands/new
  def new
    @brand = Brand.new
    # Build one default color for the form with primary set to true
    @brand.brand_colors.build(primary: true)
  end

  # GET /brands/1/edit
  def edit
  end

  # POST /brands or /brands.json
  def create
    @brand = Brand.new(brand_params)

    # Debug logging
    Rails.logger.info "="*60
    Rails.logger.info "BRAND CREATE ATTEMPT"
    Rails.logger.info "Params: #{brand_params.inspect}"
    Rails.logger.info "Brand colors count: #{@brand.brand_colors.size}"
    @brand.brand_colors.each_with_index do |c, i|
      Rails.logger.info "  Color #{i}: #{c.hex_value} primary=#{c.primary} destroy=#{c.marked_for_destruction?}"
    end
    Rails.logger.info "Brand valid? #{@brand.valid?}"
    Rails.logger.info "Brand errors: #{@brand.errors.full_messages}"
    Rails.logger.info "="*60

    respond_to do |format|
      if @brand.save
        format.html { redirect_to @brand, notice: "Brand was successfully created." }
        format.json { render :show, status: :created, location: @brand }
      else
        # If validation fails and there are no colors, add one for the form
        @brand.brand_colors.build(primary: true, hex_value: "#FF5733") if @brand.brand_colors.empty?
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @brand.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /brands/1 or /brands/1.json
  def update
    respond_to do |format|
      if @brand.update(brand_params)
        format.html { redirect_to @brand, notice: "Brand was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @brand }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @brand.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /brands/1 or /brands/1.json
  def destroy
    @brand.destroy!

    respond_to do |format|
      format.html { redirect_to brands_path, notice: "Brand was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_brand
      @brand = Brand.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def brand_params
      params.require(:brand).permit(
        :name,
        :tone_of_voice,
        :logo,
        brand_colors_attributes: [ :id, :hex_value, :primary, :_destroy ]
      )
    end
end
