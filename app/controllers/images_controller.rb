class ImagesController < ApplicationController
  def index
    render json: Image.all
  end

  def compare
    #render json: {per: 32, merge_image_url: 'merged_images/2b5daSNtTe2MThyQQyi0Qg.png'}
    example = Image.find(params[:id])
    challenger = Magick::Image.from_blob(params[:image].read).first
    render json: example.compare(challenger)
  end
end
