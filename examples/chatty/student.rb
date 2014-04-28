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

$msgr = Qpid::Proton::Messenger.new
$msgr.start
$msg = Qpid::Proton::Message.new
$reply = Qpid::Proton::Message.new

def send_and_wait(name, value)
  $msg.address = '0.0.0.0'
  $msg.reply_to = '~/#'
  $msg.properties["guru"] = name
  $msg.properties["value"] = value

  $msgr.put($msg)
  $msgr.send

  $msgr.receive(-1)
  $msgr.get($reply)
end

# get the max number
send_and_wait("max_value", true)
max_value = $reply.properties["answer"].to_i

puts "The maximum guess is: #{max_value}"

guesses = []
started = Time.new

loop do
  guess = (rand(max_value) + 1).to_i

  unless guesses.include? guess
    guesses << guess
    puts "Guessing: #{guess}"
    send_and_wait("guess", guess)

    if $reply.properties["answer"]
      ended = Time.new
      duration = ended - started
      puts "\nThe answer was #{guess}, which I got in #{guesses.size} guesses, using #{((guesses.size.to_f / max_value.to_f) * 100.0).round(2)}% of the possible values."
      puts "Runtime: #{duration.round(2)} secs (#{(guesses.size.to_f / duration.to_f).round(2)} msg/sec)"
      last = 0
      break
    end
  end
end

$msgr.stop
