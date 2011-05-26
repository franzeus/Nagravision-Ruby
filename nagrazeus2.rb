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
  # START DE-NAGRAVISION 
  # ...........................................................

  @im1 = Image.new(@im.columns, 1)
  @im2 = Image.new(@im.columns, 1)

  @img_first = Image.new(@im.columns, 1)
  @img_last = Image.new(@im.columns, 1)
  @current_img = Image.new(@im.columns, 1)
  
  @decoded_img = Image.new(@im.columns, @im.rows)

  #@comp_arr = Array.new(block_size) { Array.new(block_size) { Hash.new } }

  alrdy_incl = Array.new

  # 1. COMPARE EACH LINE WITHIN THE SAME BLOCK
  # => Get the two Lines with the biggest difference
  @imageArray = Array.new(blocks * block_size)
  @entireImageArray = Array.new(blocks * block_size)
  @comp_array = Array.new(block_size)

  for n in 0..(blocks - 1)

    # Get current line image data
    current_line = @im.export_pixels(0, n * block_size, @im.columns, 1, "RGB") # (x=0, y=0, columns=img.columns, rows=img.rows, map="RGB") -> array
    @im1.import_pixels(0, n * block_size, @im.columns, 1, "RGB", current_line)

    for i in 0..(block_size - 1)
          
        # Dont compare current_line with itself
        if(i == n)
          next
        else
          # Get Image Data of other line in the same block
          other_line = @im.export_pixels(0, i, @im.columns, 1, "RGB")
          @im2.import_pixels(0,0,@im.columns, 1, "RGB", other_line)

          # Get difference with current_line and other_line
          diff = @im1.difference(@im2)
          @comp_array[i-1] = [diff[1], (n+1) * i]
        end
    end
    
    # Merge Arrays
    @imageArray = @imageArray | @comp_array.sort{ |x,y| y.to_s <=> x.to_s }
  
 
    puts "Max:" + @imageArray[1][0].to_s + " at Line: " + @imageArray[1][1].to_s
    puts "Min" + @imageArray[@imageArray.length - 1][0].to_s + " at Line:" + @imageArray[@imageArray.length - 1][1].to_s

    # We got first and last possible line
    #possible_first_line = @imageArray[1][1]
    #possible_last_line  = @imageArray[@imageArray.length - 1][1]

    possible_first_line = @im.export_pixels(0, @imageArray[1][1], @im.columns, 1, "RGB") # (x=0, y=0, columns=img.columns, rows=img.rows, map="RGB") -> array
    @img_first.import_pixels(0, @imageArray[1][1], @im.columns, 1, "RGB", possible_first_line)

    possible_last_line = @im.export_pixels(0, @imageArray[@imageArray.length - 1][1], @im.columns, 1, "RGB") # (x=0, y=0, columns=img.columns, rows=img.rows, map="RGB") -> array
    @img_last.import_pixels(0, @imageArray[@imageArray.length - 1][1], @im.columns, 1, "RGB", possible_last_line)

    # ------------------------------------------------
    # Compare possible lines with the next block

    first = 0
    last = 0

    # Not for the last block
    if n+1 < blocks

      for m in 0..((block_size) + n)
        # Get current line image data
        current_line_of_next_block = @im.export_pixels(0, (n * block_size) + m, @im.columns, 1, "RGB")
        @current_img.import_pixels(0, (n * block_size) + m, @im.columns, 1, "RGB", current_line_of_next_block)

        # Get difference with current_line and first/last line
        diff_to_first_possible_line = @img_first.difference(@current_img)[1]
        diff_to_last_possible_line = @img_last.difference(@current_img)[1]

        if diff_to_first_possible_line < diff_to_last_possible_line
          first += 1
        else
          last += 1
        end
      end
    # Handle last block
    # just got the last line of the previous block and compare to the last block line
    else
      # code comes here for last block
    end

    if first < last # Assumption was right
      possible_first_line = @imageArray[1][1]
      possible_last_line  = @imageArray[@imageArray.length - 1][1]
    else
      possible_first_line = @imageArray[@imageArray.length - 1][1]
      possible_last_line  = @imageArray[1][1]      
    end

    # We got the first line !
    # Do the comparison again !
    first_line = @im.export_pixels(0, possible_first_line , @im.columns, 1, "RGB") # (x=0, y=0, columns=img.columns, rows=img.rows, map="RGB") -> array
    @im1.import_pixels(0, n * block_size, possible_first_line, 1, "RGB", first_line)

    for k in 0..(block_size - 1)
          
        # Dont compare current_line with itself
        if(k == possible_first_line)
          next
        else
          # Get Image Data of other line in the same block
          other_line = @im.export_pixels(0, k, @im.columns, 1, "RGB")
          @im2.import_pixels(0,0, @im.columns, 1, "RGB", other_line)

          # Get difference with current_line and other_line
          diff = @im1.difference(@im2)
          @comp_array[k-1] = [diff[1], (n+1) * i]
        end
    end
    
    # Merge Arrays
    @entireImageArray = @entireImageArray | @comp_array.sort{ |x,y| y.to_s <=> x.to_s }
  end


  # ----------------------------------------------
  # 3. WRITE DECODED IMAGE
  @im_dec = Image.new(@im.columns, @im.rows-1)
  for i in 1..(@entireImageArray.length - 1)
      puts  @imageArray[i][1].to_s
      if i == block_size
        puts "---------------"
      end
      tmp_line = @im.export_pixels(0, @entireImageArray[i][1], @im.columns, 1, "RGB")   
      @im_dec.import_pixels(0, i, @im.columns, 1, "RGB", tmp_line)
  end

  zeus_path =  File.join(directory, "zeus_" + @fileName)   
  @zeus_filename = "zeus_" + @fileName

  @im_dec.write(zeus_path)

  #erb :upload
end
