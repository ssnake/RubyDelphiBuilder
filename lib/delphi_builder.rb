
require 'json'
$LOAD_PATH << '.'
require 'helper'
require 'bdsproj_parser'
require 'yaml'
require 'dproj_parser'
require 'installer'
require 'cfg_parser'

module DelphiBuilder

	
	class Builder
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
				case File.extname(file) 
					when /\.dpr$/i
						compile_dpr file
					when /\.dproj$/i

						compile_dproj file 
				end

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
		def compile_dpr file
			file = File.basename file
			path = remove_quotes @delphi_path

			cmd ="\"#{path}\\bin\\dcc32.exe\" #{file}"
			#puts cmd
			res = `#{cmd}`
			
			#puts res

		end
		def compile_dproj file

			temp_file = make_temp_file file
			cmd = "#{@delphi_path}\\bin\\rsvars.bat && msbuild #{temp_file}"
			#puts cmd
			res = `#{cmd}`
			
			if !(res =~ /build succeeded/i)
				puts res
				raise "failed"
			end
			
			File.delete temp_file
			res			
		end
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
			case File.extname(file) 
				when /\.dpr$/i
					CfgParser.get_exe_output_dir file
					
				when /\.dproj$/i
					DProjParser.get_exe_output_dir file
			end
			
		end
		def get_output_exe file
			case File.extname(file) 
				when /\.dpr$/i
					CfgParser.get_output_exe file
					
				when /\.dproj$/i
					DProjParser.get_output_exe file
			end
			
		end
		def build_ut
			@cfg["unit_test_prj"].each do |ut|
				print "compiling #{ut}...."
				res = compile ut 
				puts "ok"
				dir = get_output_dir(ut)

				
				Dir.chdir(dir) do
					puts "changed dir to #{dir}"
					exe = get_output_exe ut
					puts exe
					raise "Unable to find #{exe}" unless File.exists? exe
					print "running ut #{exe}..."
					res = `#{exe}`

					if res =~ /FAILURES/mi
						puts res
						raise 'test failed'

					end
					puts "ok"
				end
				
			end
		end
		def build_prj
			@cfg["prj"].each do |prj|
				print "compiling #{prj}...."
				res = compile prj 	
				puts "ok"
			end
		end
		def copy_files
			dest = @cfg["copy"]["dest"]
			@cfg["copy"]["source"].each do |file|
				print "copying #{file} to #{dest}...."
				copyFile file, dest
				puts "ok"

			end
		end
		def build_installer
			@installer_path = find_path @cfg["installer_path"]
			if @installer_path.nil?
				raise "Unable to find installer path"
			end
			i = Installer.new @installer_path

			@cfg["installer_prj"].each do |prj|
				prj_file = add_quotes prj['prj']
				param = prj['params']
				output_file = prj['output_filename']
				msk = prj['change_filename_mask']
				print "compiling installer #{prj_file}...."
				i.compile prj_file, param, output_file
				puts "ok"

				Dir.chdir(File.dirname(output_file))  do
					name1= File.basename output_file
					name2= Time.now.strftime(msk)
					print "renaming #{name1} to #{name2}...."
					File.rename name1, name2
					puts "ok"
				end 				
			end
			
		end
		
	end
end
