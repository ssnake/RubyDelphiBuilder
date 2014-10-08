$LOAD_PATH << '.'

require 'nokogiri'
require 'helper'


module DelphiBuilder
	class DProjParser
		extend Helper
		class << self 
			def get_output_exe file
				doc = Nokogiri::XML(File.read(file))
				

				node = doc.search('DCC_DependencyCheckOutputName')[0]
				
				#puts "file = #{file} node = #{node.content}"
				if !node.nil?
					node.content
				else
					nil

				end
			end
			def get_exe_output_dir file
				dir = File.dirname get_output_exe(file)
				
				basedir = File.dirname file
				
				File.expand_path(dir, basedir).gsub '/', '\\'
			end
		end 
	end
end
if __FILE__ == $0

	puts DelphiBuilder::DProjParser.get_exe_output_dir 'UCQ.dproj'	

end