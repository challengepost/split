module Split
  class RedisStore
    attr_accessor :redis
    attr_accessor :identifier
   
    def initialize(redis)
      @redis = redis
      @identifier = nil
    end

    def get_key(name)
      @redis.hget("user_store:#{@identifier}", name)

    end

    def set_key(name, value)
      @redis.hset("user_store:#{@identifier}", name, value)
    end

    def get_keys
      @redis.hkeys("user_store:#{@identifier}")
    end

    def delete_key(name)
      @redis.hdel("user_store:#{@identifier}", name)
    end

    def to_hash
      @redis.hgetall("user_store:#{@identifier}")
    end

    def set_id(id)
      @identifier = id.to_s
    end
  end
end
