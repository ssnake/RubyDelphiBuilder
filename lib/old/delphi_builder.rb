
require 'json'
$LOAD_PATH << '.'
require 'helper'
require 'bdsproj_parser'
require 'yaml'
require 'dproj_parser'
require 'installer2'

module DelphiBuilder

	class CommandLineBuilder
		include Helper
		
		attr_accessor :alias, :define, :name_space
		            # -O        -U         -I            -R
		attr_accessor :obj_dir, :unit_dir, :include_dir, :resource_dir
		            # -TX
		attr_accessor :output_ext
		            # -E                -NU          -NH          -NO          -NB          -NX
		attr_accessor :exe_dll_output,  :dcu_output, :hpp_output, :obj_output, :bpl_output, :xml_output
		            # -LE                  -LN
		attr_accessor :package_bpl_output, :package_dcp_output
					# -V            -B           -VT            -VR             -GD
		attr_accessor :use_debug_info, :use_build_all, :use_tds_symbols, :use_remote_debug, :use_detailed_map
		attr_accessor :use_console

		attr_accessor :project_dir, :project_filename

		attr_accessor :install_prj_filename, :install_output_filename, :install_copy_dest_dir, :install_params
		attr_accessor :install_copy_files, :install_copy_files_dest

		def default()
			@output_ext = 'EXE'

		end
		def initialize(json_file=nil)

			default()
			return if json_file.nil?
			conf = JSON.parse(IO.read(json_file))

			@alias = conf["alias"]
			@define = conf["define"]
			@include_dir = @resource_dir = @unit_dir = conf["search_dir"]
			@dcu_output = conf["dcu_output"] || conf["output_dir"]
			
			@exe_dll_output = @package_dcp_output = @package_bpl_output = @bpl_output = @hpp_output = @obj_output = conf["output_dir"]
			@output_ext ||= conf["TX"]
			@project_dir = conf["project_dir"]
			@project_filename = conf["project_filename"]
			@name_space = conf["name_space"]
			@install_prj_filename = conf["install_prj_filename"]
			@install_output_filename = conf["install_output_filename"]
			@install_copy_dest_dir = conf["install_copy_dest_dir"]
			@install_params = conf["install_params"]
			@install_copy_files = conf["install_copy_files"]
			@install_copy_files_dest = conf["install_copy_files_dest"]
		end



		def get_output_filename
			output_filename = changeFileExtension(@project_filename, @output_ext.delete('.'))
			"#{@exe_dll_output}\\#{output_filename}"

		end
		def build()
			cmd = ""
			if @use_build_all
				cmd << "-B "
			end
			
			if @use_debug_info
				cmd << "-V "
			end
			
			if @use_tds_symbols
				cmd << "-VT " 
			end
			
			if @use_remote_debug
				cmd << "-VR " 
			end
			
			if @use_detailed_map
				cmd << "-GD " 
			end


			cmd << "-A#{@alias} "  unless @alias.nil?
			cmd << "-D#{@define} " unless @define.nil?

			cmd << "-E#{@exe_dll_output} "  unless @exe_dll_output.nil?
			cmd << "-I#{@include_dir} "  unless @include_dir.nil?
			cmd << "-LE#{@package_bpl_output} "  unless @package_bpl_output.nil?
			cmd << "-LN#{@package_dcp_output} "  unless @package_dcp_output.nil?
			cmd << "-NU#{@dcu_output} "  unless @dcu_output.nil?
			cmd << "-NS#{@name_space} "  unless @name_space.nil?
			cmd << "-O#{@obj_dir} "  unless @obj_dir.nil?

			cmd << "-R#{@resource_dir} "  unless @resource_dir.nil?
			cmd << "-U#{@unit_dir} "  unless @unit_dir.nil?
			cmd << "-NB#{@bpl_output} "  unless @bpl_output.nil?
			
			cmd << "-NH#{@hpp_output} "  unless @hpp_output.nil?
			cmd << "-NO#{obj_output} "  unless @obj_output.nil?
			cmd << "-TX#{@output_ext} " unless @output_ext.nil?

			cmd << "-CC " if @use_console
			cmd

			
			
		end
	end

	class DelphiBuilder
		include Helper
		@delphi_path
		@dcc32



		def initialize(delphi_path)
			@dcc32 = 'DCC32.EXE'
			@delphi_path = delphi_path
		end



		
		def compile(cmd_line_builder, hash_params={})
					
			additional_params = hash_params[:additional_params]
			env_var = hash_params[:env_var]

			output_filename = cmd_line_builder.get_output_filename 
			File.delete output_filename if File.exists? output_filename

			Dir.chdir(cmd_line_builder.project_dir) do
				params = cmd_line_builder.build
				params = cmd_line_builder.replace_env_var params, env_var unless env_var.nil?

				cmd = "\"#{@delphi_path}\\bin\\#{@dcc32}\" #{params} #{additional_params} #{cmd_line_builder.project_filename}"
				puts cmd
				res = `#{cmd}`
				unless File.exists? output_filename
					puts res
					raise "Unable to compile #{output_filename}"
				end

			end

		end
		
		def run_unit_test cmd_line_builder
			filename = cmd_line_builder.get_output_filename
			puts "running #{filename}"
			Dir.chdir(File.join(cmd_line_builder.project_dir, cmd_line_builder.exe_dll_output)) do
				res = `#{filename}`

			
				if res =~ /FAILURES/mi
					puts res
					raise 'test failed'

				end
			end
		end
	end

	class Parser
		
		
		class << self
			def parse_bdsproj filename
				BDSProjParser.parse filename
			end
		end

	end
	class DelphiBuilder2
		include Helper

		def initialize file
			@prj_file = file
			@cfg = YAML.load File.read(file)
		end	

		def make_temp_file file
			data = File.read file
			data = replace_env_var data, get_env_var
			ret_file = "#{file}.tmp"
			f = File.new ret_file, 'w'
			f.write data
			f.close
			ret_file
		end
		def compile file
			Dir.chdir(File.dirname(file)) do 

				temp_file = make_temp_file file
				cmd = "#{@delphi_path}\\bin\\rsvars.bat && msbuild #{temp_file}"
				puts cmd
				res = `#{cmd}`
				
				
				File.delete temp_file
				res
			end
		end
		def build 
			find_delphi_path
			puts "Found delphi path #{@delphi_path}"
			build_ut
			build_prj
			copy_files
			build_installer

			
		end
	private
		def get_env_var
			@cfg["env_var"]
		end
		def find_path list
			list.each do |path| 
				if File.exists? path
					return add_quotes(path) 
				end
			end
			nil
		end
		def find_delphi_path
			@delphi_path = find_path @cfg["delphi_path"]

			if @delphi_path.nil?
				raise "Unable to find delphi path"
			end
		end
		def get_project_dir file
			File.dirname file
		end
		def get_output_dir file
			DProjParser.get_exe_output_dir file
		end
		def get_output_exe file
			DProjParser.get_output_exe file
		end
		def build_ut
			@cfg["unit_test_prj"].each do |ut|
				puts "compiling #{ut}"
				res = compile ut 
				dir = get_output_dir(ut)
				puts "chaning dir to #{dir}"
				Dir.chdir(dir) do
					exe = get_output_exe ut
					raise "Unable to find #{exe}" unless File.exists? exe
					puts "running ut #{exe}"
					res = `#{exe}`
					if res =~ /FAILURES/mi
						puts res
						raise 'test failed'

					end
				end
				
			end
		end
		def build_prj
			@cfg["prj"].each do |prj|
				puts "compiling #{prj}"
				res = compile prj 	
			end
		end
		def copy_files
			dest = @cfg["copy"]["dest"]
			@cfg["copy"]["source"].each do |file|
				puts "copying #{file} to #{dest}"
				copyFile file, dest

			end
		end
		def build_installer
			@installer_path = find_path @cfg["installer_path"]
			if @installer_path.nil?
				raise "Unable to find installer path"
			end
			i = Installer2.new @installer_path
			i.compile @cfg["installer_prj"]
		end
		
	end
end
