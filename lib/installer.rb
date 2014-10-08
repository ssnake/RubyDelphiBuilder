$LOAD_PATH << '.'
require 'helper'
module DelphiBuilder

	class Installer
		include Helper
		
		
		def initialize exe_filename
			@exe_filename = exe_filename
		end
		
		def compile file, param, output
			cmd = "#{@exe_filename} #{file} #{param}"
			
			res = `#{cmd}`
			raise "Unable to find #{output}" if !File.exist? output


		end
	end
	
end