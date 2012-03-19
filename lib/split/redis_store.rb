module Split
  class RedisStore
    attr_accessor :redis
   
    def initialize(redis)
      @redis = redis
    end

    def get_key(name)
      @redis.hget(:user_store, name)

    end

    def set_key(name, value)
      @redis.hset(:user_store, name, value)
    end

    def get_keys
      @redis.hkeys(:user_store)
    end

    def delete_key(name)
      @redis.hdel(:user_store, name)
    end

    def to_hash
      @redis.hgetall(:user_store)
    end
  end
end
