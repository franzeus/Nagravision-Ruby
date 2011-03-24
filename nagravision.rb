# Nagravision MMT09
require 'sinatra'
require 'erb'

get '/' do
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