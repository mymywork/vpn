#!/usr/bin/ruby
# debug level
# 1 - pok,pfail
# 2 - pinfo
# 3 - pdbg
# 4 - praw

require 'rubygems'
require_relative 'radiustar/lib/radiustar'
require 'socket'
require 'digest/md5'
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'thread'

class RadShell

	@@device = "tun0"				# интерфейс на котором работае опенвпн.
	@@interim_time = 30				# интерим

	@@nas_identifier = "ovpn-cert-nas"		# имя наса
	@@radius_host = "127.0.0.1"
	@@radius_secret = "testing123"			# секрет для радиус
	@@managment_host = "127.0.0.1"			# адрес менджемента openvpn
	@@managment_port = 7777				# порт менджмента  openvpn
	@@coa_port = 3799
	@@key_auth_password = "qwerty"		# пароль для аутентификации ключей в радиусе (подключение с ключом уже идентифицирует пользователя пароль нужен чтобы завести сессию в радиусе.)

	@@nas_port_type = "X.25"			# Тип порта который обертка будет передовать радиус (по порту идентифицируется нас и порт для COA/POD)
	@@service_type = "Outbound-User"
	@@framed_protocol = "PPP"

	@@opt_rate_two_class = true			# Если опция true то используется два класса на пользователя для ограничения out/in трафика c отличными скоростями out и in
							# Если опция false то испльзуется один класс для out/in  и соответсвенно одна скорость на in и out 
							# Всего классов 9999 при использовании 2 классов можно подключить 9999/2=4999 пользователей.
	@@parent_class = 0 				# Minor номер родительского класса если такого класса не существует нужно установить 0.

	#
	# Конструктор
	#
	def initialize()
		@semaphore = Mutex.new
	end

	#
	# Парзер опций командной строки
	#
	def get_options


                options = OpenStruct.new
                options.debug = 0
		options.auth = false
		options.port = 7777
		options.coaport = 3799

                opt_parser = OptionParser.new do |opts|

                        opts.banner = "Usage: radcli.rb [options]"

                        opts.on("-d", "--debug LEVEL","Debug output level. 0=quiet,1=standart,2=info/warn,3=debug,4=raw") do |level|
                                options.debug = level.to_i
                        end

                        opts.on("-a", "--password-auth","Enable authenticator approve through managment interface.") do
                                options.auth=true
                        end
                        opts.on("-p", "--port PORT","Port for openvpn managment interface.") do |port|
                                options.port = port
                        end
                        opts.on("-c", "--coaport PORT","Port for listen coa requests.") do |coaport|
                                options.coaport = coaport
                        end
                        opts.on_tail("-v","--version", "Show version.") do
                                puts "Version 1.0"
                                exit
                        end
                        # No argument, shows at tail.  This will print an options summary.
                        # Try it and see!
                        opts.on_tail("-h", "--help", "Show this message") do
                                puts opts
                                exit
                        end
                end

                begin
                        opt_parser.parse!
                rescue OptionParser::InvalidOption , OptionParser::MissingArgument => e
                        puts "missing: "+e.to_s
                        exit
                end

		@debug = options.debug
		@authpsw = options.auth		
		@managment_port = options.port
		@coa_port = options.coaport

                options
	end

	#
	# Стартовая функция
	#
	def start
		
		get_options()
		pok "Openvpn Radius Shell started."
		#-------------
		# Load dictionaries from freeradius directory
		# NOTICE: here the Dictionary.new() only accept a parameter of "folder name" but not the dictionary file
		@dict = Radiustar::Dictionary.new('/usr/share/freeradius/')
		@reqauth = Radiustar::Request.new(@@radius_host, { :dict => @dict })
		@reqacct = Radiustar::Request.new(@@radius_host+':1813', { :dict => @dict })
		@msock = TCPSocket.open(@@managment_host, @@managment_port)
		@msock.send "log on\n",0
		@msock.send "verb 3\n",0
		@msock.send "status 3\n",0

		@@nas_identifier = ( @authpsw ) ? "ovpn-psw-nas" : "ovpn-cert-nas";

		@clients = Hash.new
		@session = Hash.new

		@class_matrix = Array.new(9999,false)
		@handle_matrix = Array.new(999,false)
		@handle_matrix[0] = true 					# Фильтр с нулевым айди не используется тц

		system("tc qdisc del dev #{@@device} root");
		system("tc qdisc add dev #{@@device} root handle 1: htb default 1")
		@class_matrix[0] = true
		@class_matrix[1] = true
		system("tc class add dev #{@@device} parent 1: classid 1:1 htb rate 100mbit");	
		@parent_class = 1						# Родительский класс устанавливаем выше прописанный 100Мегабитный.
	
		#
		# Обработка прерывания процесса из консоли.
		#
		trap("INT") do
  			pfail "Exiting by Ctrl-C, stop sessions, and kill clients...";

			@clients.each { |key,session|
				@msock.send 'kill '+session['callingip']+':'+session['port'].to_s+"\n",0
				session['interim'] = 'stop'
				accounting_interim(session)
			}

  			exit
		end

		#
		# COA Сервер 
		#
		begin
			t = Thread.new {self.coa_server()} 
			t.abort_on_exception = true
		rescue Exception => e
			pfail "Exception #{e.message} #{e.backtrace.inspec}"
		end

		#
		# Запуск треда аккаунтинга.
		#
		begin
			t = Thread.new {self.do_accounting()} 
			t.abort_on_exception = true
		rescue Exception => e
			pfail "Exception #{e.message} #{e.backtrace.inspec}"
		end
		#
		# Уводим текущий тред на поллинг менджмента		
		#
		self.do_managment()
	end

	def do_accounting
		pok "Accounting started interim=#{@@interim_time}"
  		while true
			pinfo "Accounting sleep interim=#{@@interim_time}"
      			sleep(@@interim_time)
      			pdbg "Sessions saving."
      			@msock.send "status 3\n",0
			pdbg "Sending [status 3] to managment."
		end
	end

	def coa_server

		pok "COA/POD Server started."	
		Socket.udp_server_loop(3777) {|data, sock|
			pkt = Radiustar::Packet.new(@dict,1337,data)
			pinfo "Recving COA/POD Packet code=<red>#{pkt.code}</red> id=<red>#{pkt.id}</red>"

			if pkt.validate_acct_authenticator(@@radius_secret) 
				if pkt.code == 'CoA-Request'
					pdbg "COA Authenticator valid."
					found = false
					if  pkt.attributes.has_key?('User-Name') and pkt.attributes.has_key?('Acct-Session-Id') and pkt.attributes.has_key?('Framed-IP-Address') and pkt.attributes.has_key?('ADSL-Forum/Actual-Data-Rate-Downstream') and pkt.attributes.has_key?('ADSL-Forum/Actual-Data-Rate-Upstream')
						username = pkt.attributes['User-Name'].to_s
						sessionid = pkt.attributes['Acct-Session-Id'].to_s
						framedip = pkt.attributes['Framed-IP-Address'].to_s.to_s					
						downrate = pkt.attributes['ADSL-Forum/Actual-Data-Rate-Downstream'].to_s
						uprate = pkt.attributes['ADSL-Forum/Actual-Data-Rate-Upstream'].to_s

						pinfo "COA has attributes User-Name=<red>#{username}</red> , Acct-Session-Id=<red>#{sessionid}</red>, Framed-IP-Adderess=<red>#{framedip}</red>, Actual-Data-Rate-Downstream=<red>#{downrate}</red>, Actual-Data-Rate-Upstream=<red>#{uprate}</red>"	
						pdbg "Enumerate sessions."
						@clients.each { |key,session| 
							pdbg "  -  Session key=#{key} , session=#{session.to_s}" 

							if session['commonname'] == username and session['id'] == sessionid and session['framedip'] == framedip
								pdbg "Found COA Request session."
								found = true
								change_tc_rate_of_session(@clients[key],uprate,downrate)	
								#p @clients[key]
							end
						}
						pdbg "End enumerate."
					end
					pinfo "COA Session found flag=#{found.to_s}"
					if found
						pok "Reply COA-ACK packet with id = #{pkt.id}"
						pktrpl = Radiustar::Packet.new(@dict, pkt.id)
						pktrpl.code = 'CoA-ACK'
						pktrpl.gen_response_authenticator(@@radius_secret,pkt.authenticator)
						sock.reply pktrpl.pack
					else
						pfail "Reply COA-NAK packet with id = #{pkt.id}"
						pktrpl = Radiustar::Packet.new(@dict, pkt.id)
						pktrpl.code = 'CoA-NAK'
						pktrpl.set_attribute('Error-Cause','Session-Context-Not-Found')
						pktrpl.gen_response_authenticator(@@radius_secret,pkt.authenticator)
						sock.reply pktrpl.pack
					end
			
				elsif pkt.code == 'Disconnect-Request'
					pdbg "POD Authenticator valid."
					found = false
					if  pkt.attributes.has_key?('User-Name') and pkt.attributes.has_key?('Acct-Session-Id')
						pinfo "POD has attributes User-Name=<red>#{pkt.attributes['User-Name'].to_s}</red> , Acct-Session-Id=<red>#{pkt.attributes['Acct-Session-Id'].to_s}</red>"	
						pdbg "Enumerate sessions."
						@clients.each { |key,session| 
							pdbg "  -  Session key=#{key} , session=#{session.to_s}" 
							if session['commonname'] == pkt.attributes['User-Name'].to_s and session['id'] == pkt.attributes['Acct-Session-Id'].to_s
								pdbg "Found POD Request session."
								pdbg "#{session}"
								found = true
								@msock.send 'kill '+session['callingip']+':'+session['port'].to_s+"\n",0
							end
						}
						pdbg "End enumerate."
					end
					pinfo "POD Session found flag=#{found.to_s}"
					if found
						pok "Reply POD-ACK packet POD with id = #{pkt.id}"
						pktrpl = Radiustar::Packet.new(@dict, pkt.id)
						pktrpl.code = 'Disconnect-ACK'
						pktrpl.gen_response_authenticator(@@radius_secret,pkt.authenticator)
						sock.reply pktrpl.pack
					else
						pfail "Reply POD-NAK packet POD with id = #{pkt.id}"
						pktrpl = Radiustar::Packet.new(@dict, pkt.id)
						pktrpl.code = 'Disconnect-NAK'
						pktrpl.set_attribute('Error-Cause','Session-Context-Not-Found')
						pktrpl.gen_response_authenticator(@@radius_secret,pkt.authenticator)
						sock.reply pktrpl.pack
					end
				else
					pfail "Invaild POD/COA Server packet type."
				end
			else	
				pfail "Invaild POD/COA server packet validate."
			end
				
		} # loop
	end

	def do_managment
  		pok "Managment thread started"
  		while line = @msock.gets   # Read lines from the socket
      			praw line.chop+"\n"      # And print with platform line terminator

			/.*?CLIENT:CONNECT,([0-9]+),([0-9]+)/.match(line) {|m|
				praw m
				@curstate = 'connect'
				@session['cid'] = m[1]
				@session['kid'] = m[2]
			}
			
			/.*?CLIENT:DISCONNECT,([0-9]+)/.match(line) {|m|
				praw m
				@curstate = 'disconnect'
				@session['cid'] = m[1]
			}
			/.*?CLIENT:ESTABLISHED,([0-9]+)/.match(line) {|m|
				praw m
				@curstate = 'established'
				@session['cid'] = m[1]
			}
			/.*?CLIENT:ENV,username=([a-zA-Z0-9]+)/.match(line) {|m|
				praw m
				@session['username'] = m[1]
			}
			/.*?CLIENT:ENV,password=([a-zA-Z0-9]+)/.match(line) {|m|
				praw m
				@session['password'] = m[1]
			}
      			/.*?CLIENT:ENV,common_name=([a-zA-Z0-9]+)/.match(line) {|m|
          			praw m
          			@session['commonname'] = m[1]
      			}
      			/.*?CLIENT:ENV,ifconfig_remote=([0-9.-]+)/.match(line) {|m|
          			praw m
          			@session['framedip'] = m[1]
      			}
      			/.*?CLIENT:ENV,ifconfig_pool_remote_ip=([0-9.-]+)/.match(line) {|m|
          			praw m
          			@session['framedip'] = m[1]
      			}
      			/.*?CLIENT:ENV,time_unix=([0-9]+)/.match(line) {|m|
          			praw m
          			@session['timestamp'] = m[1]
      			}
			/.*?CLIENT:ENV,.{2}?trusted_port=([0-9]+)/.match(line) {|m|
				praw m
				@session['port']=m[1].to_i
			}
			/.*?CLIENT:ENV,.{2}?trusted_ip=([0-9.]+)/.match(line) {|m|
				praw m
				@session['callingip']=m[1]
			}
      			/.*?CLIENT:ENV,END/.match(line) {|m|
          			if ( @authpsw and @curstate == 'connect' ) or ( !@authpsw and @curstate == 'established' )
					pok "Send <red>ACCESS-REQUEST</red> host=<red>#{@session['callingip']}</red> port=<red>#{@session['port']}</red> commonname=<red>#{@session['commonname']}</red>"
					praw m
							
					session = @session.clone
					sessid = session['commonname'] + ":" + session['callingip'] + ":" + session['port'].to_s
					session['sessid'] = sessid
					@clients[sessid] = session
					self.authentication(session)	
				end
      			}
      			/^CLIENT_LIST\s+([a-zA-Z0-9]+)\s+([0-9.]+):([0-9]+)\s+([0-9.]+)\s([0-9]+)\s([0-9]+).*?([0-9]{5,})/.match(line) {|m|

				if m == nil
					pinfo "No session found for accounting."
					return
				end	

				sessid = m[1]+":"+m[2]+":"+m[3]
          			#pinfo "----------------------------------------------------------"
				pinfo "Sending accounting host=<red>#{m[2]}</red> port=<red>#{m[3]}</red> commonname=<red>#{m[1]}</red> input=<red>#{m[5]}</red> output=<red>#{m[6]}</red>"

				# Если сессия отсутствует
				if @clients.has_key?(sessid) == false
					pinfo "Accounting session not found, creating new session=<red>#{sessid}</red>"
					session = Hash.new
					session['auth_code'] = 'OK'
                               		session['time'] = (Time.now.to_i - m[7].to_i)
                                	session['port'] = m[3].to_i
                                	session['framedip'] = m[4]
                                	session['callingip'] = m[2]
                                	session['input'] = m[5].to_i
                                	session['output'] = m[6].to_i
					session['commonname'] = m[1]
					session['sessid'] = sessid
					self.authentication(session)
					session['interim'] = 'start'
			                @clients[sessid] = session
				else
				# Если сессия есть.
					pok "Accounting found session=<red>#{sessid}</red>"
					@clients[sessid]['time'] = (Time.now.to_i - m[7].to_i)
					#@clients[commonname]['port'] =  m[3].to_i
					#@clients[commonname]['framedip'] = m[4]
					#@clients[commonname]['callingip'] = m[2]
					@clients[sessid]['input'] = m[5].to_i
					@clients[sessid]['output'] = m[6].to_i
				end			
				#if ( @clients[sessid]['interim'] == 'start' ) || ( @clients[sessid]['interim'] == 'stop' )
					accounting_interim(@clients[sessid])
				#end
			}
			# >LOG:1395531351,N,client/192.168.56.1:52846 SIGUSR1[soft,connection-reset]  	
			/>LOG:[0-9]+,,([a-zA-Z0-9]+)\/([0-9.]+):([0-9]+) SIG/.match(line) {|m|
				sessid = m[1]+":"+m[2]+":"+m[3]
                                pok "Disconnecting session=<red>#{sessid}</red>"
				praw m
				if @clients.has_key?(sessid)
					if @clients[sessid]['auth_code'] == 'OK'
						pinfo "Disconnecting session is present."
						@clients[sessid]['interim'] = 'stop'
        	                        	# Вызыываем более быструю обработку не дожидаясь сессии/интерима
						accounting_interim(@clients[sessid])
					else
					# Если сессия не прошла аутентифицацию по какойто причине то удаляем ее из хэша.
						@clients.delete(sessid)
					end
				else
					pfail "Openvpn session not present in hash of sessions. "
				end
                        }
		end
	end

	def authentication(session)
		session['auth_code'] = nil
		session['interim'] = 'start'
		session['id'] = Digest::MD5.hexdigest(session['sessid']+":"+Time.now.to_s)
                # Lets get authenticated
                auth_custom_attr = {
                	'Framed-IP-Address'  => session['framedip'],
                        'NAS-IP-Address' => '127.0.0.1',
                        'NAS-Port'        => session['port'].to_i,
                        'NAS-Port-Type'   => @@nas_port_type,
                        'Service-Type'    => @@service_type,
                        'NAS-Identifier'  => @@nas_identifier,
                        'Calling-Station-Id' => session['callingip'],
                        'Acct-Session-Id' => session['id']
                }
	
		p auth_custom_attr
	
		if @authpsw and session['username'] != nil and session['password'] != nil
			reply = @reqauth.authenticate(session['username'], session['password'], @@radius_secret, auth_custom_attr)
		else
			reply = @reqauth.authenticate(session['commonname'], @@key_auth_password, @@radius_secret, auth_custom_attr)
                end
		pdbg "Access-Response:"
		reply.each { |x,v| pdbg "   #{x} = #{v}" }
                if @authpsw 
			if reply[:code] == 'Access-Accept'
				session['auth_code'] = 'OK'
				@msock.send "client-auth #{session['cid']} #{session['kid']}\nEND\n",0
			else 
				session['auth_code'] = 'Reject'
                                pfail "Radius do not accept client sessid=#{session['cid']}/#{session['kid']}"
                                @msock.send "client-deny #{session['cid']} #{session['kid']} DENY\nEND",0
			end
		else 
			if reply[:code] == 'Access-Accept'
				session['auth_code'] = 'OK'
			else
				session['auth_code'] = 'Reject'
                		pfail "Radius do not accept client sessid=#{session['sessid']}"
				@msock.send "kill #{session['callingip']}:#{session['port']}\n",0
                	end
		end
	end

	def accounting_interim(session)
	
		pinfo "Accounting sending to <red>#{session['sessid']}</red>"		

		highinput = ( session['input'] & 0xFFFFFFFF00000000 ) >> 32
		lowinput = session['input'] & 0xFFFFFFFF
		highoutput = ( session['output'] & 0xFFFFFFFF00000000 ) >> 32
		lowoutput = session['output'] & 0xFFFFFFFF

		acct_custom_attr = {
			'NAS-Identifier' => @@nas_identifier,
                        'NAS-IP-Address' => '127.0.0.1',
                        'Framed-Protocol' => @@framed_protocol,
                        'Framed-IP-Address' => session['framedip'],
                        'Service-Type' => @@service_type,
                        'Calling-Station-Id' => session['callingip'],
                        'NAS-Port' => session['port'],
                        'NAS-Port-Type' => @@nas_port_type,
                        'Acct-Session-Time' => session['time'],
                        'Acct-Input-Octets' => lowinput,
                        'Acct-Output-Octets' => lowoutput,
                        'Acct-Session-Id' => session['id'],
                        'Acct-Input-Gigawords' => highinput,
                        'Acct-Output-Gigawords' => highoutput
		}

		sessid = session['sessid']		

		if session['interim'] == 'start'
			acct_custom_attr['Acct-Status-Type'] = 'Start'
			@clients[sessid]['interim'] = 'update'
		elsif session['interim'] == 'stop'
			acct_custom_attr['Acct-Status-Type'] = 'Stop'
			if delete_tc_rate_of_session(session) == false 
				pdbg "Stop session=<red>#{session['id']}</red> don't have tc rate shape for delete."
			end
			@clients.delete(sessid)
		else
			acct_custom_attr['Acct-Status-Type'] = 'Interim-Update'
		end

                pdbg "Accounting interim attributes:"
                acct_custom_attr.each { |x,v| pdbg "   #{x} = #{v}" }
	
		reply = @reqacct.accounting_start(session['commonname'],@@radius_secret, session['id'], acct_custom_attr)
	end

	def delete_tc_rate_of_session(session)
		if session.has_key?('upclass') and  session.has_key?('downclass')
			pinfo("Delete tc rate filters for user=<red>#{session['commonname']}</red> session=<red>#{session['sessid']}</red> framedip=<red>#{session['framedip']}</red>")
			pdbg("Free tc rate classes uphandle=<red>#{session['uphandle']}</red> downhandle=<red>#{session['downhandle']}</red> upclass=<red>#{session['upclass']}</red> downclass=<red>#{session['downclass']}</red>")
			
			# Удаляем фильтры
			system("tc filter del dev #{@@device} protocol ip parent 1: prio 1 handle 800::#{session['downhandle']} u32 match ip dst #{session['framedip']} flowid 1:#{session['downclass']}")
			system("tc filter del dev #{@@device} protocol ip parent 1: prio 1 handle 800::#{session['uphandle']} u32 match ip src #{session['framedip']} flowid 1:#{session['upclass']}")
			pdbg("Delete tc rate classes")
			# Удаляем классы		
			system("tc class del dev #{@@device} parent 1:#{@parent_class} classid 1:#{session['downclass']}")
			if @@opt_rate_two_class
				system("tc class del dev #{@@device} parent 1:#{@parent_class} classid 1:#{session['upclass']}")
			end
			free_handle(session['uphandle'])	
			free_handle(session['downhandle'])	
			free_class(session['upclass'])
			free_class(session['downclass'])
	
			return true
		else
			return false
		end
	end

	def change_tc_rate_of_session(session,uprate,downrate)
	
		delete_tc_rate_of_session(session)	
		pinfo("Add tc rate filter for user=#{session['commonname']} session=#{session['sessid']} framedip=#{session['framedip']}")
		# Если true то включен двуклассовый режим
		if @@opt_rate_two_class
			if (downclass=find_class()) == -1
				pfail "Not found free class for tc shaper."
			end
			if (upclass=find_class()) == -1
				pfail "Not found free class for tc shaper."
			end
			if (uphandle=find_handle()) == -1
				pfail "Not found free handle for tc shaper."
			end
			if (downhandle=find_handle()) == -1
				pfail "Not found free handle for tc shaper."
			end

			pdbg("Allocate tc rate classes uphandle=#{uphandle} downhandle=#{downhandle} upclass=#{upclass} downclass=#{downclass}")
			
			system("tc class add dev #{@@device} parent 1:#{@parent_class} classid 1:#{downclass} htb rate #{downrate}Kbit")
			system("tc class add dev #{@@device} parent 1:#{@parent_class} classid 1:#{upclass} htb rate #{uprate}Kbit")
			system("tc filter add dev #{@@device} protocol ip parent 1: prio 1 handle 800::#{uphandle} u32 match ip dst #{session['framedip']} flowid 1:#{downclass}")
			system("tc filter add dev #{@@device} protocol ip parent 1: prio 1 handle 800::#{downhandle} u32 match ip src #{session['framedip']} flowid 1:#{upclass}")
			session['uphandle'] = uphandle
			session['downhandle'] = downhandle
			session['downrate'] = downrate
			session['downclass'] = downclass
			session['uprate'] = uprate
			session['upclass'] = upclass
		else
		
			if (downclass=find_class()) == -1
				pfail "Not found free class for tc shaper."
			end
			if (uphandle=find_handle()) == -1
				pfail "Not found free handle for tc shaper."
			end
			if (downhandle=find_handle()) == -1
				pfail "Not found free handle for tc shaper."
			end

			pdbg("Allocate tc rate classes uphandle=#{uphandle} downhandle=#{downhandle} upclass=#{upclass} downclass=#{downclass}")
			
			system("tc class add dev #{@@device} parent 1:#{@parent_class} classid 1:#{downclass} htb rate #{downrate}Kbit")
			system("tc filter add dev #{@@device} protocol ip parent 1: prio 1 handle 800::#{uphandle} u32 match ip dst #{session['framedip']} flowid 1:#{downclass}")
			system("tc filter add dev #{@@device} protocol ip parent 1: prio 1 handle 800::#{downhandle} u32 match ip src #{session['framedip']} flowid 1:#{downclass}")
			session['uphandle'] = uphandle
			session['downhandle'] = downhandle
			session['downclass'] = downclass
			session['downrate'] = downrate
			session['upclass'] = downclass
			session['uprate'] = uprate
		end
	end

	#
	# Работа с хендлами
	#
	def find_handle
		result = -1
		@handle_matrix.each_index {|i| 
			if @handle_matrix[i] == false
				@handle_matrix[i] = true
				result = i
				break
			end
		}
		return result
	end

	def free_handle(handleid)
		@handle_matrix[handleid] = false
	end

	#
	# Работа с классами
	#
	def find_class
		result = -1
		@class_matrix.each_index {|i| 
			if @class_matrix[i] == false
				@class_matrix[i] = true
				result = i
				break
			end
		}
		return result
	end

	def free_class(classid)
		@class_matrix[classid] = false
	end

	#
	# Вывод отладки
	#
	def pok(str)
		if @debug >= 1
			strtmp = str.gsub("<red>","\e[31m").gsub("</red>","\e[36m")
			tputs "\e[32m[*] #{strtmp}\e[0m"
		end
	end

	def pfail(str)
		if @debug >= 1
			tputs "\e[31m[*] #{str}\e[0m"
		end
	end
	
	def pinfo(str)
		if @debug >= 2
			strtmp = str.gsub("<red>","\e[31m").gsub("</red>","\e[36m")
			tputs "\e[36m[*] #{strtmp}\e[0m"
		end
	end

	def pdbg(str)
		if @debug >= 3
			strtmp = str.gsub("<red>","\e[31m").gsub("</red>","\e[34m")
			tputs "\e[34m[*] #{strtmp}\e[0m"
		end
	end

	def praw(str)
		if @debug >= 4
			tputs str
		end
	end

	def tputs(str)
		@semaphore.synchronize {
			# access shared resource
  			puts str
		}
	end

end

rad = RadShell.new()
rad.start()

exit
