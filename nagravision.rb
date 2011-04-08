# Nagravision MMT09
require 'sinatra'
require 'RMagick'
require 'erb'

include Magick

get '/' do
  @im = ImageList.new("public/files/mmtodo_paint.png")
  #@pixels = @im.dispatch(0, 0, @im.columns, @im.rows, "RGB")
  blocks = 4 
  block_size = @im.rows / blocks
  block_min = 0 
  block_max = 50	 
  for i in 1..blocks
  block_min = (block_size * (i - 1)).ceil #THIS Line fucks the code up
  block_max = (block_size * i).ceil # (and this) | try a hardcoded nr for test
    for j in 0..block_max
      rand1 = block_min + rand(block_max).ceil
      rand2 = block_min + rand(block_max).ceil

      @line = @im.export_pixels(0, rand1, @im.columns, 1, "RGB");
      @other_line = @im.export_pixels(0, rand2, @im.columns, 1, "RGB")
      @im.import_pixels(0, rand2, @im.columns, 1, "RGB", @line)
      @im.import_pixels(0, rand1, @im.columns, 1, "RGB", @other_line)
    end
  end
#im.display

  erb :index
end

# ----------------------------------------
post '/upload' do

  @post = params[:post]
  @numberOfBlocks = params[:post][:blocks]
  
  @fileName = params[:post][:file][:filename]

  directory = "public/files"

  unless params[:post][:file] && (tmpfile = params[:post][:file][:tempfile]) && (@fileName)
      @error = "No file selected"
      return "Upload Error"#haml(:upload)
  end

  path = File.join(directory, @fileName)
  File.open(path, "wb") { |f| f.write(tmpfile.read) }

  erb :upload
end
