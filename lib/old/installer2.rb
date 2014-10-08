$LOAD_PATH << '.'
require 'helper'
module DelphiBuilder

	class Installer2
		include Helper
		
		
		def initialize exe_filename
			@exe_filename = exe_filename
		end
		
		def compile list

			list.each do |prj|
				prj_file = add_quotes prj['prj']
				param = prj['params']
				output_file = prj['output_file']
				compile_prj prj_file, param, output_file
			end

		end
	private
		def compile_prj file, param, output
			cmd = "#{@exe_filename} #{file} #{param}"
			puts "compiling installer #{file}"
			puts "#{cmd}"
			res = `#{cmd}`
			puts res

		end
	end
end