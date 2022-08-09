require 'set'
require 'byebug'

### Question
# You have 2 hashes. You are looking for the difference between the 2. What was added or removed or if the hash is the same.
# Hash only have string keys
# Hash only have string, boolean, number, array or hash as value
# Compare should have an option for deep or shallow compare
# Compare should list the difference for keys and values

# _______________________________________________________________________________________________

# return value will be formatted as follows:
## Shallow
# { diff: String, h1_value: h1, h2_value: h2 }
## Deep
# {
#   <key_one>: [ {diff: String || Hash(for nested changes), h1_value, h2_value}, {diff: String || Hash, h1_value, h2_value}, ... ], 
#   <key_two>: [ {diff: String || Hash(for nested changes), h1_value, h2_value}, {diff: String || Hash, h1_value, h2_value}, ... ],
#   ...
# }

# _______________________________________________________________________________________________



class HashCompare

  def add_changes(changes, key, diff, h1_v, h2_v)
    return if diff.nil?
    formatted_diff = { diff: diff, h1_value: h1_v, h2_value: h2_v}
    if changes[key].nil?
      changes[key] = [formatted_diff]
    else
      changes[key] << formatted_diff
    end
    puts "Adding Key: #{key} with Value: #{changes[key]}...\n\n"
  end

  def hash_compare(h1, h2, options)
    # shallow compare
    if options[:shallow]
      message = h1 == h2 ? "Hashes are equal" : "Hashes are not equal"
      return {diff: message, h1_value: h1, h2_value: h2}
    end 
    ###################### deep compare
    changes = {} 
    keys = (h1.keys | h2.keys).map(&:to_sym)
    keys.each do |k|
      # skip iteration if the values are equal
      next if h1[k] == h2[k]
      # check if one of the hashes doesnt have k and log diff accordingly
      hash_missing_key = !h1.has_key?(k) ? 1 : !h2.has_key?(k) ? 2 : nil 
      unless hash_missing_key.nil?
        diff = "Key ':#{k}' missing in Hash #{hash_missing_key}"
        add_changes(changes, k, diff, h1[k], h2[k])
        next
      end
      # check if the values are different types of data & that the values are not true and false because true(TrueClass) and false(FalseClass) would fail the check but are both booleans
      if h1[k].class != h2[k].class && ([true, false] & [h1[k], h2[k]] != [true, false])
        add_changes(changes, k, "Different data types", h1[k], h2[k])
        next
      end
      # check the type of value we are working with and act accordingly
      case h1[k]
      when Array
        # make sure elements of the array are of the same data type
        class_set = Set.new
        same_class = (h1[k] + h2[k]).reduce(class_set) {|set, ele| set << ele.class }.count == 1
        same_length = h1[k].length == h2[k].length
        unless same_class
          add_changes(changes, k, "Arrays contain different data types", h1[k], h2[k])
          next
        end
        # skip if arrays are equal
        next if (h1[k] - h2[k] | h2[k] - h1[k]).empty? && same_length
        missing_from_h1, missing_from_h2 = h2[k] - h1[k], h1[k] - h2[k]
        missing_arr_holder = [missing_from_h1, missing_from_h2]
        # different size array, but contain the same values
        if missing_arr_holder.all?(&:empty?) && !same_length
          diff  = "Same values, different lengths; Hash1[#{key}] has a length of #{h1[k].length} Hash2[#{key}] has a length of #{h2[k].length}"
          add_changes(changes, k, diff, h1[k], h2[k])
          next
        end
        # log changes for missing keys and values
        missing_arr_holder.each_with_index do |arr, index|
          arr.each do |ele|
            diff  = "#{ele} is missing from Hash[#{index+1}][#{k}]"
            add_changes(changes, k, diff, h1[k], h2[k])
          end
        end
      when Hash
        if options[:depth] > options[:max_depth]
          # shallow compare at @max_depth
          diff = hash_compare(h1[k], h2[k], {max_depth: options[:max_depth], depth: options[:depth], shallow: true})
        else
          # deep compare
          diff = hash_compare(h1[k], h2[k], {max_depth: options[:max_depth], depth: options[:depth] + 1})
        end
      else
        diff = "#{h1[k]} ==> #{h2[k]}"
      end
      # add changes
      add_changes(changes, k, diff, h1[k], h2[k])
    end
    return nil if changes.empty?
    changes
    # end of method
  end

  def run(h1, h2, options={})
    h1 ||= {}
    h2 ||= {}
    # depth will always be zero on start
    options[:depth] = 0
    options[:max_depth] ||= 2
    options[:shallow] ||= false
    # hashes are empty
    return nil if h1.empty? && h2.empty?
    return hash_compare(h1, h2, options)    
  end

end

############## Test Data


h1 = {
	"id": "1",
	"type": "icecream",
	"name": "Vanilla Cone",
	"image":
		{
			"url": "img/01.png",
			"width": 200,
			"height": 200
		},
	"thumbnail":
		{
			"url": "images/thumbnails/01.png",
			"width": 32,
			"height": 32
		},
    "misc": {
      "meow": {
        "loud": true,
        "hungry": true
      }
    } 
}


h2 = {
	"id": "2",
	"type": "icecream",
	"name": "Chocolate Cone",
	"image":
		{
			"url": "img/02.png",
			"width": 200,
			"height": 200
		},
	"thumbnail":
		{
			"url": "images/thumbnails/02.png",
			"width": 32,
			"height": 32
		},
    "misc": {
      "meow": {
        "loud": true,
        "hungry": false
      }
    } 
}

# ---------------------------------------------------------------------------------------



# h1 = {
#   "one": 1,
#   "two": [1,2],
#   "three": {
#     "meow": false,
#     "woof": true,
#     "age": 7
#   }
# }
# h2 = {
#   "one": 1,
#   "two": [3,1,2],
#   "three": {
#     "meow": true,
#     "woof": false,
#     "age": 4
#   }
# }



# ------------------

# h1 = {
#   meow: { key_one: {"one": 1, "two": 2}, key_two: {"three": 3, "four": {id: 4, light: {on: {day: true}}}}  }
# }
# h2 = {
#   meow: { key_one: {"one": 1, "two": 2}, key_two: {"three": 3, "four": {id: 5, light: {on: {day: false}}}} }
# }

# ------------------

# h1 = {
#   meow: [{"one": 1, "two": 2}, {"three": 3, "four": 4}, {"five": 5, "six": 6}, [1,2]]
# }
# h2 = {
#   meow: [{"one": 1, "two": 2},{"three": 3, "four": 4}, {"seven": 7, "eight": 8}]
# }

# ------------------



############## Run


inst = HashCompare.new

# options = {
  # depth: Integer (using it for recursive calls)
  # max_depth: Integer,
  # shallow: Boolean
# }

result = inst.run(h1,h2)

# puts result.inspect
pp result 
byebug

puts "Hola!!"