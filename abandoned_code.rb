
#  processed_line = 0

#  for block_count in 0..@numberOfBlocks.to_i
#  for block_count in 0...1
#
#    current_block = processed_line.to_i / block_size
#
#    this_block_min = current_block * block_size
#    this_block_max = (current_block + 1) * block_size
#
#    @line = @im.export_pixels(0, processed_line, @im.columns, 1, "RGB")
#    @im1.import_pixels(0,0,@im.columns, 1, "RGB", @line)
#    @alrdy_incl << processed_line
#
#
    #for i in this_block_min...this_block_max
    for i in this_block_min...block_max
      @comp_arr[i] = Hash.new
      @comp_arr[i][:value] = 100
      @comp_arr[i][:line] = processed_line
  
      puts "processing and including #{processed_line}"
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
