# Nagravision MMT09
require 'sinatra'
require 'RMagick'
require 'erb'

include Magick

get '/' do
  @im = ImageList.new("public/files/mmtodo_paint.png")
  @pixels = @im.dispatch(0, 0, @im.columns, @im.rows, "RGB")
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
