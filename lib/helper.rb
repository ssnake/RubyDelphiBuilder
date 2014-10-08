require 'fileutils'
module DelphiBuilder

	module Helper
		
	    # eg: removeFileExtion('test.txt') --> 'test'
		def removeFileExtension(filename)
		    return filename[0..filename.rindex('.')-1]
		end


		# eg: testLog = changeFileExtension('myapp.exe','log')
		def changeFileExtension(filename,newExtension)
		    return removeFileExtension(filename) + '.' + newExtension
		end

		# copies the first file to the second file. If the second file exists, it will
		# be overwritten. Standard dos wildcards can NOT be used. The destination can also be
		# a directory (in which case it must exist)
		def copyFile(source,destination)
		    begin
		        #FileUtils::cp( source.gsub("\\","/"),destination.gsub("\\","/"))
		        FileUtils::cp( source, destination )
		    rescue Exception => e
		        raise "Copying \"#{source}\" to \"#{destination}\" failed: " + e.to_s + "\r\n"
		    end
		end

		
		def update_version file
		    content = File.read file
		    content.sub!(/sDate\s=\s'.*?'/, "sDate = '#{Time.now.strftime('%Y%m%d')}'")
		    File.write file, content
			
			
		end

		def replace_env_var text, env_var_hash
			unless env_var_hash.nil?
				env_var_hash.each do |var, value|
					text.gsub!(/\$\(#{var}\)/i, value)

				end
			end
			text
		end
		def add_quotes path
			if path.include? ' '
				"\"#{path}\""
			else
				path
			end
		end
		def remove_quotes path
			path.gsub '"',''
		end
	end
end
if __FILE__ == $0
	#Class.new.extend(DelphiBuilder::Helper).update_version '/media/data/Projects/SBS/CMACStuff/CMACcommon/Title.inc'
	puts Class.new.extend(DelphiBuilder::Helper).replace_env_var '$(sBscommon)', {"sbscommon" => "34"}
end