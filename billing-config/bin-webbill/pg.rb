require 'pg'

porttypes = Hash["X.25" => 3777, "X.75" => 3778, "Virtual" => 3799]

puts "[*]\e[31m Postgres Notify POD Server Started.\e[0m" 
conn = PG::Connection.new( :dbname => 'radius', :user => 'radius', :password => 'radius' ,:host => 'localhost', :port => 5432 )
#res  = conn.exec('SELECT * from accounts')
#p res[0]
conn.async_exec "LISTEN radchannel"
while true
	# This will block until a NOTIFY is issued on one of these two channels.
	conn.wait_for_notify do |channel, pid, payload|
		p payload
		tok = payload.split(":")
		cmd = tok[0]
		
		if cmd == 'pod' 
			user = tok[1]
			session = tok[2] 
			nasporttype = tok[3]
				
			puts "[*]\e[35m Received NOTIFY on channel #{channel}, pid=#{pid}, cmd=#{cmd} user=#{user}, session=#{session}, nasporttype=#{nasporttype} \e[0m"
			if  porttypes.has_key?(nasporttype)
				port = porttypes[nasporttype]
			else
				puts "[*]\e[31m Fail not found nas pod-server-port for nasportype=#{nasporttype} .\e[0m"
			end
			system("echo \"User-Name="+user+"\nAcct-Session-Id="+session+"\n\" | radclient -x -r 2 -t 3 127.0.0.1:"+port.to_s+" disconnect testing123") 
	
		elsif cmd == 'shape'
			user = tok[1]
			session = tok[2]
			nasporttype = tok[3]
			framedip = tok[4]
			inbaud = tok[5]
			outbaud = tok[6]

			if  porttypes.has_key?(nasporttype)
                                port = porttypes[nasporttype]
                        else
                                puts "[*]\e[31m Fail not found nas pod-server-port for nasportype=#{nasporttype} .\e[0m"
                        end
			sleep(7)				
			puts "[*]\e[35m Received NOTIFY on channel #{channel}, pid=#{pid}, cmd=#{cmd} user=#{user} session=#{session} framedip=#{framedip}, inbaud=#{inbaud}, outbaud=#{outbaud} \e[0m"		
			system("echo \"User-Name="+user+"\nAcct-Session-Id="+session+"\nActual-Data-Rate-Downstream="+outbaud+"\nActual-Data-Rate-Upstream="+inbaud+"\nFramed-IP-Address = "+framedip+"\n\" | radclient -x 127.0.0.1:"+port.to_s+" coa testing123")				
			
		else 
			puts "[*]\e[31m Fail not found cmd = #{cmd} .\e[0m"
		end
	end
end
