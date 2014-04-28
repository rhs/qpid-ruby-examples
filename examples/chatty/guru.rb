#!/usr/bin/env ruby
#--
#
# eventful_qpid_proton.rb - Part of the Eventful Qpid Proton libraries.
# Copyright (C) 2014, Darryl L. Pierce <mcpierce@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'qpid_proton'

msgr = Qpid::Proton::Messenger.new
msgr.subscribe '~0.0.0.0'
msgr.start

MAX_MAX = 16384

max_number = rand(MAX_MAX) + 1

secret_number = (rand(max_number) + 1).to_i

puts "The secret number is: #{secret_number}"

msg = Qpid::Proton::Message.new
reply = Qpid::Proton::Message.new

loop do

  msgr.receive(1) if msgr.incoming < 10

  while msgr.incoming > 0
    msgr.get(msg)

    reply.clear
    reply.address = msg.reply_to

    if msg.properties["guru"] == "max_value"
      puts "Asked for a max number: sending #{max_number}"
      reply.properties["answer"] = max_number

      msgr.put(reply)
      msgr.send

    elsif msg.properties["guru"] == "guess"
      guess = msg.properties["value"]

      puts "Received a guess: #{guess}"

      if guess.to_i == secret_number.to_i
        reply.properties["answer"] = true

        max_number = rand(MAX_MAX) + 1

        secret_number = (rand(max_number) + 1).to_i

        puts "The NEW secret number is: #{secret_number}"

      else
        reply.properties["answer"] = false
      end

      msgr.put(reply)
      msgr.send

    else
      puts "This message is of no interest to me."
    end

  end

end

msgr.stop
