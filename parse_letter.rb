require 'nokogiri'

@filename = ARGV[0] || 'symbol-algb02.inkml_GT.txt'
@grid_size = 32.0

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
        letter = doc.css('trace').text.scan(/(\-?\d*) (\-?\d*),/).map { |elem| [elem[0].to_i, elem[1].to_i] }
        mapping_pairs << letter
        xml.close
    end
    mapping_pairs
end

def scale_pairs
    traces = open_xml
    scaled_traces = []
    # p trace.length
    traces.each do |trace|
        max_x = trace.max_by(&:first)[0]
        min_x = trace.min_by(&:first)[0]
        max_y = trace.max_by { |x| x[1] }[1]
        min_y = trace.min_by { |x| x[1] }[1]
        p max_y -  min_y
        offset_x = min_x
        offset_y = min_y
        scale_x = @grid_size / (max_x - min_x)
        scale_y = @grid_size / (max_y - min_y)
        scale = [scale_x, scale_y].min
        offset_trace = trace.map { |elem| [elem[0] - offset_x, elem[1] - offset_y] }
        scaled_trace = offset_trace.map { |elem| [(elem[0] * scale), (elem[1] * scale)] }
        scaled_traces << scaled_trace
    end
    scaled_traces
    # puts max_x
end

p open_xml[0]
p scale_pairs[0]
