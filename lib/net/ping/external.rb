$LOAD_PATH.unshift File.dirname(__FILE__)
require 'ping'

if RUBY_PLATFORM.match('mswin')
   require 'win32/open3'
   require 'windows/console'
   include Windows::Console
else
   require 'open3'            
end

module Net
   class Ping::External < Ping
   
      # Pings the host using your system's ping utility and checks for any
      # errors or warnings.  Returns true if boolful, or false if not.
      # 
      # If false, then the Ping::External#exception method should contain a
      # string indicating what went wrong.  If true, the Ping::External#warning
      # method may or may not contain a value.
      # 
      def ping(host = @host)
         super(host)

         input, output, error = ""
         pstring = "ping "
         bool    = false
         orig_cp = nil
         
         case RUBY_PLATFORM
            when /linux|bsd|osx|mach|darwin/i
               pstring += "-c 1 #{host}"
            when /solaris|sunos/i
               pstring += "#{host} 1"
            when /hpux/i
               pstring += "#{host} -n 1"
            when /win32|windows|mswin/i
               orig_cp = GetConsoleCP()
               SetConsoleCP(437) if orig_cp != 437 # United States
               pstring += "-n 1 #{host}"
            else
               pstring += "#{host}"
         end
         
         start_time = Time.now
         
         begin
           e = nil
           Timeout.timeout(@timeout){
              input, output, error = Open3.popen3(pstring)
              e = error.gets # Can't chomp yet, might be nil
           }

           input.close
           error.close

           if RUBY_PLATFORM.match('mswin') && GetConsoleCP() != orig_cp
              SetConsoleCP(orig_cp)
           end
        
           unless e.nil?
              if e =~ /warning/i
                 @warning = e.chomp
                 bool = true
              else
                 @exception = e.chomp
              end
           # The "no answer" response goes to stdout, not stderr, so check it
           else
              lines = output.readlines
              output.close
              if lines.nil? || lines.empty?
                 bool = true
              else
                 regexp = /
                    no\ answer|
                    host\ unreachable|
                    could\ not\ find\ host|
                    request\ timed\ out|
                    100%\ packet\ loss
                 /ix
                 lines.each{ |e|
                    if regexp.match(e)
                       @exception = e.chomp
                       break
                    end
                 }
                 bool = true unless @exception
              end
           end
         rescue Exception => err
           @exception = err.message 
         end

         # There is no duration if the ping failed
         @duration = Time.now - start_time if bool

         bool
      end

      alias ping? ping
      alias pingecho ping
   end

   # Class alias for backwards compatibility.
   PingExternal = Ping::External
end
