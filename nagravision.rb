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

  @alrdy_incl = Array.new
  err_count = 0

  for block_count in 0...@numberOfBlocks.to_i
#  for block_count in 0...1
    this_block_min = block_count * block_size
    this_block_max = (block_count + 1) * block_size

    processed_line = this_block_min

    #for i in this_block_min...this_block_max
    for i in this_block_min..this_block_max
      @comp_arr[i] = Hash.new
      @comp_arr[i][:value] = 100
      @comp_arr[i][:line] = processed_line
      @line = @im.export_pixels(0, 0, @im.columns, 1, "RGB")
      @im1.import_pixels(0,0,@im.columns, 1, "RGB", @line)
  
      @alrdy_incl << processed_line
      puts "processing and including #{processed_line}"
      current_block = processed_line.to_i / block_size
      #puts "the current block is #{current_block}"
      # find best line within block
      for j in this_block_min..this_block_max
        #puts "proc is #{processed_line} and j is #{j}"
        if(processed_line == j)
          next
        else
          @other_line = @im.export_pixels(0, j, @im.columns, 1, "RGB")
          @im2.import_pixels(0,0,@im.columns, 1, "RGB", @other_line)

          diff = @im1.difference(@im2)
          
          if(diff[1] < @comp_arr[i][:value] && !@alrdy_incl.include?(j))
            @alrdy_incl.delete(@comp_arr[i][:best_old_ind])
            #puts "removing #{@comp_arr[i][:best_old_ind]}"
            #puts "including #{j}"
            @alrdy_incl << j
            @comp_arr[i][:value] = diff[1]
            @comp_arr[i][:best_old_ind] = j
          end
        end
      end
      if !@comp_arr[i][:best_old_ind]
       #puts "no new val"
      else
        #puts "okey"
      end
      processed_line = @comp_arr[i][:best_old_ind]
      #puts "#{i} in #{@comp_arr[i][:best_old_ind]} with #{@comp_arr[i][:value]}"
    end
  end
  #@alrdy_incl.sort!
  ext_counter = 0
  for i in 0..(@comp_arr.size - 1)
    if(!@comp_arr[i])
      puts "empty"
      break
    elsif !@comp_arr[i][:best_old_ind]
      puts "empty line"
      break
    elsif !ext_counter
      break
    end
    #if(ext_counter && @comp_arr[ext_counter][:best_old_ind])
      tmp_line = @im.export_pixels(0, ext_counter, @im.columns, 1, "RGB")
      @decoded_img.import_pixels(0, i, @decoded_img.columns, 1, "RGB", tmp_line)

      ext_counter = @comp_arr[ext_counter][:best_old_ind]
      #puts "ext counter is #{ext_counter}"
      #ext_counter = @comp_arr[ext_counter][:best_old_ind]
    #else
      #while(!ext_counter)
     # ext_counter = @comp_arr[]
    #end
    
  end

  #puts @comp_arr.select {|c| c[:best_old_ind] == 999 }

  dec_path = File.join(directory, "dec_" + @fileName)
  @decoded_img.write(dec_path)

  erb :upload
end
