require 'helper'
module DelphiBuilder
	class CfgParser
		extend Helper
		class << self
			def get_exe_output_dir file
				file = get_cfg_filename file
				data = File.read file
				
				m = /^-E"(.*?)"/i.match data
				if !m.nil? && m.length > 1
					basedir = File.dirname file

					File.expand_path( m[1], basedir).gsub '/', '\\'
				else
					nil
				end
			end
			def get_output_exe file
				file = File.basename file
				changeFileExtension file, 'exe'
			end
		private
			def get_cfg_filename file
				if File.extname(file) =~ /.cfg$/i
					return file
				end
				changeFileExtension file, 'cfg'
			end
		end
	end
end
if __FILE__ == $0
	puts DelphiBuilder::CfgParser.get_output_dir 'BuildQueTest.cfg'

end