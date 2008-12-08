require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'BlockExtractor'
require 'SeparatorDetector'
require 'StructureConstructor'
require 'BlockTree'

PDOC = 6

def visualizeSections(html_doc, location)
  html_file = File.new("new.html", "w")
  html_file.puts html_doc.to_html
end

def vips_algorithm (block, body)
	if block.node.respond_to? :each_child
		extractor = BlockExtractor.new(block)
		block.node.each_child do |child|
          extractor.divideDOMTree(child, block, 10)
        end
		
		detector = SeparatorDetector.new(extractor.blockPool, block)
		detector.evaluateRelation
		detector.assignWeights
		detector.drawSeparators(body)
		
		if (detector.separatorList.size > 0)
			constructor = StructureConstructor.new(detector.blockPool, detector.separatorList, block)
			constructor.buildTree
			puts "NUM CHILDREN: #{block.children.size}"

			detector.blockPool.each { |leaf_block|
				if (leaf_block.doc <= PDOC)
					vips_algorithm(leaf_block, body)
				end
			}
		end
	end
end

def draw_blocks(root_block, body)
	if !((root_block.children).nil?)
		for i in 0...root_block.children.size
			draw_blocks(root_block.children[i], body)
		end
	end
	
	html=""
	html = html + "<div style='left:" + root_block.offsetLeft.to_s + "px; top:" + root_block.offsetTop.to_s + "px;width:" + root_block.width.to_s
    html = html + "px;height:" + root_block.height.to_s
    html = html + "px;background-color:transparent;border-width:thick;border-style:dashed;z-index:400000;position:absolute;float:center;'></div>"
	body.append(html)
=begin
	if (root_block.offsetTop > 1509)
		puts root_block.tag
	end
=end
end

if __FILE__ == $0
  location = "retrieved-6.html"
  doc = Hpricot(open(location))
  body = doc.search("/body")

  root_node = nil  
  body.each do |node|
	root_node = node
  end
	
  extractor = BlockExtractor.new(nil)
  root_block = extractor.create_block(root_node, nil, 10)	#TODO: make this a static function of the class
  root_block.doc = 5
  vips_algorithm(root_block, body)

  btree = BlockTree.new(root_block)
  draw_blocks(root_block, body)
  
  visualizeSections(doc, location)
end
