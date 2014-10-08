$LOAD_PATH << '.'
require 'helper'
module DelphiBuilder

	class Installer
		include Helper
		@exe_filename
		
		def initialize exe_filename
			@exe_filename = exe_filename
		end

		def copy_files cmd_line_builder
			cmd_line_builder.install_copy_files.each do |f|
				copyFile f, cmd_line_builder.install_copy_files_dest
				
			end
		end
		def compile cmd_line_builder, params = nil
			copy_files cmd_line_builder
			prj_filename = cmd_line_builder.install_prj_filename
			Dir.chdir File.dirname prj_filename.tr('"', '') do
				prm = params || cmd_line_builder.install_params
				cmd = "#{@exe_filename} #{prj_filename} #{prm}"
				puts cmd
				res = `#{cmd}`

				time = Time.new
				fn = cmd_line_builder.install_output_filename
				ext = File.extname(fn)
				fn = File.basename fn, ext 
				dest_fn = "#{cmd_line_builder.install_copy_dest_dir}\\#{fn}_#{time.year}#{time.month}#{time.day}#{ext}"
				copyFile cmd_line_builder.install_output_filename, dest_fn
				dest_fn
			end
		end

	end
end