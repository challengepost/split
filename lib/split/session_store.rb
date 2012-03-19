module Split
  class SessionStore
    attr_accessor :session
   
    def initialize(session)
      raise SessionNotFoundError if session.nil?
      @session = session[:split] ||= {}
    end

    def get_key(name)
      @session[name]
    end

    def set_key(name, value)
      @session[name] = value
    end

    def get_keys
      @session.keys
    end

    def delete_key(name)
      @session.delete name
    end

    def to_hash
      Marshal.load(Marshal.dump(@session))
    end

    class SessionNotFoundError < StandardError
    end
  end
end
