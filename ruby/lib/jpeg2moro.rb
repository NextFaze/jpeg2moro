
require 'rubygems'
require 'zlib'
gem 'rmagick'
require 'RMagick'
include Magick

class JPEG2moro
  DEBUG = 1

  class << self
    attr_accessor :debug
  end

  def initialize(options = {})
    if options.kind_of?(Hash) 
      @file = options[:file]
      @data = options[:data]
    else
      @file = options
    end

    @data = File.read(@file) if @file
    debug "read %d bytes" % [@data.length]
  end

  def self.with_data(data)
    return JPEG2moro.new(:data => data)
  end

  # convert data to jpeg2moro format
  def convert(options = {})
    @convert_options = options
    @convert_options[:depth] ||= 1

    # convert image data to jpg format
    img = Image.from_blob(@data).first
    jpeg_data = img.to_blob { |i|
      i.quality = 70
      i.format = 'jpg'
    }
    # insert alpha channel into jpeg data
    insert_opacity_header(jpeg_data)

    # return jpeg2moro object (contains alpha channel)
    return JPEG2moro.new(:data => jpeg_data)
  end

  def to_s
    @data
  end

 # private

  def debug(msg)
    puts msg if self.class.debug
  end

  def debug_dump(data, filename)
    if self.class.debug
      File.open(filename, "w") { |f| f.print data }
    end
  end

  def standalone_marker(marker)
    (marker >= 0xd0 && marker <= 0xd7) ||  # RST
      marker == 0xd8 || marker == 0xd9  || # SOI/EOI
      marker == 0x01  # TEM
  end

  # find position to insert opacity information
  def insert_position(jpeg_data)
    # parse jpeg data
    data = jpeg_data
    pos = 0
    while pos < data.length
      marker1 = data[pos]
      marker2 = data[pos + 1]

      return -1 if marker1 != 0xff  # parse error
      if marker2 == 0xff
        # packed marker
        pos += 1
        next
      end

      if marker2 == 0xda || marker2 == 0xd9
        # SOS (start of scan) or EOI (end of image)
        # insert before this marker
        debug "found insert position: %d (marker %x)" % [pos, marker2]
        return pos
      end

      pos += 2
      next if standalone_marker(marker2)

      mlength = data[pos, 2].unpack('C2').reverse.pack('C2').unpack('S').first
      pos += mlength

      debug "marker: %x, length: %d" % [marker2,  mlength]
    end
  end

  # create opacity header
  def create_opacity_header
    img = Image.from_blob(@data).first  # original image data
    bit_depth = @convert_options[:depth]
    bit_depth = bit_depth.to_i

    debug "using bit depth: %d" % [bit_depth]

    img.set_channel_depth(AlphaChannel, bit_depth)
    alpha = img.separate(OpacityChannel)
    #alpha.set_channel_depth(DefaultChannels, 1)
    #alpha.display
    storage = bit_depth == 16 ? ShortPixel : CharPixel
    data = alpha.export_pixels_to_str(0, 0, alpha.columns, alpha.rows,
                                      "A", storage)

    debug_dump(alpha.to_blob, "alpha.png")

    if bit_depth == 1
      # pack into bit string
      data = data.unpack('C*').map { |i| i == 0xff ? 1 : 0 }.join
      data = [data].pack("B*")
    end

    debug_dump(data, "pixel.dat")

    deflated = Zlib::Deflate.deflate(data, 9)
    #deflated = deflated[2..-5]  # strip header/footer?
    debug "deflated size: %d bytes" % [deflated.length]

    debug_dump(deflated, "compressed.dat")

    # create header
    # segment length includes 1 byte for bit depth info + 2 bytes for length param
    mlength = deflated.length + 1 + 2 
    header = [0xff, 0xe9].pack("C*")  # APP10 marker
    header += [mlength].pack("S").unpack("C*").reverse.pack("C*")
    header += [bit_depth].pack("C")
    header += deflated

    debug "alpha segment length: %d" % [mlength]
    debug_dump(header, "header.dat")

    header
  end

  def insert_opacity_header(jpeg_data)
    offset = insert_position(jpeg_data)
    header = create_opacity_header
    jpeg_data.insert(offset, header)
  end
end
