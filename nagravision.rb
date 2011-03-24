# Nagravision MMT09
require 'sinatra'
require 'RMagick'
require 'erb'

include Magick

get '/' do
  erb :index
end

post '/upload' do

  @post = params[:post]
  @numberOfBlocks = params[:post][:blocks]
  directory = "public/files"

  unless params[:post][:file] && (tmpfile = params[:post][:file][:tempfile]) && (name = params[:post][:file][:filename])
      @error = "No file selected"
      return "Upload Error"#haml(:upload)
  end

  path = File.join(directory, name)
  File.open(path, "wb") { |f| f.write(tmpfile.read) }

  erb :upload
end
