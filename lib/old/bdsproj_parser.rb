$LOAD_PATH << '.'

require 'nokogiri'
require 'helper'

module DelphiBuilder
	class BDSProjParser
		extend Helper
		class << self
			def parse file
				cmd = CommandLineBuilder.new
				cmd.project_filename = File.basename file
				cmd.project_dir = File.dirname file
				doc = Nokogiri::XML(File.read(file))
				
				doc.xpath('//Source/Source').each do |node|
					parse_node node, cmd
				end
				doc.xpath('//Compiler/Compiler').each do |node|
					parse_node node, cmd
				end
				doc.xpath('//Directories/Directories').each do |node|
					parse_node node, cmd
				end
				cmd

			end
			def parse_node node, cmd
				name = node['Name']
				value = node.content
				
					if name =~  /unitaliases/i
						cmd.alias = value
					end
					if name =~ /^outputdir$/i
						cmd.exe_dll_output = value
						
					end
					if name =~ /^unitoutputdir$/i
						cmd.dcu_output = value
					end
					if name =~ /searchpath/i
						cmd.include_dir = value
					end
					if name =~ /conditionals/i
						cmd.define = 'ControlledStartup;UseZModem;NewTimer;SERVER;QUEUE;HYBRID;USE_UDP;SUPPORT_SENTENCES;SUPPORT_PLAYLISTS;SBSDevExCtrls;DEBUGSI;DVNETPlus;LocalServerNode;MNSSConfig;UNITTEST;USE_DCOM;SERVICE;FWDownloader'
					end
					if name =~ /mainsource/i
						cmd.project_filename = value
					end
				

				 
			end
		end
	end
end
if __FILE__ == $0
	puts DelphiBuilder::BDSProjParser.class.ancestors
	DelphiBuilder::BDSProjParser.replace_env_var nil, nil
	#cmd =DelphiBuilder::DProjParser.parse 'BuildQueTest.bdsproj'
	#puts cmd.build
end