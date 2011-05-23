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

  # ...........................................................
  # we know the amount of blocks
  # first: we know all pixels per line
  # later: how many pixels do we need to know

  @im1 = Image.new(@im.columns, 1)
  @im2 = Image.new(@im.columns, 1)
  
  @decoded_img = Image.new(@im.columns, block_size)

  @comp_arr = Array.new(block_size) { Array.new(block_size) { Hash.new} }

  alrdy_incl = Array.new


  #1 finde erste linie
  for i in 0..(block_size - 1)
    line = @im.export_pixels(0, i, @im.columns, 1, "RGB")
    @im1.import_pixels(0,0,@im.columns, 1, "RGB", line)

    for j in 0..(block_size -1)
      if(i == j)
        next
      else
        other_line = @im.export_pixels(0, j, @im.columns, 1, "RGB")
        @im2.import_pixels(0,0,@im.columns, 1, "RGB", other_line)
        diff = @im1.difference(@im2)
        @comp_arr[i][j][:value] = diff[1]
      end
    end
  end

  first_line = 0
  biggest_diff = Hash.new
  biggest_diff[:diff] = 0
  biggest_diff[:line1] = 0
  biggest_diff[:line2] = 1

  for i in 0..(block_size - 1)
    for j in 0..(block_size - 1)
      puts "i: #{i} and j #{j}"
      if(i == j)
        next
      else
        if @comp_arr[i][j][:value] > biggest_diff[:diff]
          biggest_diff[:diff] = @comp_arr[i][j][:value]
          biggest_diff[:line1] = i
          biggest_diff[:line2] = j
        end
      end
    end
  end

  puts "biggest diff with #{biggest_diff[:diff]}, first line: #{biggest_diff[:line1]}"


#2 finde best match für linie -> linie = betch match
#3 finde best match für linie...
  @comp = Array.new(block_size) { Hash.new }
    
  line = @im.export_pixels(0, first_line, @im.columns, 1, "RGB")

  for i in 0..(block_size - 1)
    @im1.import_pixels(0,0,@im.columns, 1, "RGB", line)
    @comp[i][:best_line] = 0
    @comp[i][:best_diff] = 100

    alrdy_incl << i

    for j in 0..(block_size -1)
      if(i == j)
        next
      else
        other_line = @im.export_pixels(0, j, @im.columns, 1, "RGB")
        @im2.import_pixels(0,0,@im.columns, 1, "RGB", other_line)
        diff = @im1.difference(@im2)
        
        if diff[1] < @comp[i][:best_diff] && !alrdy_incl.include?(j)
          alrdy_incl.delete(@comp[i][:best_line])
          alrdy_incl << j
          @comp[i][:best_line] = j
          @comp[i][:best_diff] = diff[1]
        end
      end
    end
  end

  next_line = first_line
  for i in 0..(block_size - 1)
    tmp_line = @im.export_pixels(0, next_line, @im.columns, 1, "RGB")
    @decoded_img.import_pixels(0, i, @decoded_img.columns, 1, "RGB", tmp_line)

    next_line = @comp[i][:best_line]
  end


#4 finde besten treffer in neuem block für linie
#2


  dec_path = File.join(directory, "dec_" + @fileName)
  @decoded_img.write(dec_path)

  erb :upload
end
