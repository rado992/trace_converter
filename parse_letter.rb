require 'nokogiri'

@filename = ARGV[0]# || 'symbol-algb02.inkml_GT.txt'
@grid_size = 24.0

def read_mapping
    IO.read @filename
end

def parse_mapping
    read_mapping.scan /.*_(?<number>\d*),(?<char>.*)/
end

def open_xml
    characters = parse_mapping
    mapping_pairs = []
    characters.each do |character|
        # p character
        xml_filename = /.*inkml/.match(@filename).to_s + character[0] + ".inkml"
        xml = File.open xml_filename
        doc = Nokogiri::XML xml
        trace = doc.css('trace').text.scan(/(\-?\d*) (\-?\d*),/).map { |elem| [elem[0].to_i, elem[1].to_i] }
        mapping_pairs << [character[1], trace]
        xml.close
    end
    mapping_pairs
end

def scale_pairs
    trace_pairs = open_xml
    scaled_traces = []
    # p trace.length
    trace_pairs.each do |letter, trace|
        max_x = trace.max_by(&:first)[0]
        min_x = trace.min_by(&:first)[0]
        max_y = trace.max_by { |x| x[1] }[1]
        min_y = trace.min_by { |x| x[1] }[1]
        # p max_y -  min_y
        offset_x = min_x
        offset_y = min_y
        scale_x = (@grid_size - 1) / (max_x - min_x)
        scale_y = (@grid_size - 1) / (max_y - min_y)
        scale = [scale_x, scale_y].min
        offset_trace = trace.map { |elem| [elem[0] - offset_x, elem[1] - offset_y] }
        scaled_trace = offset_trace.map { |elem| [(elem[0] * scale).to_i, (elem[1] * scale).to_i] }
        scaled_traces << [letter, scaled_trace]
    end
    scaled_traces
end

def fill_trace(trace)
    limit = @grid_size / 3
    new_pixels = []
    (trace.length - 1).times do |i|
        first = trace[i]
        second = trace[i + 1]
        if (first[0] - second[0]).abs > limit || (first[1] - second[1]).abs > limit
            next
        end
        if first[0] == second[0]
            if first[1] == second[1]
                next
            end

            (second[1] - first[1]).abs.times do |j|
                new_pixels << [first[0], [first[1], second[1]].min + j]
            end
        elsif first[1] == second[1]
            if first[0] == second[0]
                next
            end

            (second[0] - first[0]).abs.times do |j|
                new_pixels << [[first[0], second[0]].min + j, first[1]]
            end
        else
            (second[0] - first[0]).abs.times do |j|

                q = j * 1.0 / (second[0] - first[0]).abs
                point = [q * first[0] + (1 - q) * second[0], q * first[1] + (1 - q) * second[1]]

                new_pixels << [point[0].to_i, point[1].to_i]

                q = (j + 0.5) * 1.0 / (second[0] - first[0]).abs
                point = [q * first[0] + (1 - q) * second[0], q * first[1] + (1 - q) * second[1]]
                point[0] = [[point[0], 0].max, 23].min
                point[1] = [[point[1], 0].max, 23].min

                new_pixels << [point[0].to_i, point[1].to_i]
            end
        end
        # p new_pixels[-1]
    end
    trace.concat new_pixels
    # new_pixels
    # trace
end

def fill_traces
    scaled_traces = scale_pairs
    scaled_traces.map{ |letter, trace| [letter, fill_trace(trace).uniq] }
end

def print_trace(trace, trace2)
    pixels = []
    grid_dimension = @grid_size.to_i
    grid_dimension.times do
        row = []
        grid_dimension.times do
            row << ' '
        end
        pixels << row
    end
    # p trace[0]
    trace.each do |point|
        pixels[point[1]][point[0]] = '&'
    end
    trace2.each do |point|
        pixels[point[1]][point[0]] = '#'
    end
    grid_dimension.times do |i|
        grid_dimension.times do |j|
            print pixels[i][j]
            print ' '
        # p '\n'
        end
        print "\n"
    end
end

def write_traces
    # @filename = filename
    p "parsing " + @filename
    trace_pairs = fill_traces
    filename = /.*inkml/.match(@filename).to_s.sub(/traces\//, '')

    trace_pairs.each_with_index do |pair, index|
        dir = "parsed/" + filename + "/"
        Dir.mkdir(dir) unless Dir.exist?(dir)
        file = File.open("parsed/" + filename + "/" + index.to_s + ".txt", "w")

        file.write pair[0]
        file.write "\n"
        pixels = []
        grid_dimension = @grid_size.to_i
        grid_dimension.times do
            row = []
            grid_dimension.times do
                row << 0
            end
            pixels << row
        end

        pair[1].each do |point|
            pixels[point[1]][point[0]] = 1
        end

        grid_dimension.times do |i|
            grid_dimension.times do |j|
                file.write pixels[i][j]
                file.write ' '
            # p '\n'
            end
            file.write "\n"
        end
        # file.write pair[1]
    end

end

# # p open_xml[3]
# # p scale_pairs[2]\
# trace = scale_pairs[25]
# # p trace
# filled = fill_trace trace[1]#[6..7]
# print_trace trace[1], filled
# # print_trace scale_pairs[10]


# write_traces fill_traces
write_traces