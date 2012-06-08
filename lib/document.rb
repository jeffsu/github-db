module Document
  def self.included(klass)
    klass.send(:include, Mongoid::Document)
    klass.send(:extend, ClassMethods)
  end

  module ClassMethods
    def sanitize_hash(hash)
      return hash
    end
  end
end
