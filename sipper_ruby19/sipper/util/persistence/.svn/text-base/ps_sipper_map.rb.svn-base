require 'sipper_configurator'
require 'pstore'
require 'util/persistence/sipper_map'

module SipperUtil
  module Persistence
  
    # Uses the pstore data store 
    # Data access to the map is transactional. 
    class PsSipperMap < SipperMap
      def initialize(name)
        super
        path = SipperConfigurator[:PStorePath]||SipperConfigurator[:LogPath]
        @ps = PStore.new(File.join(path, name))
      end
      
      def put(k,v)
        @ps.transaction do
          @ps[k] = v
        end
      end
      
      def get(k)
        @ps.transaction(true) do
          return @ps[k]
        end
      end
      
      def get_all_keys 
        @ps.transaction(true) do
          @ps.roots
        end
      end
      
      
      def put_all(h)
        @ps.transaction do
          h.each_pair {|k,v| @ps[k] = v}
        end
      end
      
      def delete(k)
        @ps.transaction do
          @ps.delete(k)
        end
      end
      
      def delete_all 
        @ps.transaction do
          @ps.roots.each do |k|
            @ps.delete(k)
          end
        end
      end
      
      def destroy
        self.delete_all
        File.delete @ps.path
      end
      
    end
  end
end  