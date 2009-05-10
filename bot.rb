#!/usr/bin/env ruby
require 'rubygems'
require 'thread'
require 'pp'
require 'xmpp4r/client'
require 'xmpp4r/roster'
require 'set'
require 'common'
require 'query-lib'

hostname = "knuthium.club.cc.cmu.edu"
username = "dtella@club.cc.cmu.edu/#{hostname}"
password = 'loo7Pho3'

SERVER_ADDRESS = hostname
SERVER_PORT = 8314
BASE_URL = "http://#{SERVER_ADDRESS}:#{SERVER_PORT}"

class DtellaBot
	def initialize username, password, index_filename
		@username = username
		@client = Jabber::Client::new(Jabber::JID::new(@username))
		@client.connect
		@client.auth(password)
		@client.send(Jabber::Presence.new)
		@roster = Jabber::Roster::Helper.new(@client)
		@z = DtellaIndexReader.new index_filename
		@options = {
			:verbose => false,
			:offset => 0,
			:count => 10,
			:max_locations => 5,
		}
		@result_hashes = {}
		@client.add_message_callback { |m| on_message m }
		@roster.add_subscription_request_callback(0, nil) { |item,pres| on_subscription_request item, pres }
	end

	def on_subscription_request item, pres
		@roster.accept_subscription(pres.from)
		puts "accepted subscription request from #{pres.from}"
	end

	def tx to, body
		m = Jabber::Message::new(to, body)
		m.type = :chat
		@client.send m
	end

	def on_message m
		if m.body.nil?
			puts "nil body from #{m.from}"
			return
		end
		puts "got message from #{m.from}: #{m.body.inspect}"
		cmd, arg = m.body.split(nil, 2)
		cmd ||= ""
		arg ||= ""
		case cmd
		when 'explain', 'e'
			cmd_explain m.from, arg
		when 'query', 'q'
			cmd_query m.from, arg
		when 'link', 'l'
			cmd_link m.from, arg
		else
			tx m.from, "invalid command #{cmd.inspect}"
		end
	end

	def cmd_explain from, query_string
		q = @z.parse_query query_string
		tx from, q.description
	end

	def cmd_query from, query_string
		q = @z.parse_query query_string
		ms, estimate = @z.query q, @options[:offset], @options[:count]

		if ms.empty?
			tx from, "No results found."
		else
			tx from, "Results #{@options[:offset]+1} - #{@options[:offset]+ms.size} of #{estimate}:"
			ms.each do |m|
				result_id = m[:rank].to_i + 1
				@result_hashes["#{from}\000#{result_id}"] = m[:tth]
				username, path = m[:locations][rand(m[:locations].size)]
				tx from, "#{result_id}: #{m[:percent]}% #{username}:/#{path}"
			end
		end
	end

	def cmd_link from, result_id
		tth = @result_hashes["#{from}\000#{result_id}"]
		if !tth
			tx from, "invalid result id"
			return
		end
		tx from, "TTH: #{tth}"
		ms, e = @z.query Xapian::Query.new(mkterm(:tth, tth)), 0, 1
		if ms.empty?
			tx from, "result not found in index"
			return
		end
		m = ms[0]
		seen = []
		m[:locations].each do |username,path|
			next if seen.member? username
			tx from, BASE_URL + "/file?username=#{username}&tth=#{tth}"
			seen << username
		end
	end
end

bot = DtellaBot.new username, password, 'index'
Thread.stop
