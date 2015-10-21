require "exploreuk/version"
require 'trollop'
require 'fileutils'
require 'json'
require 'pathname'
require 'rsolr'

module Exploreuk
  class Options
    def self.get
      opts = ::Trollop::options do
        opt :incoming, "Incoming directory", :type => :string
        opt :working, "Working directory", :type => :string
        opt :success, "Success directory", :type => :string
        opt :failure, "Failure directory", :type => :string
        opt :base, "Base directory", :type => :string, :default => ''
      end

      keys = [
        :incoming,
        :working,
        :success,
        :failure,
      ]

      if opts[:base].length > 0
        keys.each do |key|
          opts[key] = File.join(opts[:base], opts[key])
        end
      end

      keys.each do |key|
        opts[key] = Pathname.new(opts[key])
      end

      opts
    end
  end

  module Task
    def initialize
      @opts = Options.get
    end

    def setup
      @opts[:incoming].find do |path|
        if FileTest.file? path
          FileUtils.mv path, @opts[:working]
        end
      end
    end

    def teardown
    end

    def idle
      if @delay
        sleep @delay
      end
    end

    def run
      Process.daemon
      while true
        setup
        perform
        teardown
        idle
      end
    end

    def perform
      @opts[:working].find do |path|
        if FileTest.file? path
          if @message
            puts "#{@message} #{path}"
          end

          begin
            handle(path)
            FileUtils.mv path, @opts[:success]
          rescue
            FileUtils.mv path, @opts[:failure]
          end
        end
      end
    end

    def handle path
    end
  end
end
