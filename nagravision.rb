# Nagravision MMT09
require 'rubygems'
require 'sinatra'
require 'RMagick'
require 'erb'

include Magick

get '/' do
=begin
  @im = ImageList.new("public/files/testscreen.png")
  #@pixels = @im.dispatch(0, 0, @im.columns, @im.rows, "RGB")
  blocks = 4 
  block_size = (@im.rows / blocks).to_int

  for i in 0..(blocks - 1)
    for j in 0..block_size
      rand1 = block_size * i + rand(block_size).to_int
      rand2 = block_size * i + rand(block_size).to_int

      @line = @im.export_pixels(0, rand1, @im.columns, 1, "RGB");
      @other_line = @im.export_pixels(0, rand2, @im.columns, 1, "RGB")
      @im.import_pixels(0, rand2, @im.columns, 1, "RGB", @line)
      @im.import_pixels(0, rand1, @im.columns, 1, "RGB", @other_line)
    end
  end
#im.display
=end

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
  
  @im = ImageList.new(path)

  blocks = @numberOfBlocks.to_i
  block_size = (@im.rows / blocks)
  block_min = 0
  block_max = 50
  for i in 0...blocks
    block_min = block_size * i
    block_max = block_size * (i + 1) 

    for j in block_min..block_max
      rand1 = block_min + rand(block_max - block_min).ceil
      rand2 = block_min + rand(block_max - block_min).ceil

      @line = @im.export_pixels(0, rand1, @im.columns, 1, "RGB");
      @other_line = @im.export_pixels(0, rand2, @im.columns, 1, "RGB")
      @im.import_pixels(0, rand2, @im.columns, 1, "RGB", @line)
      @im.import_pixels(0, rand1, @im.columns, 1, "RGB", @other_line)
    end
  end 

  new_path =  File.join(directory, "new_" + @fileName)   
  @new_filename = "new_" + @fileName

  @im.write(new_path) 

  #we know the amount of blocks
  #first: we know all pixels per line
  #later: how many pixels do we need to know

  @im1 = Image.new(@im.columns, 1)
  @im2 = Image.new(@im.columns, 1)
  
  @decoded_img = Image.new(@im.columns, @im.rows)

  @comp_arr = Array.new(@im.rows) { Hash.new }
  @comp_arr.each do |comp|
    comp[:best_old_ind] = -1
  end

  alrdy_incl = Array.new
 
  for block_count in 0...@numberOfBlocks.to_i
    this_block_min = block_count * block_size
    this_block_max = (block_count + 1) * block_size

    for i in this_block_min..this_block_max
      @comp_arr[i] = Hash.new
      @comp_arr[i][:value] = 100
      @line = @im.export_pixels(0, i, @im.columns, 1, "RGB")
      @im1.import_pixels(0,0,@im.columns, 1, "RGB", @line)

      for j in this_block_min..this_block_max
        if(i == j)
          next
        end

        @other_line = @im.export_pixels(0, j, @im.columns, 1, "RGB")
        @im2.import_pixels(0,0,@im.columns, 1, "RGB", @other_line)

        diff = @im1.difference(@im2)
      
        if(diff[1] < @comp_arr[i][:value] && !alrdy_incl.include?(j)) 
          alrdy_incl << j
          @comp_arr[i][:value] = diff[1]
          @comp_arr[i][:best_line] = @other_line
          @comp_arr[i][:best_old_ind] = j
        end
      end
      puts "#{i} in #{@comp_arr[i][:best_old_ind]} with #{@comp_arr[i][:value]}"
    end
  end

  ext_counter = 0
  for i in 0...@decoded_img.rows
    #puts "Importing #{ext_counter}"
    #puts @comp_arr[ext_counter][:best_old_ind]
  
    if(@comp_arr[i][:best_old_ind])
      @decoded_img.import_pixels(0, i, @decoded_img.columns, 1, "RGB", @comp_arr[i][:best_line])
    end
    #ext_counter = @comp_arr[ext_counter][:best_old_ind]
  end

  #puts @comp_arr.select {|c| c[:best_old_ind] == 999 }

  dec_path = File.join(directory, "dec_" + @fileName)
  @decoded_img.write(dec_path)

  erb :upload
end
