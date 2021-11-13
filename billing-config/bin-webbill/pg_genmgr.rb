require 'pg'


puts "[*]\e[31m Postgres certifiicate and configuration generator started.\e[0m" 

database="radius"
login="radius"
password="radius"
host="localhost"
port=5432

conn = PG::Connection.new( :dbname => database, :user => login, :password => password ,:host => host, :port => port )
conn.async_exec "LISTEN genmgr"
while true
	p "Wait notify"
	# This will block until a NOTIFY is issued on one of these two channels.
	conn.wait_for_notify do |channel, pid, payload|

		result = conn.exec("SELECT accountid,path,state,vpnlogin FROM key_provider INNER JOIN accounts on key_provider.accountid = accounts.id WHERE state = 0")
		result.each do |row|
			p row
		
			system("/opt/accounts/makezippack.sh "+payload)
			path="/opt/accounts/"+payload+".zip"	
			p "Update key request in id=#{row['accountid']} state=1"
			conn.exec("UPDATE key_provider SET state=1, path='#{path}' WHERE accountid = #{row['accountid']}");
		end
	end
end
