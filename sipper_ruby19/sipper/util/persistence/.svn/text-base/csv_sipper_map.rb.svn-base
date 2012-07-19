
require 'sipper_configurator'
require 'csv'
require 'util/persistence/sipper_map'

module SipperUtil
  module Persistence
    
    # Uses the CSV data store 
    # Data access to the map is non-transactional. 
    class CsvSipperMap < SipperMap
      def initialize(name)
        super
        path = SipperConfigurator[:PStorePath]||SipperConfigurator[:LogPath]
        @file = File.join(path, name)
        unless File.exists? @file
          outfile = File.open(@file, 'wb')
          CSV::Writer.generate(outfile) do |csv|
            csv << ['sipper_user', 'sipper_passwd']
          end
          outfile.close     
        end
        @csv_map = {}
        #CSV::Reader.parse(File.open(@file, 'rb')) do |row|
         # @csv_map[row[0]] = row[1] 
        end
      end
      
      def put(k,v)
        @csv_map[k] = v
      end
      
      def get(k)
        return @csv_map[k]    
      end
      
      def get_all_keys 
        @csv_map.keys
      end
      
      
      def put_all(h)
        h.each_pair {|k,v| @csv_map[k] = v}
      end
      
      def delete(k)
        @csv_map.delete(k)
      end
      
      def delete_all 
        @csv_map.keys.each do |k|
          @csv_map.delete(k)
        end
      end
      
      def destroy
        self.delete_all
        File.delete @file
      end
      
    end
  end
$end  