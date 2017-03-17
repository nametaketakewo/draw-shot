class Image

  Dir.glob(Rails.root.join('public/lists/*.rb')).map do |f|
    eval(`cat #{f.gsub(' ', '\ ')}`)
  end

  include ActiveModel::Model
  include ActiveModel::Serialization

  attr_accessor :id, :url, :path, :file_name, :magick, :white_list, :black_list
  class_attribute :cache

  define_model_callbacks :compare

  before_compare :read_list, if: -> {white_list.blank? && black_list.blank?}

  self.cache = {}

  def initialize
    @id = nil
    @url = nil
    @path = nil
    @file_name = nil
    @magick = nil
    @white_list = []
    @black_list = []
  end

  def self.find(id)
    cache = self.cache[id]
    return cache if cache
    path = Rails.root.join('public/images/%{id}.png' % {id: id}).to_s
    return File.exist?(path) ? path_2_image(path) : nil
  end

  def self.all
    Dir.glob(Rails.root.join('public/images/*.png')).map do |f|
      path_2_image(f)
    end
  end

  def self.path_2_image(path)
    image = self.cache[path.split('/').last.split('.').first]
    return image if image
    image = self.new
    image.path = path
    image.url = path.split('/')[-2, 2].join('/')
    image.file_name = path.split('/').last
    image.id = path.split('/').last.split('.').first.to_i
    image.magick = image.get_magick
    self.cache[image.id] = image
  end

  def get_magick
    File.exist?(self.path) ? Magick::Image.read(path).first : nil
  end

  def read_list
    @white_list = eval('@@whites_' + id.to_s)
    @black_list = eval('@@blacks_' + id.to_s)
  end

  def caliculate_list

    blacks = []
    whites = []

    magick.rows.times do |x|
      magick.columns.times do |y|
        pixel_color = self.magick.pixel_color(x, y)
        color = pixel_color.to_color
        opacity = pixel_color.opacity
        blacks << [x,y] if color == 'black' && 10000 > opacity
        whites << [x,y] if color == 'white' || 60000 <= opacity
      end
    end
    [blacks, whites]
  end

  def self.lists_export(black = nil, white = nil)
    Image.all.length.times do |i|
      image = Image.find(i + 1)
      blacks, whites = image.caliculate_list
      File.write(Rails.root.join('public', 'lists', "black_#{i + 1}.rb"), "@@blacks_#{i + 1} = " + (black ? blacks.sample(black) : blacks).to_s)
      File.write(Rails.root.join('public', 'lists', "white_#{i + 1}.rb"), "@@whites_#{i + 1} = " + (white ? whites.sample(white) : whites).to_s)
    end
  end

  def compare(challenger)
    run_callbacks(:compare)
    {per: compare_rate(challenger), merged_image_url: merge_image(challenger)}
  end

  def compare_rate(challenger)
    white_per = 0
    white_list.each do |pixel|
      white_per += 1 if challenger.pixel_color(*pixel).to_color == 'white'
    end
    black_per = 0
    black_list.each do |pixel|
      color = challenger.pixel_color(*pixel).to_color
      black_per += 1 if color == 'black' || color == '#111111111111'
    end
    gain = (ENV['SIGMOID_GAIN'] || 2).to_i
    param = (black_per / black_list.length.to_f * 3 - ( white_list.length - white_per) / white_list.length.to_f) - 1.0
    ((1.0 / (1.0 + Math.exp(-gain * param))) * 100).ceil
  end

  def merge_image(challenger)
    write_name = SecureRandom.urlsafe_base64 + '.png'
    write_path = Rails.root.join('public', 'merged_images', write_name)
    material = Magick::Image.read(Rails.root.join('public', 'materials', self.file_name)).first
    merged = challenger.composite!(material, Magick::SouthWestGravity, Magick::OverCompositeOp)
    merged.write(write_path)
    merged.destroy!
    'merged_images/' + write_name
    # 'hogehoge'
    # material = Magick::Image.new(magick.columns, magick.rows)
    # hoge.each_pixel do |pixel, x, y|
    #   if pixel.to_color == 'black'
    #     material.pixel_color(x, y, 'red')
    #   else
    #     material.pixel_color(x, y, 'white')
    #   end
    # end
  end
end
