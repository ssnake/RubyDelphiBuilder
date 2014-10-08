$LOAD_PATH << '.'

require 'net/ftp'
module DelphiBuilder

	class Uploader
		@ftp
		@user
		@password
		def initialize host, user=nil, password=nil
			@ftp = Net::FTP.new host
			@ftp.passive = true
			@user = user
			@password = password
		end
		def upload filename
			@ftp.login @user, @password
			size = File.size filename
			total=0.0
			@ftp.putbinaryfile filename do |data|
				total += data.length
				puts  "#{total.to_f/size*100} %"

			end
			@ftp.close
		end
	end
end